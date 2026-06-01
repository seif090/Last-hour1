import {
  Injectable,
  Logger,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { RedisService } from '../../redis/redis.service';
import { CreateOrderDto } from './dto/create-order.dto';

@Injectable()
export class OrdersService {
  private readonly logger = new Logger(OrdersService.name);

  private readonly orderNumberChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  async placeOrder(dto: CreateOrderDto, customerId: string) {
    const { offerId, quantity, notes } = dto;

    // ── Step 1: Validate offer exists and is active ──────────
    const offer = await this.prisma.offer.findUnique({
      where: { id: offerId },
      include: { store: true, product: true },
    });

    if (!offer) throw new BadRequestException('Offer not found');
    if (offer.status !== 'active') throw new BadRequestException('Offer is no longer active');
    if (new Date() > offer.endTime) throw new BadRequestException('Offer has expired');
    if (quantity > offer.maxPerCustomer) {
      throw new BadRequestException(`Max ${offer.maxPerCustomer} per customer`);
    }

    // ── Step 2: Redis atomic stock decrement (fast path) ─────
    const { code: redisCode, remaining: redisRemaining } =
      await this.redis.decrementStock(offerId, quantity, Date.now());

    if (redisCode === -1) {
      throw new ConflictException({
        code: 'INSUFFICIENT_STOCK',
        message: `Only ${redisRemaining} items remaining, requested ${quantity}`,
        stockRemaining: redisRemaining,
      });
    }

    // ── Step 3: PG transaction (source of truth) ─────────────
    try {
      const order = await this.prisma.$transaction(async (tx) => {
        // Lock and decrement stock in PG (double-check)
        const result: any = await tx.$queryRawUnsafe(
          `SELECT * FROM fn_atomic_decrement_stock($1::uuid, $2)`,
          offerId,
          quantity,
        );

        const success = result?.[0]?.success;
        const pgRemaining = result?.[0]?.remaining;

        if (!success) {
          // Rollback Redis
          await this.redis.initStock(offerId, pgRemaining);
          throw new ConflictException({
            code: 'INSUFFICIENT_STOCK',
            message: `Only ${pgRemaining} items remaining`,
            stockRemaining: pgRemaining,
          });
        }

        // Generate order number
        const orderNumber = await this.generateOrderNumber(tx);

        // Create order
        const newOrder = await tx.order.create({
          data: {
            orderNumber,
            customerId,
            storeId: offer.storeId,
            offerId: offer.id,
            quantity,
            unitPrice: Number(offer.discountedPrice),
            subtotal: Number(offer.discountedPrice) * quantity,
            serviceFee: this.calculateServiceFee(Number(offer.discountedPrice) * quantity),
            totalAmount: this.calculateTotal(Number(offer.discountedPrice) * quantity),
            status: 'confirmed',
            notes: notes || null,
          },
        });

        return newOrder;
      });

      // ── Step 4: Update Redis with current PG state ────

      this.logger.log(`Order ${order.orderNumber} placed for offer ${offerId} x${quantity}`);

      return order;
    } catch (err) {
      // If PG fails, try to restore Redis stock
      const currentRedis = await this.redis.getStock(offerId);
      if (currentRedis !== null) {
        await this.redis.initStock(offerId, currentRedis + quantity);
      }
      throw err;
    }
  }

  async getOrder(orderId: string, userId: string) {
    return this.prisma.order.findFirstOrThrow({
      where: { id: orderId, customerId: userId },
      include: {
        items: true,
        payment: true,
        store: { select: { id: true, name: true, addressLine1: true } },
      },
    });
  }

  async getUserOrders(userId: string, status?: string, page = 1, limit = 20) {
    const where: any = { customerId: userId };
    if (status) where.status = status;

    const [orders, total] = await Promise.all([
      this.prisma.order.findMany({
        where,
        include: {
          store: { select: { id: true, name: true, slug: true } },
          offer: { select: { id: true, title: true, imageUrl: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.order.count({ where }),
    ]);

    return { orders, meta: { page, limit, total, hasMore: page * limit < total } };
  }

  private async generateOrderNumber(tx: any): Promise<string> {
    let attempts = 0;
    while (attempts < 5) {
      const chars = this.orderNumberChars;
      let code = 'LH-';
      for (let i = 0; i < 6; i++) {
        code += chars[Math.floor(Math.random() * chars.length)];
      }
      const existing = await tx.order.findUnique({ where: { orderNumber: code } });
      if (!existing) return code;
      attempts++;
    }
    throw new Error('Failed to generate unique order number');
  }

  private calculateServiceFee(subtotal: number): number {
    return Math.round(subtotal * 0.05 * 100) / 100; // 5% service fee
  }

  private calculateTotal(subtotal: number): number {
    return subtotal + this.calculateServiceFee(subtotal);
  }
}

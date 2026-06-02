import {
  Injectable,
  Logger,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';
import { PrismaService } from '../../database/prisma.service';
import { RedisService } from '../../redis/redis.service';
import { OrderStatus, PaymentStatus, Prisma } from '@prisma/client';
import { CreateOrderDto } from './dto/create-order.dto';
import { PaymentsService } from '../payments/payments.service';
import { OffersGateway } from '../offers/offers.gateway';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class OrdersService {
  private readonly logger = new Logger(OrdersService.name);

  private readonly orderNumberChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly paymentsService: PaymentsService,
    private readonly offersGateway: OffersGateway,
    private readonly notificationsService: NotificationsService,
    @InjectQueue('order-timeout') private readonly orderTimeoutQueue: Queue,
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

    // Double-check: Check if customer already has a pending or confirmed order for this offer
    const existingOrder = await this.prisma.order.findFirst({
      where: {
        customerId,
        offerId,
        status: { in: ['pending', 'confirmed', 'preparing', 'ready'] },
      },
    });
    if (existingOrder) {
      throw new ConflictException({
        code: 'DUPLICATE_ORDER',
        message: 'You already have an active order for this offer',
      });
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
      const { order, paymentDetails } = await this.prisma.$transaction(async (tx) => {
        // Lock and decrement stock in PG (double-check)
        const result: any = await tx.$queryRawUnsafe(
          `SELECT * FROM fn_atomic_decrement_stock($1::uuid, $2)`,
          offerId,
          quantity,
        );

        const success = result?.[0]?.success;
        const pgRemaining = result?.[0]?.remaining;

        if (!success) {
          // Rollback Redis stock
          await this.redis.initStock(offerId, pgRemaining);
          throw new ConflictException({
            code: 'INSUFFICIENT_STOCK',
            message: `Only ${pgRemaining} items remaining`,
            stockRemaining: pgRemaining,
          });
        }

        // Generate order number
        const orderNumber = await this.generateOrderNumber(tx);
        const subtotal = Number(offer.discountedPrice) * quantity;
        const serviceFee = this.calculateServiceFee(subtotal);
        const totalAmount = this.calculateTotal(subtotal);

        // Create order in pending state (will confirm if payment is synchronous/succeeds)
        const newOrder = await tx.order.create({
          data: {
            orderNumber,
            customerId,
            storeId: offer.storeId,
            offerId: offer.id,
            quantity,
            unitPrice: Number(offer.discountedPrice),
            subtotal,
            serviceFee,
            totalAmount,
            status: 'pending',
            notes: notes || null,
            items: {
              create: {
                productId: offer.productId,
                productName: offer.product.name,
                quantity,
                unitPrice: Number(offer.discountedPrice),
                subtotal,
              },
            },
          },
        });

        // ── Step 3.5: Charge Payment ──
        const chargeResult = await this.paymentsService.charge(dto.payment, {
          id: newOrder.id,
          orderNumber,
          totalAmount,
        });

        // Save Payment record in database
        const paymentRecord = await tx.payment.create({
          data: {
            orderId: newOrder.id,
            provider: dto.payment.provider,
            providerTxId: chargeResult.providerTxId || null,
            amount: totalAmount,
            status: chargeResult.status as PaymentStatus,
            metadata: chargeResult.iframeUrl
              ? { iframeUrl: chargeResult.iframeUrl, paymentKey: chargeResult.paymentKey }
              : {},
          },
        });

        // If payment succeeded synchronously (e.g. Stripe), transition order directly to confirmed
        let updatedOrder = newOrder;
        if (chargeResult.status === 'captured') {
          updatedOrder = await tx.order.update({
            where: { id: newOrder.id },
            data: { status: 'confirmed' },
          });
        }

        return { order: updatedOrder, paymentDetails: paymentRecord };
      });

      // ── Step 4: After Transaction Side-Effects ────
      const finalRedis = await this.redis.getStock(offerId);
      const remainingStock = finalRedis !== null ? finalRedis : redisRemaining;

      // Broadcast updated stock to all WebSockets
      this.offersGateway.broadcastStockUpdate(offerId, offer.storeId, remainingStock);

      if (order.status === 'confirmed') {
        this.logger.log(`Order ${order.orderNumber} placed & paid synchronously via Stripe`);

        // Broadcast order status via WS
        this.offersGateway.broadcastOrderStatus(order.id, customerId, 'confirmed');

        // Send push notification
        await this.notificationsService.onOrderConfirmed(order.id, customerId);
      } else {
        this.logger.log(`Order ${order.orderNumber} created pending asynchronous payment redirection`);

        // Schedule timeout in queue (10 minutes) to cancel order if payment is not completed
        await this.orderTimeoutQueue.add(
          'confirm-timeout',
          { orderId: order.id },
          { delay: 10 * 60 * 1000 },
        );
      }

      // Format response exactly as specified in API_SPECIFICATION.md
      return {
        order: {
          id: order.id,
          orderNumber: order.orderNumber,
          status: order.status,
          quantity: order.quantity,
          unitPrice: Number(order.unitPrice),
          subtotal: Number(order.subtotal),
          serviceFee: Number(order.serviceFee),
          totalAmount: Number(order.totalAmount),
          currency: order.currency,
          estimatedReadyAt: order.estimatedReadyAt,
          createdAt: order.createdAt,
        },
        payment: {
          id: paymentDetails.id,
          provider: paymentDetails.provider,
          status: paymentDetails.status,
          amount: Number(paymentDetails.amount),
          iframeUrl: (paymentDetails.metadata as Record<string, string>)?.iframeUrl || null,
        },
        stock_remaining: remainingStock,
        message: order.status === 'pending' ? 'Payment redirection required' : null,
      };

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
    const where: Prisma.OrderFindManyArgs['where'] = { customerId: userId };
    if (status) where.status = status as OrderStatus;

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

  private async generateOrderNumber(tx: Prisma.TransactionClient): Promise<string> {
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

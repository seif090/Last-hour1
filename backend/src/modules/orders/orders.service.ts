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
import { CouponsService } from '../coupons/coupons.service';
import { ReferralsService } from '../referrals/referrals.service';

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
    private readonly couponsService: CouponsService,
    private readonly referralsService: ReferralsService,
    @InjectQueue('order-timeout') private readonly orderTimeoutQueue: Queue,
  ) {}

  async placeOrder(dto: CreateOrderDto, customerId: string) {
    const { offerId, quantity, notes, couponCode } = dto;

    // ── Step 1: Validate offer exists and is active ──────────
    const offer = await this.prisma.offer.findUnique({
      where: { id: offerId },
      include: {
        store: { select: { id: true, name: true, merchantId: true } },
        product: { select: { id: true, name: true } },
      },
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

    // ── Step 2: Validate coupon if provided ───────────────────
    let couponInfo: { couponId: string; discount: number } | null = null;
    if (couponCode) {
      const subtotal = Number(offer.discountedPrice) * quantity;
      const orderTotal = this.calculateTotal(subtotal);
      try {
        const result = await this.couponsService.validateAndApply(offer.storeId, { code: couponCode, orderTotal });
        couponInfo = { couponId: result.couponId, discount: result.discount };
      } catch (e) {
        // Coupon invalid — proceed without discount
        this.logger.warn(`Coupon ${couponCode} invalid for order: ${(e as Error).message}`);
      }
    }

    // ── Step 3: Redis atomic stock decrement (fast path) ─────
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
        const discountAmount = couponInfo?.discount ?? 0;
        const totalAmount = this.calculateTotal(subtotal) - discountAmount;

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
            couponId: couponInfo?.couponId ?? null,
            discountAmount,
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

      // Increment coupon usage if applied
      if (couponInfo) {
        await this.couponsService.useCoupon(couponInfo.couponId);
      }

      // Broadcast updated stock to all WebSockets
      this.offersGateway.broadcastStockUpdate(offerId, offer.storeId, remainingStock);

      if (order.status === 'confirmed') {
        this.logger.log(`Order ${order.orderNumber} placed & paid synchronously via Stripe`);

        // Broadcast order status via WS
        this.offersGateway.broadcastOrderStatus(order.id, customerId, 'confirmed');

        // Send push notification
        await this.notificationsService.onOrderConfirmed(order.id, customerId);

        // Reward referrer if this is the referred user's first confirmed order
        if (await this.referralsService.rewardReferral(customerId)) {
          this.logger.log(`Referral reward credited for customer ${customerId}`);
        }
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
        coupon: { select: { code: true } },
        offer: { select: { id: true } },
      },
    });
  }

  async confirmPickup(orderId: string, userId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
    });
    if (!order || order.customerId !== userId) {
      throw new BadRequestException('Order not found');
    }
    if (order.status !== 'ready') {
      throw new BadRequestException('Order must be ready before confirming pickup');
    }
    return this.prisma.order.update({
      where: { id: orderId },
      data: { status: 'picked_up', pickedUpAt: new Date() },
    });
  }

  async cancelOrder(orderId: string, userId: string, reason?: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { offer: true },
    });
    if (!order || order.customerId !== userId) {
      throw new BadRequestException('Order not found');
    }
    if (order.status !== 'pending' && order.status !== 'confirmed') {
      throw new BadRequestException('Only pending or confirmed orders can be cancelled');
    }

    const updatedOrder = await this.prisma.$transaction(async (tx) => {
      await tx.offer.update({
        where: { id: order.offerId },
        data: { stockRemaining: { increment: order.quantity } },
      });
      return tx.order.update({
        where: { id: orderId },
        data: {
          status: 'cancelled',
          cancelledAt: new Date(),
          cancelReason: reason || 'Cancelled by customer',
        },
      });
    });

    try {
      const currentRedis = await this.redis.getStock(order.offerId);
      if (currentRedis !== null) {
        await this.redis.initStock(order.offerId, currentRedis + order.quantity);
      } else {
        const freshOffer = await this.prisma.offer.findUnique({
          where: { id: order.offerId },
        });
        if (freshOffer) {
          await this.redis.initStock(order.offerId, Number(freshOffer.stockRemaining));
        }
      }

      const freshRedis = await this.redis.getStock(order.offerId);
      this.offersGateway.broadcastStockUpdate(
        order.offerId,
        order.storeId,
        freshRedis !== null ? freshRedis : order.offer.stockRemaining + order.quantity,
      );
    } catch (err) {
      this.logger.error(`Failed to restore Redis stock for cancellation of order ${orderId}`, err);
    }

    this.offersGateway.broadcastOrderStatus(orderId, userId, 'cancelled');

    return updatedOrder;
  }

  async getUserOrders(
    userId: string,
    status?: string,
    page = 1,
    limit = 20,
    filters?: {
      startDate?: string;
      endDate?: string;
      minPrice?: number;
      maxPrice?: number;
      sort?: string;
    },
  ) {
    const where: Prisma.OrderFindManyArgs['where'] = { customerId: userId };
    if (status) where.status = status as OrderStatus;

    if (filters) {
      if (filters.startDate || filters.endDate) {
        where.createdAt = {};
        if (filters.startDate) where.createdAt.gte = new Date(filters.startDate);
        if (filters.endDate) where.createdAt.lte = new Date(filters.endDate);
      }
      if (filters.minPrice !== undefined || filters.maxPrice !== undefined) {
        where.totalAmount = {};
        if (filters.minPrice !== undefined) where.totalAmount.gte = filters.minPrice;
        if (filters.maxPrice !== undefined) where.totalAmount.lte = filters.maxPrice;
      }
    }

    let orderBy: Prisma.OrderFindManyArgs['orderBy'] = { createdAt: 'desc' };
    if (filters?.sort === 'amount_asc') orderBy = { totalAmount: 'asc' };
    else if (filters?.sort === 'amount_desc') orderBy = { totalAmount: 'desc' };
    else if (filters?.sort === 'oldest') orderBy = { createdAt: 'asc' };

    const [orders, total] = await Promise.all([
      this.prisma.order.findMany({
        where,
      include: {
        store: { select: { id: true, name: true, slug: true } },
        offer: { select: { id: true, title: true, imageUrl: true } },
        coupon: { select: { code: true } },
      },
        orderBy,
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

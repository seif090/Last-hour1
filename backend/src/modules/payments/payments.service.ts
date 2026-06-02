import { Injectable, Logger } from '@nestjs/common';
import { StripeProvider } from './providers/stripe.provider';
import { PaymobProvider } from './providers/paymob.provider';
import { PrismaService } from '../../database/prisma.service';
import { RedisService } from '../../redis/redis.service';
import { OffersGateway } from '../offers/offers.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { OrderPaymentInfo, PaymentChargeResult } from './providers/payment-provider.interface';

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);

  constructor(
    private readonly stripeProvider: StripeProvider,
    private readonly paymobProvider: PaymobProvider,
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly offersGateway: OffersGateway,
    private readonly notificationsService: NotificationsService,
  ) {}

  async charge(
    payment: {
      provider: string;
      paymentMethodId?: string;
      integrationId?: string;
      billingData?: Record<string, string>;
    },
    order: OrderPaymentInfo,
  ): Promise<PaymentChargeResult> {
    switch (payment.provider) {
      case 'stripe':
        return this.stripeProvider.charge(payment, order);
      case 'paymob':
        return this.paymobProvider.charge(payment, order);
      default:
        throw new Error(`Unsupported payment provider: ${payment.provider}`);
    }
  }

  /**
   * Verify Paymob Webhook signature
   */
  verifyPaymobWebhook(hmac: string, obj: Record<string, unknown>): boolean {
    return this.paymobProvider.verifyWebhook(hmac, obj);
  }

  /**
   * Process Paymob webhook transaction callback
   */
  async handlePaymobWebhook(obj: Record<string, unknown>): Promise<void> {
    const success = obj.success === true || obj.success === 'true';
    const pending = obj.pending === true || obj.pending === 'true';
    const paymobOrder = obj.order as Record<string, unknown> | undefined;
    const txId = obj.id as string | undefined;

    const orderId = paymobOrder?.merchant_order_id as string | undefined;
    if (!orderId) {
      this.logger.warn('Paymob webhook received without merchant_order_id in payload');
      return;
    }

    this.logger.log(`Processing Paymob webhook for order ${orderId}. Success: ${success}, Pending: ${pending}`);

    // Look up the order in our database
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        customer: { select: { id: true } },
        store: { select: { id: true, name: true } },
        offer: { select: { id: true, storeId: true, stockRemaining: true } },
      },
    });

    if (!order) {
      this.logger.error(`Order ${orderId} not found for Paymob webhook`);
      return;
    }

    if (order.status !== 'pending') {
      this.logger.log(`Order ${orderId} is already in status: ${order.status}. Skipping webhook processing.`);
      return;
    }

    if (success && !pending) {
      // 1. Transaction succeeded -> Confirm order and capture payment in database
      await this.prisma.$transaction(async (tx) => {
        await tx.payment.update({
          where: { orderId },
          data: {
            status: 'captured',
            providerTxId: String(txId),
            paidAt: new Date(),
          },
        });

        await tx.order.update({
          where: { id: orderId },
          data: { status: 'confirmed' },
        });
      });

      this.logger.log(`Order ${orderId} confirmed successfully via Paymob callback`);

      // 2. Broadcast status update via WebSocket
      this.offersGateway.broadcastOrderStatus(order.id, order.customerId, 'confirmed');

      // 3. Dispatch push notification to the customer
      await this.notificationsService.onOrderConfirmed(order.id, order.customerId);

    } else if (!success && !pending) {
      // 2. Transaction failed -> Cancel order and restore stock in database and cache
      await this.prisma.$transaction(async (tx) => {
        await tx.payment.update({
          where: { orderId },
          data: {
            status: 'failed',
            providerTxId: String(txId),
          },
        });

        await tx.order.update({
          where: { id: orderId },
          data: {
            status: 'cancelled',
            cancelledAt: new Date(),
            cancelReason: 'Paymob payment failed',
          },
        });

        await tx.offer.update({
          where: { id: order.offerId },
          data: {
            stockRemaining: { increment: order.quantity },
          },
        });
      });

      // Restore Redis stock
      try {
        const currentRedis = await this.redis.getStock(order.offerId);
        if (currentRedis !== null) {
          await this.redis.initStock(order.offerId, currentRedis + order.quantity);
        } else {
          // If expired from Redis entirely, query PG to restore
          const freshOffer = await this.prisma.offer.findUnique({ where: { id: order.offerId } });
          if (freshOffer) {
            await this.redis.initStock(order.offerId, Number(freshOffer.stockRemaining));
          }
        }
      } catch (redisErr) {
        this.logger.error(`Failed to restore stock in Redis for offer ${order.offerId}`, redisErr);
      }

      this.logger.log(`Order ${orderId} cancelled due to failed payment. Stock restored.`);

      // Broadcast order status update (cancelled) via WebSockets
      this.offersGateway.broadcastOrderStatus(order.id, order.customerId, 'cancelled');
    }
  }
}

import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';

@Injectable()
export class StripeProvider {
  private readonly logger = new Logger(StripeProvider.name);
  private readonly stripe: Stripe;

  constructor(config: ConfigService) {
    this.stripe = new Stripe(config.get<string>('STRIPE_SECRET_KEY')!, {
      apiVersion: '2024-11-20.acacia' as any,
      maxNetworkRetries: 3,
    });
  }

  async charge(payment: { paymentMethodId: string }, order: any) {
    try {
      const paymentIntent = await this.stripe.paymentIntents.create({
        amount: Math.round(order.totalAmount * 100), // cents
        currency: 'egp',
        payment_method: payment.paymentMethodId,
        confirm: true,
        metadata: {
          order_id: order.id,
          order_number: order.orderNumber,
        },
        description: `Last Hour order ${order.orderNumber}`,
      });

      this.logger.log(`Payment ${paymentIntent.id} for order ${order.orderNumber}`);

      return {
        provider: 'stripe',
        providerTxId: paymentIntent.id,
        amount: order.totalAmount,
        status: paymentIntent.status === 'succeeded' ? 'captured' : 'pending',
      };
    } catch (err: any) {
      this.logger.error(`Stripe charge failed: ${err.message}`);
      throw err;
    }
  }
}

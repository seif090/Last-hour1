import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { PaymentProvider, PaymentChargeInput, OrderPaymentInfo, PaymentChargeResult } from './payment-provider.interface';

@Injectable()
export class StripeProvider implements PaymentProvider {
  private readonly logger = new Logger(StripeProvider.name);
  private readonly stripe: Stripe;

  constructor(config: ConfigService) {
    this.stripe = new Stripe(config.get<string>('STRIPE_SECRET_KEY')!, {
      apiVersion: '2023-10-16',
      maxNetworkRetries: 3,
    });
  }

  async charge(payment: PaymentChargeInput, order: OrderPaymentInfo): Promise<PaymentChargeResult> {
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
    } catch (err: unknown) {
      this.logger.error(`Stripe charge failed: ${err instanceof Error ? err.message : String(err)}`);
      throw err;
    }
  }
}

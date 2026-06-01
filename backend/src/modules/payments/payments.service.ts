import { Injectable, Logger } from '@nestjs/common';
import { StripeProvider } from './providers/stripe.provider';
import { PaymobProvider } from './providers/paymob.provider';

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);

  constructor(
    private readonly stripeProvider: StripeProvider,
    private readonly paymobProvider: PaymobProvider,
  ) {}

  async charge(payment: { provider: string; paymentMethodId?: string; integrationId?: string; billingData?: Record<string, string> }, order: any) {
    switch (payment.provider) {
      case 'stripe':
        return this.stripeProvider.charge(payment, order);
      case 'paymob':
        return this.paymobProvider.charge(payment, order);
      default:
        throw new Error(`Unsupported payment provider: ${payment.provider}`);
    }
  }
}

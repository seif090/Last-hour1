import { Injectable, Logger } from '@nestjs/common';
import { StripeProvider } from './providers/stripe.provider';
import { CreateOrderDto } from '../orders/dto/create-order.dto';

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);

  constructor(private readonly stripeProvider: StripeProvider) {}

  async charge(payment: CreateOrderDto['payment'], order: any) {
    switch (payment.provider) {
      case 'stripe':
        return this.stripeProvider.charge(payment, order);
      case 'paymob':
        throw new Error('Paymob not yet implemented');
      default:
        throw new Error(`Unsupported payment provider: ${payment.provider}`);
    }
  }
}

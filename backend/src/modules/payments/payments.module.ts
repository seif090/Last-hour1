import { Module } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { StripeProvider } from './providers/stripe.provider';

@Module({
  providers: [PaymentsService, StripeProvider],
  exports: [PaymentsService],
})
export class PaymentsModule {}

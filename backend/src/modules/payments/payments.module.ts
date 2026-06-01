import { Module } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { StripeProvider } from './providers/stripe.provider';
import { PaymobProvider } from './providers/paymob.provider';

@Module({
  providers: [PaymentsService, StripeProvider, PaymobProvider],
  exports: [PaymentsService],
})
export class PaymentsModule {}

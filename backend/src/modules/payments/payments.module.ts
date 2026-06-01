import { Module } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { StripeProvider } from './providers/stripe.provider';
import { PaymobProvider } from './providers/paymob.provider';
import { PaymentsController } from './payments.controller';
import { OffersModule } from '../offers/offers.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [OffersModule, NotificationsModule],
  controllers: [PaymentsController],
  providers: [PaymentsService, StripeProvider, PaymobProvider],
  exports: [PaymentsService],
})
export class PaymentsModule {}

import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { OffersModule } from '../offers/offers.module';
import { PaymentsModule } from '../payments/payments.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { CouponsModule } from '../coupons/coupons.module';
import { ReferralsModule } from '../referrals/referrals.module';

@Module({
  imports: [
    OffersModule,
    PaymentsModule,
    NotificationsModule,
    CouponsModule,
    ReferralsModule,
    BullModule.registerQueue({ name: 'order-timeout' }),
  ],
  controllers: [OrdersController],
  providers: [OrdersService],
  exports: [OrdersService],
})
export class OrdersModule {}

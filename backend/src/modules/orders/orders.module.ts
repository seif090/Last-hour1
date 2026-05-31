import { Module } from '@nestjs/common';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { OffersModule } from '../offers/offers.module';
import { PaymentsModule } from '../payments/payments.module';

@Module({
  imports: [OffersModule, PaymentsModule],
  controllers: [OrdersController],
  providers: [OrdersService],
  exports: [OrdersService],
})
export class OrdersModule {}

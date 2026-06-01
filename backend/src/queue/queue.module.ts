import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';
import { NotificationsModule } from '../modules/notifications/notifications.module';
import { DeviceTokensModule } from '../modules/device-tokens/device-tokens.module';
import { OfferExpirationProcessor } from './jobs/offer-expiration.processor';
import { OrderTimeoutProcessor } from './jobs/order-timeout.processor';
import { NotificationDispatchProcessor } from './jobs/notification-dispatch.processor';

@Module({
  imports: [
    BullModule.registerQueue(
      { name: 'offer-expiration' },
      { name: 'order-timeout' },
      { name: 'notification-dispatch' },
    ),
    NotificationsModule,
    DeviceTokensModule,
  ],
  providers: [
    OfferExpirationProcessor,
    OrderTimeoutProcessor,
    NotificationDispatchProcessor,
  ],
})
export class QueueModule {}

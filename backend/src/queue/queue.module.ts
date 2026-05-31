import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';

@Module({
  imports: [
    BullModule.registerQueue(
      { name: 'offer-expiration' },
      { name: 'order-timeout' },
      { name: 'notification-dispatch' },
    ),
  ],
})
export class QueueModule {}

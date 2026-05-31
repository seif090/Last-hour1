import { Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { FcmProvider } from './providers/fcm.provider';
import { EmailProvider } from './providers/email.provider';
import { SmsProvider } from './providers/sms.provider';
import { BullModule } from '@nestjs/bull';

@Module({
  imports: [
    BullModule.registerQueue({ name: 'notification-dispatch' }),
  ],
  providers: [
    NotificationsService,
    FcmProvider,
    EmailProvider,
    SmsProvider,
  ],
  exports: [NotificationsService, FcmProvider, EmailProvider, SmsProvider],
})
export class NotificationsModule {}

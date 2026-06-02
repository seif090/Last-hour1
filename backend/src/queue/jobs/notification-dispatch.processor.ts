import { Processor, Process } from '@nestjs/bull';
import { Job } from 'bull';
import { Logger } from '@nestjs/common';
import { FcmProvider } from '../../modules/notifications/providers/fcm.provider';
import { DeviceTokensService } from '../../modules/device-tokens/device-tokens.service';

export interface NotificationPayload {
  userId: string;
  type: 'order_confirmed' | 'order_ready' | 'offer_expiring' | 'new_nearby_offer' | 'payment_failed';
  title: string;
  body: string;
  data?: Record<string, string>;
}

@Processor('notification-dispatch')
export class NotificationDispatchProcessor {
  private readonly logger = new Logger(NotificationDispatchProcessor.name);

  constructor(
    private readonly fcmProvider: FcmProvider,
    private readonly deviceTokens: DeviceTokensService,
  ) {}

  @Process('push')
  async handlePushNotification(job: Job<NotificationPayload>) {
    const { userId, type, title, body, data } = job.data;

    try {
      const tokens = await this.deviceTokens.getActiveTokens([userId]);
      if (tokens.length === 0) {
        this.logger.log(`No device tokens for user ${userId}, skipping push`);
        return;
      }

      await this.fcmProvider.sendMulticast(tokens, { title, body, data });
      this.logger.log(`Push to ${userId}: [${type}] ${title} — ${body}`);
      job.progress(100);
    } catch (err: any) {
      this.logger.error(`Push notification failed for user ${userId}: ${err.message}`);
      throw err;
    }
  }

  @Process('email')
  async handleEmailNotification(job: Job<NotificationPayload>) {
    const { userId, type, title } = job.data;

    this.logger.log(`Email to ${userId}: [${type}] ${title}`);

    job.progress(100);
  }

  @Process('sms')
  async handleSmsNotification(job: Job<NotificationPayload>) {
    const { userId, type, body } = job.data;

    this.logger.log(`SMS to ${userId}: [${type}] ${body}`);

    job.progress(100);
  }
}

import { Processor, Process } from '@nestjs/bull';
import { Job } from 'bull';
import { Logger } from '@nestjs/common';

export interface NotificationPayload {
  userId: string;
  type: 'order_confirmed' | 'order_ready' | 'offer_expiring' | 'new_nearby_offer' | 'payment_failed';
  title: string;
  body: string;
  data?: Record<string, any>;
}

@Processor('notification-dispatch')
export class NotificationDispatchProcessor {
  private readonly logger = new Logger(NotificationDispatchProcessor.name);

  @Process('push')
  async handlePushNotification(job: Job<NotificationPayload>) {
    const { userId, type, title, body, data } = job.data;

    try {
      // Firebase Cloud Messaging integration point
      this.logger.log(`Push to ${userId}: [${type}] ${title} — ${body}`);

      // const message = {
      //   notification: { title, body },
      //   data: data ?? {},
      //   token: await this.getDeviceToken(userId),
      // };
      // await admin.messaging().send(message);

      job.progress(100);
    } catch (err) {
      this.logger.error(`Push notification failed for user ${userId}: ${err.message}`);
      throw err;
    }
  }

  @Process('email')
  async handleEmailNotification(job: Job<NotificationPayload>) {
    const { userId, type, title, body } = job.data;

    // SendGrid / SES integration point
    this.logger.log(`Email to ${userId}: [${type}] ${title}`);

    job.progress(100);
  }

  @Process('sms')
  async handleSmsNotification(job: Job<NotificationPayload>) {
    const { userId, type, body } = job.data;

    // Twilio integration point
    this.logger.log(`SMS to ${userId}: [${type}] ${body}`);

    job.progress(100);
  }
}

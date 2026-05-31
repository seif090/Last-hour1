import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';
import { NotificationPayload } from '../../queue/jobs/notification-dispatch.processor';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    @InjectQueue('notification-dispatch') private readonly notificationQueue: Queue,
  ) {}

  async sendPush(payload: NotificationPayload) {
    await this.notificationQueue.add('push', payload, {
      attempts: 3,
      backoff: { type: 'exponential', delay: 2000 },
      removeOnComplete: true,
    });
  }

  async sendEmail(payload: NotificationPayload) {
    await this.notificationQueue.add('email', payload, {
      attempts: 3,
      backoff: { type: 'fixed', delay: 5000 },
    });
  }

  async sendSms(payload: NotificationPayload) {
    await this.notificationQueue.add('sms', payload, {
      attempts: 2,
      backoff: { type: 'exponential', delay: 1000 },
    });
  }

  async onOrderConfirmed(orderId: string, customerId: string) {
    await this.sendPush({
      userId: customerId,
      type: 'order_confirmed',
      title: 'Order Confirmed!',
      body: `Your order #${orderId.slice(0, 8)} has been confirmed`,
      data: { orderId, screen: 'order-tracking' },
    });
  }

  async onOrderReady(orderId: string, storeName: string, customerId: string) {
    await this.sendPush({
      userId: customerId,
      type: 'order_ready',
      title: 'Ready for Pickup!',
      body: `Your order from ${storeName} is ready`,
      data: { orderId, screen: 'order-tracking' },
    });
  }

  async onNearbyOffer(customerIds: string[], offerTitle: string, storeName: string) {
    const notifications = customerIds.map((userId) =>
      this.sendPush({
        userId,
        type: 'new_nearby_offer',
        title: 'New Flash Deal!',
        body: `${offerTitle} at ${storeName} — hurry, limited stock!`,
        data: { screen: 'offers-nearby' },
      }),
    );

    await Promise.allSettled(notifications);
  }
}

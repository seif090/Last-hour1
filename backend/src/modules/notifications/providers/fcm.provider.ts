import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

@Injectable()
export class FcmProvider implements OnModuleInit {
  private readonly logger = new Logger(FcmProvider.name);

  constructor(private config: ConfigService) {}

  onModuleInit() {
    const serviceAccountBase64 = this.config.get<string>('FIREBASE_SERVICE_ACCOUNT_B64');
    if (!serviceAccountBase64) {
      this.logger.warn('FIREBASE_SERVICE_ACCOUNT_B64 not set — FCM pushes will be no-ops');
      return;
    }
    try {
      const serviceAccountJson = Buffer.from(serviceAccountBase64, 'base64').toString('utf-8');
      const serviceAccount = JSON.parse(serviceAccountJson);

      if (admin.apps.length === 0) {
        admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
        this.logger.log('Firebase Admin SDK initialized');
      }
    } catch (err: any) {
      this.logger.error(`Firebase Admin init failed: ${err.message}`);
    }
  }

  async send(token: string, payload: { title: string; body: string; data?: Record<string, string> }) {
    if (admin.apps.length === 0) {
      this.logger.log(`[FCM mock] push to ${token.slice(0, 20)}...: ${payload.title}`);
      return { success: true };
    }
    try {
      const message: admin.messaging.TokenMessage = {
        notification: { title: payload.title, body: payload.body },
        data: payload.data ?? {},
        token,
      };
      await admin.messaging().send(message);
      this.logger.log(`FCM push to ${token.slice(0, 20)}...: ${payload.title}`);
      return { success: true };
    } catch (err: any) {
      this.logger.error(`FCM send failed: ${err.message}`);
      return { success: false, error: err.message };
    }
  }

  async sendMulticast(
    tokens: string[],
    payload: { title: string; body: string; data?: Record<string, string> },
  ) {
    if (admin.apps.length === 0 || tokens.length === 0) {
      this.logger.log(`[FCM mock] multicast to ${tokens.length} devices: ${payload.title}`);
      return { succeeded: tokens.length, failed: 0 };
    }
    try {
      const message: admin.messaging.MulticastMessage = {
        notification: { title: payload.title, body: payload.body },
        data: payload.data ?? {},
        tokens,
      };
      const response = await admin.messaging().sendEachForMulticast(message);
      this.logger.log(`FCM multicast: ${response.successCount}/${tokens.length} delivered`);
      return { succeeded: response.successCount, failed: response.failureCount };
    } catch (err: any) {
      this.logger.error(`FCM multicast failed: ${err.message}`);
      return { succeeded: 0, failed: tokens.length };
    }
  }

  async sendToUser(
    token: string,
    payload: { title: string; body: string; data?: Record<string, string> },
  ) {
    return this.send(token, payload);
  }
}

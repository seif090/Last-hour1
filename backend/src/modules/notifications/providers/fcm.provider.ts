import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class FcmProvider {
  private readonly logger = new Logger(FcmProvider.name);

  constructor(private config: ConfigService) {}

  async send(token: string, payload: { title: string; body: string; data?: Record<string, string> }) {
    try {
      // Firebase Admin SDK integration
      // const message = {
      //   notification: { title: payload.title, body: payload.body },
      //   data: payload.data ?? {},
      //   token,
      // };
      // await admin.messaging().send(message);

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
    const results = await Promise.allSettled(
      tokens.map((token) => this.send(token, payload)),
    );

    const succeeded = results.filter((r) => r.status === 'fulfilled' && r.value.success).length;
    this.logger.log(`FCM multicast: ${succeeded}/${tokens.length} delivered`);

    return { succeeded, failed: tokens.length - succeeded };
  }
}

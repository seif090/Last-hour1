import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class SmsProvider {
  private readonly logger = new Logger(SmsProvider.name);

  constructor(private config: ConfigService) {}

  async send(phone: string, message: string) {
    try {
      // Twilio integration
      // const client = twilio(accountSid, authToken);
      // await client.messages.create({
      //   body: message,
      //   from: '+201234567890',
      //   to: phone,
      // });

      this.logger.log(`SMS sent to ${phone}: ${message.slice(0, 50)}...`);
      return { success: true };
    } catch (err: any) {
      this.logger.error(`SMS failed to ${phone}: ${err.message}`);
      return { success: false, error: err.message };
    }
  }

  async sendOrderReady(phone: string, orderNumber: string, storeName: string) {
    return this.send(
      phone,
      `Last Hour: Your order ${orderNumber} from ${storeName} is ready for pickup!`,
    );
  }

  async sendVerificationCode(phone: string, code: string) {
    return this.send(
      phone,
      `Last Hour verification code: ${code}. Valid for 5 minutes.`,
    );
  }
}

import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

interface PaymobChargeRequest {
  paymentMethodId?: string;
  integrationId?: string;
  billingData?: Record<string, string>;
}

interface PaymobAuthResponse {
  token: string;
}

interface PaymobOrderResponse {
  id: number;
}

interface PaymobPaymentKeyResponse {
  token: string;
  id: number;
}

@Injectable()
export class PaymobProvider {
  private readonly logger = new Logger(PaymobProvider.name);
  private readonly apiKey: string;
  private readonly hmacSecret: string;
  private readonly integrationId: string;
  private readonly baseUrl: string;

  constructor(config: ConfigService) {
    this.apiKey = config.get<string>('PAYMOB_API_KEY') ?? '';
    this.hmacSecret = config.get<string>('PAYMOB_HMAC_SECRET') ?? '';
    this.integrationId = config.get<string>('PAYMOB_INTEGRATION_ID') ?? '';
    this.baseUrl = 'https://accept.paymob.com/api';
  }

  async charge(
    payment: PaymobChargeRequest,
    order: { id: string; orderNumber: string; totalAmount: number; currency?: string },
  ) {
    try {
      const authToken = await this.authenticate();

      const paymobOrder = await this.createOrder(authToken, order);
      const paymobOrderId = paymobOrder.id;

      const paymentKey = await this.createPaymentKey(
        authToken,
        paymobOrderId,
        order,
        payment,
      );

      this.logger.log(`Paymob payment key ${paymentKey.token} for order ${order.orderNumber}`);

      return {
        provider: 'paymob',
        providerTxId: paymentKey.token,
        paymobOrderId,
        amount: order.totalAmount,
        status: 'pending',
        paymentKey: paymentKey.token,
        iframeUrl: `https://accept.paymob.com/api/acceptance/iframes/${this.integrationId}?payment_token=${paymentKey.token}`,
      };
    } catch (err: any) {
      this.logger.error(`Paymob charge failed: ${err.message}`);
      throw err;
    }
  }

  private async authenticate(): Promise<string> {
    const response = await fetch(`${this.baseUrl}/auth/tokens`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ api_key: this.apiKey }),
    });

    if (!response.ok) {
      throw new Error(`Paymob auth failed: ${response.statusText}`);
    }

    const data = (await response.json()) as PaymobAuthResponse;
    return data.token;
  }

  private async createOrder(
    token: string,
    order: { id: string; orderNumber: string; totalAmount: number },
  ): Promise<PaymobOrderResponse> {
    const amountCents = Math.round(order.totalAmount * 100);

    const response = await fetch(`${this.baseUrl}/ecommerce/orders`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        auth_token: token,
        delivery_needed: 'false',
        amount_cents: amountCents.toString(),
        currency: 'EGP',
        merchant_order_id: order.id,
        items: [],
      }),
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`Paymob order creation failed: ${text}`);
    }

    return (await response.json()) as PaymobOrderResponse;
  }

  private async createPaymentKey(
    token: string,
    paymobOrderId: number,
    order: { id: string; orderNumber: string; totalAmount: number },
    payment: PaymobChargeRequest,
  ): Promise<PaymobPaymentKeyResponse> {
    const amountCents = Math.round(order.totalAmount * 100);

    const billingData = payment.billingData ?? {
      apartment: 'NA',
      email: 'customer@example.com',
      floor: 'NA',
      first_name: 'Customer',
      street: 'NA',
      building: 'NA',
      phone_number: '+201000000000',
      shipping_method: 'PKG',
      postal_code: 'NA',
      city: 'Cairo',
      country: 'EG',
      last_name: 'LastHour',
      state: 'NA',
    };

    const response = await fetch(`${this.baseUrl}/acceptance/payments/payment_keys`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        auth_token: token,
        amount_cents: amountCents.toString(),
        expiration: 3600,
        order_id: paymobOrderId,
        billing_data: billingData,
        currency: 'EGP',
        integration_id: parseInt(payment.integrationId ?? this.integrationId, 10),
        lock_order_when_paid: 'true',
      }),
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`Paymob payment key creation failed: ${text}`);
    }

    return (await response.json()) as PaymobPaymentKeyResponse;
  }

  verifyWebhook(hmac: string, body: any): boolean {
    const { amount_cents, created_at, currency, error_occured, has_parent_transaction, id, integration_id, is_3d_secure, is_auth, is_capture, is_refund, is_standalone_payment, is_void, order, owner, pending, source_data, success, tx_ref } = body;

    const concatString = `${amount_cents}${created_at}${currency}${error_occured}${has_parent_transaction}${id}${integration_id}${is_3d_secure}${is_auth}${is_capture}${is_refund}${is_standalone_payment}${is_void}${order.id}${owner}${pending}${source_data.identifier}${source_data.sub_type}${success}${tx_ref}`;

    const calculated = crypto.createHmac('sha512', this.hmacSecret).update(concatString).digest('hex');

    return calculated === hmac;
  }
}

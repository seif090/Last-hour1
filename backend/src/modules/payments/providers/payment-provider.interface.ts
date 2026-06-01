export interface PaymentChargeResult {
  provider: string;
  providerTxId?: string;
  paymobOrderId?: number;
  amount: number;
  status: 'pending' | 'captured' | 'failed';
  paymentKey?: string;
  iframeUrl?: string;
}

export interface PaymentChargeInput {
  provider: string;
  paymentMethodId?: string;
  integrationId?: string;
  billingData?: Record<string, string>;
  [key: string]: any;
}

export interface OrderPaymentInfo {
  id: string;
  orderNumber: string;
  totalAmount: number;
  currency?: string;
}

export interface PaymentProvider {
  charge(payment: PaymentChargeInput, order: OrderPaymentInfo): Promise<PaymentChargeResult>;
}

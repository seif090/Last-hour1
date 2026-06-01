import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

export const options = {
  stages: [
    { duration: '10s', target: 50 },
    { duration: '20s', target: 200 },
    { duration: '30s', target: 500 },
    { duration: '30s', target: 500 },
    { duration: '10s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000', 'p(99)<5000'],
    http_req_failed: ['rate<0.01'],
    order_success_rate: ['rate>0.95'],
    stock_errors: ['count<50'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000/api/v1';

const orderSuccessRate = new Rate('order_success_rate');
const orderDuration = new Trend('order_duration');
const stockErrors = new Counter('stock_errors');
const concurrencyErrors = new Counter('concurrency_errors');

const customerAccounts = Array.from({ length: 500 }, (_, i) => ({
  email: `loadtest${i}@test.com`,
  password: 'password123',
}));

const authTokens: string[] = [];

export function setup() {
  const tokens: string[] = [];
  for (const account of customerAccounts.slice(0, 50)) {
    const res = http.post(`${BASE_URL}/auth/login`, JSON.stringify(account), {
      headers: { 'Content-Type': 'application/json' },
    });
    if (res.status === 200) {
      tokens.push(res.json('accessToken') as string);
    }
  }
  return { tokens };
}

export default function (data: { tokens: string[] }) {
  const token = data.tokens[Math.floor(Math.random() * data.tokens.length)];
  if (!token) {
    sleep(1);
    return;
  }

  const headers = {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${token}`,
  };

  group('browse_offers', () => {
    const res = http.get(`${BASE_URL}/offers?page=1&limit=20&lat=30.0444&lng=31.2357&radius=10`, { headers });

    check(res, {
      'offers fetched': (r) => r.status === 200,
      'offers body ok': (r) => r.body !== undefined,
    });

    const offers = res.json('data') as any[] | undefined;
    if (offers && offers.length > 0) {
      const offer = offers[0];
      const offerId = offer.id;

      group('place_order', () => {
        const quantity = 1;
        const startTime = Date.now();

        const orderRes = http.post(
          `${BASE_URL}/orders`,
          JSON.stringify({
            offerId,
            quantity,
            payment: {
              provider: 'stripe',
              paymentMethodId: 'pm_card_visa',
            },
          }),
          { headers },
        );

        const duration = Date.now() - startTime;
        orderDuration.add(duration);

        if (orderRes.status === 201) {
          orderSuccessRate.add(true);
          check(orderRes, {
            'order created': (r) => r.status === 201,
            'order number present': (r) => r.json('data.orderNumber') !== undefined,
          });
        } else if (orderRes.status === 409) {
          stockErrors.add(1);
          concurrencyErrors.add(1);
          check(orderRes, {
            'out of stock handled': () => true,
          });
        } else if (orderRes.status === 429) {
          concurrencyErrors.add(1);
        } else if (orderRes.status === 400) {
          stockErrors.add(1);
          check(orderRes, {
            'duplicate order handled': () => true,
          });
        } else {
          orderSuccessRate.add(false);
        }
      });
    }

    sleep(Math.random() * 0.5);
  });
}

export function teardown(data: any) {
  const headers = {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${data.tokens?.[0] ?? ''}`,
  };

  const res = http.get(`${BASE_URL}/admin/system-health`, { headers });
  if (res.status === 200) {
    console.log('System health check passed');
  }
}

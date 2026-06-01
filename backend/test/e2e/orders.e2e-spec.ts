import supertest from 'supertest';
const request = supertest;
import { app } from './setup';

describe('Orders (e2e)', () => {
  let customerToken: string;
  let merchantToken: string;
  let testOfferId: string;

  beforeAll(async () => {
    // Login as customer
    const customerRes = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: 'customer@test.com', password: 'password123' });

    customerToken = customerRes.body.accessToken;

    // Login as merchant
    const merchantRes = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: 'merchant@breadfactory.com', password: 'password123' });

    merchantToken = merchantRes.body.accessToken;

    // Find an active offer
    const offersRes = await request(app.getHttpServer())
      .get('/api/v1/offers/nearby')
      .query({ lat: 30.0444, lng: 31.2357, radius: 10000, limit: 1 });

    if (offersRes.body?.data?.offers?.length > 0) {
      testOfferId = offersRes.body.data.offers[0].id;
    }
  });

  describe('POST /api/v1/orders', () => {
    it('should place an order successfully', async () => {
      if (!testOfferId) return; // skip if no offers seeded

      const res = await request(app.getHttpServer())
        .post('/api/v1/orders')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({
          offerId: testOfferId,
          quantity: 2,
          payment: {
            provider: 'stripe',
            paymentMethodId: 'pm_card_visa',
          },
          notes: 'Please pack carefully',
        })
        .expect(201);

      expect(res.body.success).toBe(true);
      expect(res.body.data.order).toBeDefined();
      expect(res.body.data.order.status).toBe('confirmed');
      expect(res.body.data.order.orderNumber).toMatch(/^LH-/);
    });

    it('should reject duplicate order for same offer', async () => {
      if (!testOfferId) return;

      await request(app.getHttpServer())
        .post('/api/v1/orders')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({
          offerId: testOfferId,
          quantity: 1,
          payment: { provider: 'stripe', paymentMethodId: 'pm_card_visa' },
        })
        .expect(409);
    });

    it('should reject unauthenticated request', async () => {
      await request(app.getHttpServer())
        .post('/api/v1/orders')
        .send({ offerId: '00000000-0000-0000-0000-000000000000', quantity: 1, payment: {} })
        .expect(401);
    });

    it('should reject quantity exceeding max_per_customer', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/offers/nearby')
        .query({ lat: 30.0444, lng: 31.2357, radius: 10000, limit: 1 });

      const offerId = res.body?.data?.offers?.[0]?.id;
      if (!offerId) return;

      await request(app.getHttpServer())
        .post('/api/v1/orders')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({
          offerId,
          quantity: 999,
          payment: { provider: 'stripe', paymentMethodId: 'pm_card_visa' },
        })
        .expect(400);
    });
  });

  describe('GET /api/v1/orders', () => {
    it('should list customer orders', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/orders')
        .set('Authorization', `Bearer ${customerToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.meta).toBeDefined();
    });
  });

  describe('Merchant endpoints', () => {
    it('should get merchant dashboard', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/merchant/dashboard')
        .set('Authorization', `Bearer ${merchantToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.stores).toBeDefined();
    });

    it('should get today sales report', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/merchant/sales/today')
        .set('Authorization', `Bearer ${merchantToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.totalOrders).toBeDefined();
    });
  });

  describe('Admin endpoints', () => {
    let adminToken: string;

    beforeAll(async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/auth/login')
        .send({ email: 'admin@lasthour.app', password: 'password123' });

      adminToken = res.body.accessToken;
    });

    it('should get platform stats', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/admin/stats')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.totalUsers).toBeDefined();
    });

    it('should list merchants', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/admin/merchants')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(res.body.merchants).toBeDefined();
      expect(Array.isArray(res.body.merchants)).toBe(true);
    });
  });

  describe('GET /api/v1/health', () => {
    it('should return healthy status', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/health')
        .expect(200);

      expect(res.body.status).toBe('healthy');
      expect(res.body.checks.database).toBe('up');
      expect(res.body.checks.cache).toBe('up');
    });
  });
});

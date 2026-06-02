import supertest from 'supertest';
const request = supertest;
import { setupE2eTestApp, teardownE2eTestApp } from './testcontainers-setup';
import { INestApplication } from '@nestjs/common';

describe('Coupons (e2e)', () => {
  let app: INestApplication;
  let customerToken: string;
  let merchantToken: string;
  let storeId: string;

  beforeAll(async () => {
    app = await setupE2eTestApp();

    // Login as merchant to get store ID
    const merchRes = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: 'merchant@breadfactory.com', password: 'password123' });
    merchantToken = merchRes.body.data?.accessToken ?? merchRes.body.accessToken;

    // Login as customer
    const custRes = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: 'customer@test.com', password: 'password123' });
    customerToken = custRes.body.data?.accessToken ?? custRes.body.accessToken;

    // Get merchant dashboard to find first store ID
    const dashRes = await request(app.getHttpServer())
      .get('/api/v1/merchant/dashboard')
      .set('Authorization', `Bearer ${merchantToken}`);
    const stores = dashRes.body.data?.stores ?? [];
    if (stores.length > 0) {
      storeId = stores[0].id;
    }
  }, 120000);

  afterAll(async () => {
    await teardownE2eTestApp();
  }, 30000);

  describe('POST /api/v1/merchant/coupons', () => {
    it('should create a coupon', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/merchant/coupons')
        .set('Authorization', `Bearer ${merchantToken}`)
        .send({
          storeId,
          code: 'TEST10',
          discountType: 'percentage',
          discountValue: 10,
          maxUses: 100,
          minOrderAmount: 50,
          description: 'Test coupon',
        })
        .expect(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.code).toBe('TEST10');
    });

    it('should reject duplicate code', async () => {
      await request(app.getHttpServer())
        .post('/api/v1/merchant/coupons')
        .set('Authorization', `Bearer ${merchantToken}`)
        .send({ storeId, code: 'TEST10', discountType: 'percentage', discountValue: 10 })
        .expect(400);
    });

    it('should reject unauthenticated request', async () => {
      await request(app.getHttpServer())
        .post('/api/v1/merchant/coupons')
        .send({ storeId, code: 'NOAUTH', discountType: 'fixed', discountValue: 50 })
        .expect(401);
    });
  });

  describe('POST /api/v1/coupons/validate', () => {
    it('should validate an active coupon', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/coupons/validate')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({ code: 'TEST10', orderTotal: 100, storeId })
        .expect(201);

      expect(res.body.success).toBe(true);
      expect(res.body.data.valid).toBe(true);
      expect(res.body.data.discount).toBe(10);
    });

    it('should reject non-existent coupon', async () => {
      await request(app.getHttpServer())
        .post('/api/v1/coupons/validate')
        .set('Authorization', `Bearer ${customerToken}`)
        .send({ code: 'INVALID', orderTotal: 100, storeId })
        .expect(404);
    });
  });
});

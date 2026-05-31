import * as request from 'supertest';
import { app } from './setup';

describe('Offers (e2e)', () => {
  let authToken: string;

  beforeAll(async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: 'admin@lasthour.app', password: 'admin123' });

    authToken = res.body.accessToken;
  });

  describe('GET /api/v1/offers/nearby', () => {
    it('should return nearby offers with valid coordinates', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/offers/nearby')
        .query({ lat: 30.0444, lng: 31.2357, radius: 5000 })
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data.offers)).toBe(true);
      expect(res.body.data.meta).toBeDefined();
    });

    it('should reject missing coordinates', async () => {
      await request(app.getHttpServer())
        .get('/api/v1/offers/nearby')
        .query({ radius: 5000 })
        .expect(400);
    });
  });

  describe('POST /api/v1/orders', () => {
    it('should reject unauthenticated request', async () => {
      await request(app.getHttpServer())
        .post('/api/v1/orders')
        .send({ offerId: 'uuid', quantity: 1, payment: { provider: 'stripe', paymentMethodId: 'pm_test' } })
        .expect(401);
    });
  });
});

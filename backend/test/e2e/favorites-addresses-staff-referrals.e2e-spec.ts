import supertest from 'supertest';
const request = supertest;
import { setupE2eTestApp, teardownE2eTestApp } from './testcontainers-setup';
import { INestApplication } from '@nestjs/common';

describe('Favorites (e2e)', () => {
  let app: INestApplication;
  let token: string;
  let offerId: string;

  beforeAll(async () => {
    app = await setupE2eTestApp();

    const login = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: 'customer@test.com', password: 'password123' });
    token = login.body.data?.accessToken ?? login.body.accessToken;

    const offers = await request(app.getHttpServer())
      .get('/api/v1/offers/nearby')
      .query({ lat: 30.0444, lng: 31.2357, radius: 10000, limit: 1 });
    const items = offers.body.data?.offers ?? offers.body?.data?.data?.offers ?? [];
    if (items.length > 0) offerId = items[0].id;
  }, 120000);

  afterAll(async () => {
    await teardownE2eTestApp();
  }, 30000);

  describe('POST /api/v1/favorites', () => {
    it('should add a favorite', async () => {
      if (!offerId) return;
      const res = await request(app.getHttpServer())
        .post('/api/v1/favorites')
        .set('Authorization', `Bearer ${token}`)
        .send({ offerId })
        .expect(201);
      expect(res.body.success).toBe(true);
    });
  });

  describe('GET /api/v1/favorites', () => {
    it('should list favorites', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/favorites')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data.data ?? res.body.data)).toBe(true);
    });
  });
});

describe('Addresses (e2e)', () => {
  let app: INestApplication;
  let token: string;
  let addressId: string;

  beforeAll(async () => {
    app = await setupE2eTestApp();

    const login = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: 'customer@test.com', password: 'password123' });
    token = login.body.data?.accessToken ?? login.body.accessToken;
  }, 120000);

  afterAll(async () => {
    await teardownE2eTestApp();
  }, 30000);

  it('POST /api/v1/addresses — should create address', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/addresses')
      .set('Authorization', `Bearer ${token}`)
      .send({
        label: 'Home',
        addressLine1: '123 Main St',
        city: 'Cairo',
        latitude: 30.0444,
        longitude: 31.2357,
      })
      .expect(201);
    expect(res.body.success).toBe(true);
    addressId = res.body.data.id;
  });

  it('GET /api/v1/addresses — should list addresses', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/v1/addresses')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
  });
});

describe('Staff (e2e)', () => {
  let app: INestApplication;
  let merchantToken: string;

  beforeAll(async () => {
    app = await setupE2eTestApp();

    const login = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: 'merchant@breadfactory.com', password: 'password123' });
    merchantToken = login.body.data?.accessToken ?? login.body.accessToken;
  }, 120000);

  afterAll(async () => {
    await teardownE2eTestApp();
  }, 30000);

  it('GET /api/v1/merchant/staff — should list staff', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/v1/merchant/staff')
      .set('Authorization', `Bearer ${merchantToken}`)
      .expect(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  it('POST /api/v1/merchant/staff — should invite staff', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/merchant/staff')
      .set('Authorization', `Bearer ${merchantToken}`)
      .send({ email: 'staff@test.com', name: 'Test Staff', role: 'staff' })
      .expect(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.email).toBe('staff@test.com');
  });

  it('DELETE /api/v1/merchant/staff/:id — should remove staff', async () => {
    const list = await request(app.getHttpServer())
      .get('/api/v1/merchant/staff')
      .set('Authorization', `Bearer ${merchantToken}`);
    const staff = list.body.data?.[0];
    if (!staff) return;
    await request(app.getHttpServer())
      .delete(`/api/v1/merchant/staff/${staff.id}`)
      .set('Authorization', `Bearer ${merchantToken}`)
      .expect(200);
  });
});

describe('Referrals (e2e)', () => {
  let app: INestApplication;
  let customerToken: string;

  beforeAll(async () => {
    app = await setupE2eTestApp();

    const login = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: 'customer@test.com', password: 'password123' });
    customerToken = login.body.data?.accessToken ?? login.body.accessToken;
  }, 120000);

  afterAll(async () => {
    await teardownE2eTestApp();
  }, 30000);

  it('GET /api/v1/referrals/info — should return referral info', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/v1/referrals/info')
      .set('Authorization', `Bearer ${customerToken}`)
      .expect(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.referralCode).toBeDefined();
  });

  it('GET /api/v1/referrals — should list referrals', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/v1/referrals')
      .set('Authorization', `Bearer ${customerToken}`)
      .expect(200);
    expect(res.body.success).toBe(true);
  });
});

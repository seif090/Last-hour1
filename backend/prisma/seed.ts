import { PrismaClient, UserRole, OfferStatus, BusinessType } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding Last Hour database...');

  // ── Clean existing data ──────────────────────────────────────
  await prisma.review.deleteMany();
  await prisma.payment.deleteMany();
  await prisma.orderItem.deleteMany();
  await prisma.order.deleteMany();
  await prisma.offer.deleteMany();
  await prisma.product.deleteMany();
  await prisma.store.deleteMany();
  await prisma.merchant.deleteMany();
  await prisma.user.deleteMany();

  const passwordHash = await bcrypt.hash('password123', 12);

  // ── Admin ────────────────────────────────────────────────────
  const admin = await prisma.user.create({
    data: {
      email: 'admin@lasthour.app',
      passwordHash,
      role: 'admin',
      phone: '+201000000000',
    },
  });
  console.log(`  ✓ Admin: ${admin.email}`);

  // ── Merchant 1: Bread Factory ────────────────────────────────
  const m1User = await prisma.user.create({
    data: {
      email: 'merchant@breadfactory.com',
      passwordHash,
      role: 'merchant',
      phone: '+201000000001',
    },
  });

  const m1 = await prisma.merchant.create({
    data: {
      userId: m1User.id,
      businessName: 'Bread Factory',
      businessType: 'bakery',
      description: 'Fresh bread and pastries daily',
      isVerified: true,
      taxId: '123456789',
    },
  });

  const [store1] = await prisma.$queryRawUnsafe<
    Array<{ id: string }>
  >(
    `INSERT INTO "stores" (id, merchant_id, name, slug, description, location, address_line1, city, district, cuisine_type, opens_at, closes_at, timezone, cover_image_url, logo_url, updated_at)
      VALUES (gen_random_uuid(), $1::uuid, $2, $3, $4, ST_SetSRID(ST_MakePoint($5, $6), 4326), $7, $8, $9, $10, $11, $12, $13, $14, $15, CURRENT_TIMESTAMP)
      RETURNING id`,
    m1.id,
    'Bread Factory – Downtown',
    'bread-factory-downtown',
    'Artisan bakery since 1990',
    31.2357,
    30.0444,
    '15 Tahrir St',
    'Cairo',
    'Downtown',
    'bakery',
    '07:00:00',
    '22:00:00',
    'Africa/Cairo',
    'https://picsum.photos/seed/bakery1/800/400',
    'https://picsum.photos/seed/bakery1logo/200/200',
  );

  const p1 = await prisma.product.create({
    data: {
      storeId: store1.id,
      name: 'Fresh Croissant Pack',
      description: '6 freshly baked butter croissants',
      category: 'bakery',
      originalPrice: 35.00,
      unit: 'pack',
      imageUrls: ['https://picsum.photos/seed/croissant/400/400'],
    },
  });

  const p2 = await prisma.product.create({
    data: {
      storeId: store1.id,
      name: 'Sourdough Loaf',
      description: '24h fermented sourdough, 1kg',
      category: 'bread',
      originalPrice: 45.00,
      unit: 'loaf',
      imageUrls: ['https://picsum.photos/seed/sourdough/400/400'],
    },
  });

  const p3 = await prisma.product.create({
    data: {
      storeId: store1.id,
      name: 'Mixed Pastry Box',
      description: '12 assorted pastries',
      category: 'bakery',
      originalPrice: 60.00,
      unit: 'box',
      imageUrls: ['https://picsum.photos/seed/pastry/400/400'],
    },
  });

  // ── Merchant 2: Gourmet Kitchen ───────────────────────────────
  const m2User = await prisma.user.create({
    data: {
      email: 'merchant@gourmetkitchen.com',
      passwordHash,
      role: 'merchant',
      phone: '+201000000002',
    },
  });

  const m2 = await prisma.merchant.create({
    data: {
      userId: m2User.id,
      businessName: 'Gourmet Kitchen',
      businessType: 'restaurant',
      description: 'Fine dining Mediterranean cuisine',
      isVerified: true,
      taxId: '987654321',
    },
  });

  const [store2] = await prisma.$queryRawUnsafe<
    Array<{ id: string }>
  >(
    `INSERT INTO "stores" (id, merchant_id, name, slug, description, location, address_line1, city, district, cuisine_type, opens_at, closes_at, timezone, cover_image_url, logo_url, updated_at)
      VALUES (gen_random_uuid(), $1::uuid, $2, $3, $4, ST_SetSRID(ST_MakePoint($5, $6), 4326), $7, $8, $9, $10, $11, $12, $13, $14, $15, CURRENT_TIMESTAMP)
      RETURNING id`,
    m2.id,
    'Gourmet Kitchen – Zamalek',
    'gourmet-kitchen-zamalek',
    'Mediterranean fine dining',
    31.2180,
    30.0656,
    '42 Brazil St',
    'Cairo',
    'Zamalek',
    'mediterranean',
    '12:00:00',
    '23:00:00',
    'Africa/Cairo',
    'https://picsum.photos/seed/rest1/800/400',
    'https://picsum.photos/seed/rest1logo/200/200',
  );

  const p4 = await prisma.product.create({
    data: {
      storeId: store2.id,
      name: 'Grilled Chicken Platter',
      description: 'Half chicken with rice and salad',
      category: 'mains',
      originalPrice: 120.00,
      unit: 'plate',
      imageUrls: ['https://picsum.photos/seed/chicken/400/400'],
    },
  });

  const p5 = await prisma.product.create({
    data: {
      storeId: store2.id,
      name: 'Mixed Mezze Platter',
      description: '6 dips with fresh pita bread',
      category: 'appetizers',
      originalPrice: 65.00,
      unit: 'plate',
      imageUrls: ['https://picsum.photos/seed/mezze/400/400'],
    },
  });

  // ── Active Offers ─────────────────────────────────────────────
  const now = new Date();
  const endOfDay = new Date(now);
  endOfDay.setHours(23, 59, 59, 999);

  await prisma.offer.create({
    data: {
      storeId: store1.id,
      productId: p1.id,
      title: 'Last Hour — Croissant Pack',
      description: '6 fresh croissants at half price — last hour deal!',
      originalPrice: 35.00,
      discountedPrice: 15.00,
      stockInitial: 50,
      stockRemaining: 42,
      maxPerCustomer: 5,
      startTime: new Date(now.getTime() - 3600000),
      endTime: endOfDay,
      status: 'active',
      imageUrl: 'https://picsum.photos/seed/croissant/400/400',
      tags: ['bakery', 'breakfast', 'deal'],
    },
  });

  await prisma.offer.create({
    data: {
      storeId: store1.id,
      productId: p3.id,
      title: 'Flash Sale — Pastry Box',
      description: '12 assorted pastries, 50% off',
      originalPrice: 60.00,
      discountedPrice: 25.00,
      stockInitial: 20,
      stockRemaining: 15,
      maxPerCustomer: 3,
      startTime: new Date(now.getTime() - 1800000),
      endTime: endOfDay,
      status: 'active',
      imageUrl: 'https://picsum.photos/seed/pastry/400/400',
      tags: ['bakery', 'pastry', 'flash'],
    },
  });

  await prisma.offer.create({
    data: {
      storeId: store2.id,
      productId: p4.id,
      title: 'Last Call — Grilled Chicken',
      description: 'Freshly grilled chicken platter — don\'t miss out!',
      originalPrice: 120.00,
      discountedPrice: 49.00,
      stockInitial: 30,
      stockRemaining: 22,
      maxPerCustomer: 4,
      startTime: new Date(now.getTime() - 3600000),
      endTime: endOfDay,
      status: 'active',
      imageUrl: 'https://picsum.photos/seed/chicken/400/400',
      tags: ['mains', 'chicken', 'dinner'],
    },
  });

  await prisma.offer.create({
    data: {
      storeId: store2.id,
      productId: p5.id,
      title: 'Mezze Special — 60% Off',
      description: '6 dips + fresh pita, perfect for sharing',
      originalPrice: 65.00,
      discountedPrice: 25.00,
      stockInitial: 25,
      stockRemaining: 18,
      maxPerCustomer: 5,
      startTime: new Date(now.getTime() - 7200000),
      endTime: endOfDay,
      status: 'active',
      imageUrl: 'https://picsum.photos/seed/mezze/400/400',
      tags: ['appetizers', 'mezze', 'share'],
    },
  });

  // ── Customer Users ───────────────────────────────────────────
  const customer1 = await prisma.user.create({
    data: {
      email: 'customer@test.com',
      passwordHash,
      role: 'customer',
      phone: '+201000000010',
    },
  });

  const customer2 = await prisma.user.create({
    data: {
      email: 'jane@test.com',
      passwordHash,
      role: 'customer',
      phone: '+201000000011',
    },
  });

  // ── Create/refresh materialized view ─────────────────────────
  await prisma.$executeRawUnsafe('DROP MATERIALIZED VIEW IF EXISTS mv_active_offers');
  await prisma.$executeRawUnsafe(`
    CREATE MATERIALIZED VIEW mv_active_offers AS
    SELECT o.id, o.title, o.original_price, o.discounted_price, o.stock_remaining,
           o.end_time, o.image_url, o.tags,
           s.id AS store_id, s.name AS store_name, s.slug AS store_slug,
           s.logo_url AS store_logo_url, s.city, s.district,
           p.id AS product_id, p.name AS product_name,
           p.image_urls AS product_image_urls, p.category AS product_category
    FROM offers o
    JOIN stores s ON s.id = o.store_id
    JOIN products p ON p.id = o.product_id
    WHERE o.status = 'active' AND o.end_time > NOW() AND o.stock_remaining > 0
  `);

  console.log('\n✅ Seed complete!');
  console.log(`   Users:      ${await prisma.user.count()}`);
  console.log(`   Merchants:  ${await prisma.merchant.count()}`);
  console.log(`   Stores:     ${await prisma.store.count()}`);
  console.log(`   Products:   ${await prisma.product.count()}`);
  console.log(`   Offers:     ${await prisma.offer.count()}`);
  console.log('\n   Test accounts (password: password123):');
  console.log(`   Admin:     admin@lasthour.app`);
  console.log(`   Merchant:  merchant@breadfactory.com`);
  console.log(`   Customer:  customer@test.com / jane@test.com`);
}

main()
  .catch((e) => {
    console.error('Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

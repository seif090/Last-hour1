import { Injectable, Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../database/prisma.service';
import { RedisService } from '../../redis/redis.service';

@Injectable()
export class AdminService {
  private readonly logger = new Logger(AdminService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  async getPlatformStats() {
    const [
      totalUsers,
      totalMerchants,
      totalStores,
      totalOrders,
      totalRevenue,
      activeOffers,
      ordersToday,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.merchant.count(),
      this.prisma.store.count(),
      this.prisma.order.count(),
      this.prisma.order.aggregate({
        _sum: { totalAmount: true },
        where: { status: { notIn: ['cancelled', 'refunded'] } },
      }),
      this.prisma.offer.count({ where: { status: 'active', endTime: { gte: new Date() } } }),
      this.prisma.order.count({
        where: { createdAt: { gte: new Date(new Date().setHours(0, 0, 0, 0)) } },
      }),
    ]);

    return {
      totalUsers,
      totalMerchants,
      totalStores,
      totalOrders,
      totalRevenue: totalRevenue._sum.totalAmount ?? 0,
      activeOffers,
      ordersToday,
    };
  }

  async listMerchants(page = 1, limit = 20, verified?: boolean) {
    const where: Prisma.MerchantWhereInput = {};
    if (verified !== undefined) where.isVerified = verified;

    const [merchants, total] = await Promise.all([
      this.prisma.merchant.findMany({
        where,
        include: {
          user: { select: { id: true, email: true, createdAt: true } },
          _count: { select: { stores: true } },
        },
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.merchant.count({ where }),
    ]);

    return { merchants, meta: { page, limit, total, hasMore: page * limit < total } };
  }

  async verifyMerchant(merchantId: string) {
    const merchant = await this.prisma.merchant.update({
      where: { id: merchantId },
      data: { isVerified: true },
    });
    this.logger.log(`Merchant ${merchantId} verified`);
    return merchant;
  }

  async listOffers(status?: string, page = 1, limit = 20) {
    const where: Prisma.OfferWhereInput = {};
    if (status) where.status = status as any;

    const [offers, total] = await Promise.all([
      this.prisma.offer.findMany({
        where,
        include: {
          store: { select: { id: true, name: true } },
          product: { select: { id: true, name: true, category: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.offer.count({ where }),
    ]);

    return { offers, meta: { page, limit, total, hasMore: page * limit < total } };
  }

  async forceExpireOffer(offerId: string) {
    const offer = await this.prisma.offer.update({
      where: { id: offerId },
      data: { status: 'expired', stockRemaining: 0 },
    });

    await this.redis.invalidateStock(offerId);
    await this.redis.invalidateOffer(offerId);
    this.logger.warn(`Admin force-expired offer ${offerId}`);

    return offer;
  }

  async listUsers(page = 1, limit = 20, role?: string) {
    const where: Prisma.UserWhereInput = {};
    if (role) where.role = role as any;

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        select: {
          id: true, email: true, phone: true, role: true, isActive: true,
          createdAt: true, updatedAt: true,
          merchant: { select: { id: true, businessName: true, isVerified: true } },
          _count: { select: { customerOrders: true, reviews: true } },
        },
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.user.count({ where }),
    ]);

    return { users, meta: { page, limit, total, hasMore: page * limit < total } };
  }

  async toggleUserBan(userId: string, banned: boolean) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { isActive: !banned },
      select: { id: true, email: true, isActive: true },
    });
    this.logger.log(`User ${userId} ${banned ? 'banned' : 'unbanned'}`);
    return user;
  }

  async listOrders(page = 1, limit = 20, status?: string) {
    const where: Prisma.OrderWhereInput = {};
    if (status) where.status = status as any;

    const [orders, total] = await Promise.all([
      this.prisma.order.findMany({
        where,
        include: {
          customer: { select: { id: true, email: true } },
          offer: {
            select: { id: true, discountedPrice: true, product: { select: { name: true } } },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.order.count({ where }),
    ]);

    return { orders, meta: { page, limit, total, hasMore: page * limit < total } };
  }

  async getRevenueAnalytics(days = 30) {
    const since = new Date();
    since.setDate(since.getDate() - days);

    const orders = await this.prisma.order.findMany({
      where: {
        createdAt: { gte: since },
        status: { notIn: ['cancelled', 'refunded'] },
      },
      select: { totalAmount: true, createdAt: true, status: true },
      orderBy: { createdAt: 'asc' },
    });

    const dailyMap = new Map<string, { revenue: number; orders: number; avgOrder: number }>();
    for (const order of orders) {
      const day = order.createdAt.toISOString().slice(0, 10);
      const entry = dailyMap.get(day) || { revenue: 0, orders: 0, avgOrder: 0 };
      entry.revenue += Number(order.totalAmount);
      entry.orders += 1;
      entry.avgOrder = entry.revenue / entry.orders;
      dailyMap.set(day, entry);
    }

    const daily = Array.from(dailyMap.entries()).map(([date, data]) => ({
      date,
      ...data,
    }));

    return {
      totalRevenue: orders.reduce((sum, o) => sum + Number(o.totalAmount), 0),
      totalOrders: orders.length,
      avgOrderValue: orders.length > 0
        ? orders.reduce((sum, o) => sum + Number(o.totalAmount), 0) / orders.length
        : 0,
      period: { days },
      daily,
    };
  }

  async getSystemHealth() {
    const dbStart = Date.now();
    await this.prisma.$queryRawUnsafe('SELECT 1');
    const dbLatency = Date.now() - dbStart;

    const cacheStart = Date.now();
    await this.redis.getStock('ping');
    const cacheLatency = Date.now() - cacheStart;

    return {
      database: { status: 'connected', latencyMs: dbLatency },
      cache: { status: 'connected', latencyMs: cacheLatency },
      memory: process.memoryUsage(),
      cpu: process.cpuUsage(),
      uptime: process.uptime(),
    };
  }
}

import { Injectable, Logger } from '@nestjs/common';
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
    const where: any = {};
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
    const where: any = {};
    if (status) where.status = status;

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

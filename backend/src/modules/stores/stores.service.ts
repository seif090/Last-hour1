import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class StoresService {
  constructor(private readonly prisma: PrismaService) {}

  async findNearbyOffers(lat: number, lng: number, radiusM: number, category?: string, page = 1, limit = 20) {
    // Use materialized view for cached geo-results
    const results = await this.prisma.$queryRawUnsafe<
      Array<Record<string, unknown>>
    >(
      `SELECT * FROM fn_nearby_offers($1, $2, $3, $4, $5)`,
      lat,
      lng,
      radiusM,
      category || null,
      limit,
    );

    const total = results.length;

    return {
      offers: results,
      meta: {
        page,
        limit,
        total,
        hasMore: total >= limit,
      },
    };
  }

  async getStoreDetail(storeId: string) {
    return this.prisma.store.findUniqueOrThrow({
      where: { id: storeId },
      include: {
        merchant: { select: { id: true, businessName: true } },
        products: {
          where: { isActive: true },
          orderBy: { sortOrder: 'asc' },
        },
        _count: { select: { reviews: true } },
      },
    });
  }

  async getStoreMenu(storeId: string) {
    return this.prisma.product.findMany({
      where: { storeId, isActive: true },
      orderBy: { sortOrder: 'asc' },
      include: {
        offers: {
          where: { status: 'active', endTime: { gt: new Date() } },
          select: {
            id: true,
            discountedPrice: true,
            stockRemaining: true,
            endTime: true,
          },
        },
      },
    });
  }
}

import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class StoresService {
  constructor(private readonly prisma: PrismaService) {}

  async findNearbyOffers(lat: number, lng: number, radiusM: number, category?: string, page = 1, limit = 20) {
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
      meta: { page, limit, total, hasMore: total >= limit },
    };
  }

  async searchOffers(query: string, lat: number, lng: number, radiusM = 20000, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const searchTerm = `%${query}%`;

    const [offers, total] = await Promise.all([
      this.prisma.$queryRawUnsafe<Array<Record<string, unknown>>>(
        `SELECT o.id, o.title, o.discounted_price, o.original_price,
                o.stock_remaining, o.stock_initial, o.end_time, o.image_url,
                s.id AS store_id, s.name AS store_name, s.slug AS store_slug,
                s.rating_avg, s.rating_count,
                ST_Distance(s.location::geography, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography) AS distance_m
         FROM offers o
         JOIN stores s ON s.id = o.store_id
         WHERE o.status = 'active'
           AND o.end_time > NOW()
           AND ST_DWithin(s.location::geography, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography, $3)
           AND (o.title ILIKE $4 OR o.description ILIKE $4 OR s.name ILIKE $4)
         ORDER BY distance_m
         OFFSET $5 LIMIT $6`,
        lat,
        lng,
        radiusM,
        searchTerm,
        skip,
        limit,
      ),
      this.prisma.$queryRawUnsafe<Array<Record<string, unknown>>>(
        `SELECT COUNT(*)::int AS cnt
         FROM offers o
         JOIN stores s ON s.id = o.store_id
         WHERE o.status = 'active'
           AND o.end_time > NOW()
           AND ST_DWithin(s.location::geography, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography, $3)
           AND (o.title ILIKE $4 OR o.description ILIKE $4 OR s.name ILIKE $4)`,
        lat,
        lng,
        radiusM,
        searchTerm,
      ),
    ]);

    const count = total.length > 0 ? Number(total[0]['cnt']) : 0;

    return {
      offers,
      meta: { page, limit, total: count, hasMore: skip + limit < count },
    };
  }

  async getStoreDetail(storeId: string) {
    const store = await this.prisma.store.findUniqueOrThrow({
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
    // Fetch location separately (Unsupported geography type)
    const locResult: Array<{ coordinates: string }> = await this.prisma.$queryRawUnsafe(
      `SELECT ST_AsGeoJSON(location)::jsonb -> 'coordinates' as coordinates FROM stores WHERE id = $1`,
      storeId,
    );
    const coordinates: number[] | null = locResult[0]?.coordinates
      ? JSON.parse(locResult[0].coordinates as unknown as string)
      : null;
    const lng = coordinates?.[0] ?? null;
    const lat = coordinates?.[1] ?? null;
    return { ...store, lat, lng, location: undefined };

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

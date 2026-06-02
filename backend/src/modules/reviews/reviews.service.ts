import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class ReviewsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(customerId: string, data: { orderId: string; rating: number; comment?: string; imageUrl?: string }) {
    const order = await this.prisma.order.findUnique({
      where: { id: data.orderId },
      select: { customerId: true, storeId: true, status: true },
    });

    if (!order) throw new BadRequestException('Order not found');
    if (order.customerId !== customerId) throw new BadRequestException('Not your order');
    if (order.status !== 'picked_up') throw new BadRequestException('Order must be picked up first');

    const existing = await this.prisma.review.findUnique({
      where: { orderId: data.orderId },
    });
    if (existing) throw new BadRequestException('Already reviewed');

    const review = await this.prisma.review.create({
      data: {
        orderId: data.orderId,
        customerId,
        storeId: order.storeId,
        rating: data.rating,
        comment: data.comment,
        imageUrl: data.imageUrl,
      },
    });

    await this.updateStoreRating(order.storeId, data.rating);

    return review;
  }

  private async updateStoreRating(storeId: string, newRating: number) {
    const store = await this.prisma.store.findUnique({
      where: { id: storeId },
      select: { ratingAvg: true, ratingCount: true },
    });

    if (!store) return;

    const currentAvg = Number(store.ratingAvg);
    const newCount = store.ratingCount + 1;
    const newAvg = (currentAvg * store.ratingCount + newRating) / newCount;

    await this.prisma.store.update({
      where: { id: storeId },
      data: {
        ratingAvg: Math.round(newAvg * 100) / 100,
        ratingCount: newCount,
      },
    });
  }

  async getStoreReviews(storeId: string, page = 1, limit = 20) {
    const [reviews, total] = await Promise.all([
      this.prisma.review.findMany({
        where: { storeId },
        include: {
          customer: { select: { id: true, avatarUrl: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.review.count({ where: { storeId } }),
    ]);

    return { reviews, meta: { page, limit, total, hasMore: page * limit < total } };
  }
}

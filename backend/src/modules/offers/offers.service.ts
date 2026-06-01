import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class OffersService {
  constructor(private readonly prisma: PrismaService) {}

  async getOfferDetail(offerId: string, userId: string | null) {
    const offer = await this.prisma.offer.findUnique({
      where: { id: offerId },
      include: {
        store: {
          select: {
            id: true,
            name: true,
            slug: true,
            cuisineType: true,
            ratingAvg: true,
            ratingCount: true,
          },
        },
        product: {
          select: {
            id: true,
            name: true,
            category: true,
          },
        },
      },
    });

    if (!offer) {
      throw new NotFoundException('Offer not found');
    }

    let customerPurchasedCount = 0;
    if (userId) {
      customerPurchasedCount = await this.prisma.order.count({
        where: {
          customerId: userId,
          offerId: offerId,
          status: { in: ['confirmed', 'preparing', 'ready', 'picked_up'] },
        },
      });
    }

    return {
      id: offer.id,
      title: offer.title,
      description: offer.description,
      discounted_price: Number(offer.discountedPrice),
      original_price: Number(offer.originalPrice),
      stock_remaining: offer.stockRemaining,
      stock_initial: offer.stockInitial,
      end_time: offer.endTime,
      max_per_customer: offer.maxPerCustomer,
      store: offer.store,
      product: offer.product,
      customer_purchased_count: customerPurchasedCount,
    };
  }
}

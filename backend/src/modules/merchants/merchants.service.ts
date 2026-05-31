import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class MerchantsService {
  constructor(private readonly prisma: PrismaService) {}

  async register(userId: string, data: {
    businessName: string;
    businessType: string;
    description?: string;
    taxId?: string;
  }) {
    const existing = await this.prisma.merchant.findUnique({ where: { userId } });
    if (existing) throw new BadRequestException('Already registered as merchant');

    return this.prisma.merchant.create({
      data: {
        userId,
        businessName: data.businessName,
        businessType: data.businessType as any,
        description: data.description,
        taxId: data.taxId,
      },
    });
  }

  async getDashboard(merchantId: string) {
    const stores = await this.prisma.store.findMany({
      where: { merchantId },
      include: {
        _count: { select: { orders: true, products: true } },
        offers: {
          where: { status: 'active' },
          select: { id: true, title: true, stockRemaining: true, endTime: true },
        },
      },
    });

    return { stores };
  }

  async getTodaySales(merchantId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const stores = await this.prisma.store.findMany({
      where: { merchantId },
      select: { id: true },
    });
    const storeIds = stores.map(s => s.id);

    const [orders, offers] = await Promise.all([
      this.prisma.order.findMany({
        where: {
          storeId: { in: storeIds },
          createdAt: { gte: today, lt: tomorrow },
          status: { not: 'cancelled' },
        },
        select: { totalAmount: true, quantity: true, serviceFee: true, createdAt: true },
      }),
      this.prisma.offer.findMany({
        where: { storeId: { in: storeIds } },
        select: { id: true, status: true },
      }),
    ]);

    const totalRevenue = orders.reduce((sum, o) => sum + Number(o.totalAmount), 0);
    const totalFees = orders.reduce((sum, o) => sum + Number(o.serviceFee), 0);
    const itemsSold = orders.reduce((sum, o) => sum + o.quantity, 0);

    const ordersByHour = Array.from({ length: 24 }, (_, i) => ({
      hour: i,
      count: orders.filter(o => new Date(o.createdAt).getHours() === i).length,
    }));

    return {
      date: today.toISOString().slice(0, 10),
      totalOrders: orders.length,
      totalRevenue,
      totalFees,
      netRevenue: totalRevenue - totalFees,
      itemsSold,
      offersActive: offers.filter(o => o.status === 'active').length,
      offersSoldOut: offers.filter(o => o.status === 'sold_out').length,
      ordersByHour: ordersByHour.filter(h => h.count > 0),
    };
  }

  async createOffer(merchantId: string, data: {
    storeId: string;
    productId: string;
    title: string;
    description?: string;
    discountedPrice: number;
    originalPrice: number;
    stockInitial: number;
    maxPerCustomer?: number;
    startTime: string;
    endTime: string;
    imageUrl?: string;
    tags?: string[];
  }) {
    const store = await this.prisma.store.findFirst({
      where: { id: data.storeId, merchantId },
    });
    if (!store) throw new BadRequestException('Store not found');

    const product = await this.prisma.product.findFirst({
      where: { id: data.productId, storeId: data.storeId },
    });
    if (!product) throw new BadRequestException('Product not found');

    return this.prisma.offer.create({
      data: {
        storeId: data.storeId,
        productId: data.productId,
        title: data.title,
        description: data.description,
        discountedPrice: data.discountedPrice,
        originalPrice: data.originalPrice,
        stockInitial: data.stockInitial,
        stockRemaining: data.stockInitial,
        maxPerCustomer: data.maxPerCustomer ?? 5,
        startTime: new Date(data.startTime),
        endTime: new Date(data.endTime),
        status: new Date(data.startTime) <= new Date() ? 'active' : 'draft',
        imageUrl: data.imageUrl,
        tags: data.tags ?? [],
      },
    });
  }

  async updateStock(merchantId: string, offerId: string, stockRemaining: number) {
    const offer = await this.prisma.offer.findUnique({
      where: { id: offerId },
      include: { store: { select: { merchantId: true } } },
    });
    if (!offer || offer.store.merchantId !== merchantId) {
      throw new BadRequestException('Offer not found');
    }

    return this.prisma.offer.update({
      where: { id: offerId },
      data: {
        stockRemaining,
        status: stockRemaining === 0 ? 'sold_out' : 'active',
      },
    });
  }
}

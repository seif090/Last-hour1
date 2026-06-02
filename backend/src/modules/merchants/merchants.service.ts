import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { BusinessType, OrderStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../../database/prisma.service';
import { OffersGateway } from '../offers/offers.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { RedisService } from '../../redis/redis.service';

@Injectable()
export class MerchantsService {
  private readonly logger = new Logger(MerchantsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly offersGateway: OffersGateway,
    private readonly notificationsService: NotificationsService,
    private readonly redis: RedisService,
  ) {}

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
        businessType: data.businessType as BusinessType,
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

    const hourlyCounts = new Array(24).fill(0);
    for (const o of orders) {
      hourlyCounts[new Date(o.createdAt).getHours()]++;
    }
    const ordersByHour = hourlyCounts
      .map((count, hour) => ({ hour, count }))
      .filter(h => h.count > 0);

    return {
      date: today.toISOString().slice(0, 10),
      totalOrders: orders.length,
      totalRevenue,
      totalFees,
      netRevenue: totalRevenue - totalFees,
      itemsSold,
      offersActive: offers.filter(o => o.status === 'active').length,
      offersSoldOut: offers.filter(o => o.status === 'sold_out').length,
      ordersByHour,
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

  async updateOffer(merchantId: string, offerId: string, data: {
    title?: string;
    description?: string;
    discountedPrice?: number;
    originalPrice?: number;
    stockInitial?: number;
    maxPerCustomer?: number;
    startTime?: string;
    endTime?: string;
    imageUrl?: string;
    tags?: string[];
  }) {
    const offer = await this.prisma.offer.findUnique({
      where: { id: offerId },
      include: { store: { select: { merchantId: true } } },
    });
    if (!offer || offer.store.merchantId !== merchantId) {
      throw new BadRequestException('Offer not found');
    }

    const updateData: Record<string, unknown> = {};
    if (data.title !== undefined) updateData.title = data.title;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.discountedPrice !== undefined) updateData.discountedPrice = data.discountedPrice;
    if (data.originalPrice !== undefined) updateData.originalPrice = data.originalPrice;
    if (data.stockInitial !== undefined) {
      updateData.stockInitial = data.stockInitial;
      updateData.stockRemaining = data.stockInitial;
    }
    if (data.maxPerCustomer !== undefined) updateData.maxPerCustomer = data.maxPerCustomer;
    if (data.startTime !== undefined) updateData.startTime = new Date(data.startTime);
    if (data.endTime !== undefined) updateData.endTime = new Date(data.endTime);
    if (data.imageUrl !== undefined) updateData.imageUrl = data.imageUrl;
    if (data.tags !== undefined) updateData.tags = data.tags;

    return this.prisma.offer.update({
      where: { id: offerId },
      data: updateData,
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

  /**
   * List incoming orders for merchant stores
   */
  async listOrders(merchantId: string, status?: string, page = 1, limit = 20) {
    const stores = await this.prisma.store.findMany({
      where: { merchantId },
      select: { id: true },
    });
    const storeIds = stores.map((s) => s.id);

    const where: Prisma.OrderFindManyArgs['where'] = { storeId: { in: storeIds } };
    if (status) where.status = status as OrderStatus;

    const [orders, total] = await Promise.all([
      this.prisma.order.findMany({
        where,
        include: {
          customer: { select: { id: true, email: true, phone: true } },
          store: { select: { id: true, name: true } },
          offer: { select: { id: true, title: true, imageUrl: true } },
          payment: { select: { id: true, provider: true, status: true, amount: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.order.count({ where }),
    ]);

    return {
      orders: orders.map((o) => ({
        id: o.id,
        orderNumber: o.orderNumber,
        status: o.status,
        quantity: o.quantity,
        totalAmount: Number(o.totalAmount),
        createdAt: o.createdAt,
        customer: o.customer,
        store: o.store,
        offer: o.offer,
        payment: o.payment
          ? {
              id: o.payment.id,
              provider: o.payment.provider,
              status: o.payment.status,
              amount: Number(o.payment.amount),
            }
          : null,
      })),
      meta: { page, limit, total, hasMore: page * limit < total },
    };
  }

  /**
   * Update state of an order with notification & WebSocket dispatching
   */
  async updateOrderStatus(merchantId: string, orderId: string, status: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        store: { select: { id: true, name: true, merchantId: true } },
        offer: true,
      },
    });

    if (!order || order.store.merchantId !== merchantId) {
      throw new BadRequestException('Order not found');
    }

    const currentStatus = order.status;
    const targetStatus = status as OrderStatus;

    // State machine check
    const validTransitions: Record<string, string[]> = {
      pending: ['confirmed', 'cancelled'],
      confirmed: ['preparing', 'cancelled'],
      preparing: ['ready', 'cancelled'],
      ready: ['picked_up', 'cancelled'],
      picked_up: [],
      cancelled: [],
      refunded: [],
    };

    if (!validTransitions[currentStatus]?.includes(targetStatus)) {
      throw new BadRequestException(
        `Cannot transition order from status "${currentStatus}" to "${targetStatus}"`,
      );
    }

    // 1. Transactionally update DB
    const updatedOrder = await this.prisma.$transaction(async (tx) => {
      const data: Prisma.OrderUpdateInput = { status: targetStatus };

      if (targetStatus === 'picked_up') {
        data.pickedUpAt = new Date();
      } else if (targetStatus === 'cancelled') {
        data.cancelledAt = new Date();
        data.cancelReason = 'Cancelled by merchant';

        // Restore postgres stock
        await tx.offer.update({
          where: { id: order.offerId },
          data: {
            stockRemaining: { increment: order.quantity },
          },
        });
      }

      return tx.order.update({
        where: { id: orderId },
        data,
      });
    });

    // 2. Post-Transaction actions
    if (targetStatus === 'cancelled') {
      try {
        // Restore Redis stock
        const currentRedis = await this.redis.getStock(order.offerId);
        if (currentRedis !== null) {
          await this.redis.initStock(order.offerId, currentRedis + order.quantity);
        } else {
          const freshOffer = await this.prisma.offer.findUnique({
            where: { id: order.offerId },
          });
          if (freshOffer) {
            await this.redis.initStock(order.offerId, Number(freshOffer.stockRemaining));
          }
        }

        // Broadcast Redis stock update via WebSockets
        const freshRedis = await this.redis.getStock(order.offerId);
        this.offersGateway.broadcastStockUpdate(
          order.offerId,
          order.storeId,
          freshRedis !== null ? freshRedis : order.offer.stockRemaining + order.quantity,
        );
      } catch (err) {
        this.logger.error(`Failed to restore Redis stock for cancellation of order ${orderId}`, err);
      }
    }

    // Broadcast status change via WebSockets
    this.offersGateway.broadcastOrderStatus(
      orderId,
      order.customerId,
      targetStatus,
      updatedOrder.estimatedReadyAt || undefined,
    );

    // Send push notification if marked ready for pickup
    if (targetStatus === 'ready') {
      await this.notificationsService.onOrderReady(
        orderId,
        order.store.name,
        order.customerId,
      );
    }

    return updatedOrder;
  }

  async updateStoreHours(merchantId: string, storeId: string, dto: Record<string, string>) {
    const store = await this.prisma.store.findUnique({
      where: { id: storeId },
      select: { merchantId: true },
    });
    if (!store || store.merchantId !== merchantId) {
      throw new BadRequestException('Store not found');
    }
    const data: Record<string, unknown> = {};
    if (dto.opensAt !== undefined) data.opensAt = dto.opensAt;
    if (dto.closesAt !== undefined) data.closesAt = dto.closesAt;
    if (dto.timezone !== undefined) data.timezone = dto.timezone;
    return this.prisma.store.update({ where: { id: storeId }, data });
  }

  async getFirstStoreId(userId: string): Promise<string> {
    const merchant = await this.prisma.merchant.findUnique({ where: { userId } });
    if (!merchant) throw new BadRequestException('Merchant profile not found');
    const store = await this.prisma.store.findFirst({ where: { merchantId: merchant.id } });
    if (!store) throw new BadRequestException('No store found for this merchant');
    return store.id;
  }

  async getAnalytics(merchantId: string, days: number) {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const stores = await this.prisma.store.findMany({
      where: { merchantId },
      select: { id: true },
    });
    const storeIds = stores.map((s) => s.id);

    const [orders, revenue] = await Promise.all([
      this.prisma.order.findMany({
        where: {
          storeId: { in: storeIds },
          createdAt: { gte: startDate },
        },
        select: {
          id: true,
          status: true,
          totalAmount: true,
          createdAt: true,
          storeId: true,
        },
        orderBy: { createdAt: 'asc' },
      }),
      this.prisma.order.aggregate({
        where: {
          storeId: { in: storeIds },
          status: { in: ['picked_up', 'confirmed', 'preparing', 'ready'] },
          createdAt: { gte: startDate },
        },
        _sum: { totalAmount: true },
      }),
    ]);

    const ordersByDay: Record<string, { count: number; revenue: number }> = {};
    for (let i = 0; i < days; i++) {
      const d = new Date(startDate);
      d.setDate(d.getDate() + i);
      const key = d.toISOString().split('T')[0];
      ordersByDay[key] = { count: 0, revenue: 0 };
    }

    for (const order of orders) {
      const key = order.createdAt.toISOString().split('T')[0];
      if (ordersByDay[key]) {
        ordersByDay[key].count++;
        if (order.status !== 'cancelled' && order.status !== 'refunded') {
          ordersByDay[key].revenue += Number(order.totalAmount);
        }
      }
    }

    return {
      totalOrders: orders.length,
      totalRevenue: Number(revenue._sum?.totalAmount ?? 0),
      daily: Object.entries(ordersByDay).map(([date, data]) => ({
        date,
        orders: data.count,
        revenue: data.revenue,
      })),
      stores: stores.length,
    };
  }

  async generateCsvReport(merchantId: string, days: number, storeId?: string) {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const stores = await this.prisma.store.findMany({
      where: { merchantId, ...(storeId ? { id: storeId } : {}) },
      select: { id: true, name: true },
    });
    const storeIds = stores.map((s) => s.id);

    const orders = await this.prisma.order.findMany({
      where: {
        storeId: { in: storeIds },
        createdAt: { gte: startDate },
      },
      include: {
        store: { select: { name: true } },
        customer: { select: { email: true } },
        payment: { select: { provider: true, status: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    const header = 'Order#,Date,Status,Store,Customer,Items,Subtotal,Discount,Fee,Total,Payment,Payment Status\n';
    const rows = orders.map((o) =>
      [
        o.orderNumber,
        o.createdAt.toISOString().split('T')[0],
        o.status,
        `"${o.store.name}"`,
        o.customer.email,
        o.quantity,
        Number(o.subtotal).toFixed(2),
        Number(o.discountAmount).toFixed(2),
        Number(o.serviceFee).toFixed(2),
        Number(o.totalAmount).toFixed(2),
        o.payment?.provider ?? '',
        o.payment?.status ?? '',
      ].join(','),
    );

    return header + rows.join('\n');
  }

  async getInvoice(merchantId: string, orderId: string) {
    const stores = await this.prisma.store.findMany({
      where: { merchantId },
      select: { id: true },
    });
    const storeIds = stores.map((s) => s.id);

    const order = await this.prisma.order.findFirst({
      where: { id: orderId, storeId: { in: storeIds } },
      include: {
        items: true,
        payment: true,
        store: { select: { id: true, name: true, addressLine1: true, city: true, logoUrl: true } },
        customer: { select: { id: true, email: true, phone: true } },
        coupon: { select: { code: true } },
        offer: { select: { id: true, title: true } },
      },
    });

    if (!order) throw new BadRequestException('Order not found');

    return {
      invoiceNumber: `INV-${order.orderNumber}`,
      orderNumber: order.orderNumber,
      createdAt: order.createdAt,
      status: order.status,
      store: order.store,
      customer: order.customer,
      offer: order.offer,
      items: order.items,
      subtotal: Number(order.subtotal),
      discountAmount: Number(order.discountAmount),
      couponCode: order.coupon?.code ?? null,
      serviceFee: Number(order.serviceFee),
      totalAmount: Number(order.totalAmount),
      currency: order.currency,
      payment: order.payment ? { provider: order.payment.provider, status: order.payment.status, paidAt: order.payment.paidAt } : null,
    };
  }
}

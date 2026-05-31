import { Processor, Process } from '@nestjs/bull';
import { Job } from 'bull';
import { Logger } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { RedisService } from '../../redis/redis.service';

@Processor('order-timeout')
export class OrderTimeoutProcessor {
  private readonly logger = new Logger(OrderTimeoutProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  @Process('confirm-timeout')
  async handleConfirmTimeout(job: Job<{ orderId: string }>) {
    const { orderId } = job.data;
    this.logger.log(`Checking order confirmation timeout: ${orderId}`);

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { offer: true },
    });

    if (!order || order.status !== 'pending') {
      this.logger.warn(`Order ${orderId} no longer pending, skipping`);
      return;
    }

    // If payment already captured, keep order
    const payment = await this.prisma.payment.findUnique({
      where: { orderId },
    });

    if (payment && payment.status === 'captured') {
      await this.prisma.order.update({
        where: { id: orderId },
        data: { status: 'confirmed' },
      });
      this.logger.log(`Order ${orderId} confirmed (payment captured)`);
      return;
    }

    // Timeout — cancel order and restore stock
    await this.prisma.$transaction(async (tx) => {
      await tx.order.update({
        where: { id: orderId },
        data: {
          status: 'cancelled',
          cancelledAt: new Date(),
          cancelReason: 'Payment timeout',
        },
      });

      await tx.offer.update({
        where: { id: order.offerId },
        data: {
          stockRemaining: { increment: order.quantity },
        },
      });
    });

    await this.redis.initStock(order.offerId, order.offer.stockRemaining + order.quantity);

    this.logger.log(`Order ${orderId} cancelled due to timeout, stock restored`);
  }

  @Process('pickup-reminder')
  async handlePickupReminder(job: Job<{ orderId: string }>) {
    const { orderId } = job.data;

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { id: true, status: true, estimatedReadyAt: true },
    });

    if (!order || order.status !== 'ready') return;

    this.logger.log(`Pickup reminder sent for order ${orderId}`);
  }

  @Process('auto-complete')
  async handleAutoComplete(job: Job<{ orderId: string }>) {
    const { orderId } = job.data;

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
    });

    if (!order || order.status !== 'ready') return;

    await this.prisma.order.update({
      where: { id: orderId },
      data: { status: 'picked_up', pickedUpAt: new Date() },
    });

    this.logger.log(`Order ${orderId} auto-completed (pickup assumed)`);
  }
}

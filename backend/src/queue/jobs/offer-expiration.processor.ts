import { Processor, Process } from '@nestjs/bull';
import { Job } from 'bull';
import { Logger } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { RedisService } from '../../redis/redis.service';

@Processor('offer-expiration')
export class OfferExpirationProcessor {
  private readonly logger = new Logger(OfferExpirationProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  @Process('expire-offer')
  async handleExpireOffer(job: Job<{ offerId: string }>) {
    const { offerId } = job.data;
    this.logger.log(`Processing offer expiration: ${offerId}`);

    const offer = await this.prisma.offer.findUnique({
      where: { id: offerId },
      select: { id: true, status: true, endTime: true, storeId: true },
    });

    if (!offer || offer.status !== 'active') {
      this.logger.warn(`Offer ${offerId} already inactive or not found`);
      return;
    }

    await this.prisma.offer.update({
      where: { id: offerId },
      data: {
        status: 'expired',
        stockRemaining: 0,
      },
    });

    await this.redis.invalidateStock(offerId);
    await this.redis.invalidateOffer(offerId);

    this.logger.log(`Offer ${offerId} expired and cache invalidated`);
  }

  @Process('check-active-offers')
  async handleCheckActiveOffers(_job: Job<{ limit?: number }>) {
    this.logger.log('Running scheduled active offer check');

    const expired = await this.prisma.offer.updateMany({
      where: {
        status: 'active',
        endTime: { lte: new Date() },
      },
      data: {
        status: 'expired',
        stockRemaining: 0,
      },
    });

    if (expired.count > 0) {
      this.logger.log(`Auto-expired ${expired.count} offers`);
    }
  }

  @Process('warn-expiring-soon')
  async handleWarnExpiring(job: Job<{ withinMinutes: number }>) {
    const { withinMinutes } = job.data;
    const threshold = new Date(Date.now() + withinMinutes * 60 * 1000);

    const expiringSoon = await this.prisma.offer.findMany({
      where: {
        status: 'active',
        endTime: { lte: threshold, gte: new Date() },
      },
      select: { id: true, title: true, storeId: true, endTime: true },
    });

    if (expiringSoon.length > 0) {
      this.logger.log(`${expiringSoon.length} offers expiring within ${withinMinutes}min`);
    }
  }
}

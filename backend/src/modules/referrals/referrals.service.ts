import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class ReferralsService {
  constructor(private readonly prisma: PrismaService) {}

  async getReferralInfo(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { referralCode: true },
    });

    const stats = await this.prisma.referral.aggregate({
      where: { referrerId: userId },
      _count: true,
    });

    const rewarded = await this.prisma.referral.count({
      where: { referrerId: userId, status: 'rewarded' },
    });

    return {
      referralCode: user?.referralCode,
      totalReferrals: stats._count,
      rewardedReferrals: rewarded,
    };
  }

  async getReferrals(userId: string) {
    return this.prisma.referral.findMany({
      where: { referrerId: userId },
      include: {
        referee: { select: { email: true, createdAt: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getRewardsSummary(userId: string) {
    const totalRewarded = await this.prisma.referral.aggregate({
      where: { referrerId: userId, status: 'rewarded' },
      _sum: { rewardAmount: true },
    });

    const pendingRewards = await this.prisma.referral.aggregate({
      where: { referrerId: userId, status: 'pending' },
      _count: true,
    });

    return {
      totalRewards: Number(totalRewarded._sum?.rewardAmount ?? 0),
      pendingReferrals: pendingRewards._count,
    };
  }

  async rewardReferral(refereeId: string): Promise<boolean> {
    const referral = await this.prisma.referral.findUnique({
      where: { refereeId },
    });
    if (!referral || referral.status !== 'pending') return false;

    const orderCount = await this.prisma.order.count({
      where: { customerId: refereeId, status: 'confirmed' },
    });
    if (orderCount > 1) return false;

    await this.prisma.referral.update({
      where: { id: referral.id },
      data: {
        status: 'rewarded',
        rewardAmount: 10.0,
        rewardedAt: new Date(),
      },
    });
    return true;
  }
}

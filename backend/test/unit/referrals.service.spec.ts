import { Test, TestingModule } from '@nestjs/testing';
import { ReferralsService } from '../../src/modules/referrals/referrals.service';
import { PrismaService } from '../../src/database/prisma.service';

describe('ReferralsService', () => {
  let service: ReferralsService;
  let prisma: any;

  const mockUser = { id: 'user-1', referralCode: 'LH-ABC123' };
  const mockReferral = {
    id: 'ref-1',
    referrerId: 'user-1',
    refereeId: 'user-2',
    status: 'pending',
    rewardAmount: null,
    createdAt: new Date(),
  };

  beforeEach(async () => {
    prisma = {
      user: { findUnique: jest.fn() },
      referral: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        aggregate: jest.fn(),
        count: jest.fn(),
        update: jest.fn(),
      },
      order: { count: jest.fn() },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ReferralsService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();

    service = module.get<ReferralsService>(ReferralsService);
  });

  describe('getReferralInfo', () => {
    it('should return referral code and stats', async () => {
      prisma.user.findUnique.mockResolvedValue(mockUser);
      prisma.referral.aggregate.mockResolvedValue({ _count: 5 });
      prisma.referral.count.mockResolvedValue(2);
      const result = await service.getReferralInfo('user-1');
      expect(result.referralCode).toBe('LH-ABC123');
      expect(result.totalReferrals).toBe(5);
      expect(result.rewardedReferrals).toBe(2);
    });
  });

  describe('getReferrals', () => {
    it('should return referrals for user', async () => {
      prisma.referral.findMany.mockResolvedValue([mockReferral]);
      const result = await service.getReferrals('user-1');
      expect(prisma.referral.findMany).toHaveBeenCalledWith({
        where: { referrerId: 'user-1' },
        include: { referee: { select: { email: true, createdAt: true } } },
        orderBy: { createdAt: 'desc' },
      });
      expect(result).toEqual([mockReferral]);
    });
  });

  describe('getRewardsSummary', () => {
    it('should return rewards summary', async () => {
      prisma.referral.aggregate
        .mockResolvedValueOnce({ _sum: { rewardAmount: 30 } })
        .mockResolvedValueOnce({ _count: 3 });
      const result = await service.getRewardsSummary('user-1');
      expect(result.totalRewards).toBe(30);
      expect(result.pendingReferrals).toBe(3);
    });
  });

  describe('rewardReferral', () => {
    it('should reward a referral on first confirmed order', async () => {
      prisma.referral.findUnique.mockResolvedValue(mockReferral);
      prisma.order.count.mockResolvedValue(1);
      prisma.referral.update.mockResolvedValue({ ...mockReferral, status: 'rewarded', rewardAmount: 10 });
      const result = await service.rewardReferral('user-2');
      expect(result).toBe(true);
      expect(prisma.referral.update).toHaveBeenCalledWith({
        where: { id: 'ref-1' },
        data: { status: 'rewarded', rewardAmount: 10.0, rewardedAt: expect.any(Date) },
      });
    });

    it('should return false if no referral record', async () => {
      prisma.referral.findUnique.mockResolvedValue(null);
      const result = await service.rewardReferral('user-2');
      expect(result).toBe(false);
    });

    it('should return false if referral already rewarded', async () => {
      prisma.referral.findUnique.mockResolvedValue({ ...mockReferral, status: 'rewarded' });
      const result = await service.rewardReferral('user-2');
      expect(result).toBe(false);
    });

    it('should return false if not first confirmed order', async () => {
      prisma.referral.findUnique.mockResolvedValue(mockReferral);
      prisma.order.count.mockResolvedValue(3);
      const result = await service.rewardReferral('user-2');
      expect(result).toBe(false);
    });
  });
});

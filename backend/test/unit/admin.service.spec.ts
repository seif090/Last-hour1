import { Test, TestingModule } from '@nestjs/testing';
import { AdminService } from '../../src/modules/admin/admin.service';
import { PrismaService } from '../../src/database/prisma.service';
import { RedisService } from '../../src/redis/redis.service';

describe('AdminService', () => {
  let service: AdminService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      user: { count: jest.fn(), findMany: jest.fn(), update: jest.fn() },
      merchant: { count: jest.fn(), findMany: jest.fn(), update: jest.fn() },
      store: { count: jest.fn() },
      order: { count: jest.fn(), aggregate: jest.fn(), findMany: jest.fn() },
      offer: { count: jest.fn(), findMany: jest.fn(), update: jest.fn() },
      coupon: { findMany: jest.fn(), count: jest.fn() },
      referral: { findMany: jest.fn(), count: jest.fn(), aggregate: jest.fn() },
      $queryRawUnsafe: jest.fn(),
    };

    const redis = { getStock: jest.fn(), invalidateStock: jest.fn(), invalidateOffer: jest.fn() };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminService,
        { provide: PrismaService, useValue: prisma },
        { provide: RedisService, useValue: redis },
      ],
    }).compile();

    service = module.get<AdminService>(AdminService);
  });

  describe('listCoupons', () => {
    it('should return paginated coupons', async () => {
      prisma.coupon.findMany.mockResolvedValue([{ id: 'c1', code: 'SAVE20', store: { id: 's1', name: 'Store' } }]);
      prisma.coupon.count.mockResolvedValue(1);
      const result = await service.listCoupons(1, 20);
      expect(result.coupons).toHaveLength(1);
      expect(result.meta.hasMore).toBe(false);
    });

    it('should filter by storeId', async () => {
      prisma.coupon.findMany.mockResolvedValue([]);
      prisma.coupon.count.mockResolvedValue(0);
      await service.listCoupons(1, 20, 'store-1');
      expect(prisma.coupon.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { storeId: 'store-1' } }),
      );
    });
  });

  describe('listReferrals', () => {
    it('should return paginated referrals', async () => {
      prisma.referral.findMany.mockResolvedValue([{
        id: 'r1', referrer: { id: 'u1', email: 'a@b.com' }, referee: { id: 'u2', email: 'c@d.com' },
      }]);
      prisma.referral.count.mockResolvedValue(1);
      const result = await service.listReferrals(1, 20);
      expect(result.referrals).toHaveLength(1);
      expect(result.meta.total).toBe(1);
    });
  });

  describe('getReferralStats', () => {
    it('should return referral statistics', async () => {
      prisma.referral.count.mockResolvedValueOnce(10).mockResolvedValueOnce(5).mockResolvedValueOnce(3);
      prisma.referral.aggregate.mockResolvedValue({ _sum: { rewardAmount: 50 } });
      const result = await service.getReferralStats();
      expect(result.totalReferrals).toBe(10);
      expect(result.rewardedCount).toBe(5);
      expect(result.totalRewardAmount).toBe(50);
      expect(result.pendingCount).toBe(3);
    });
  });
});

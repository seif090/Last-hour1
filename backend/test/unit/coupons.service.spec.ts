import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { CouponsService } from '../../src/modules/coupons/coupons.service';
import { PrismaService } from '../../src/database/prisma.service';

describe('CouponsService', () => {
  let service: CouponsService;
  let prisma: any;

  const mockCoupon = {
    id: 'coupon-1',
    storeId: 'store-1',
    code: 'SAVE20',
    discountType: 'percentage',
    discountValue: 20,
    minOrderAmount: 50,
    maxDiscount: 30,
    maxUses: 100,
    currentUses: 5,
    isActive: true,
    expiresAt: new Date(Date.now() + 86400000),
    startsAt: null,
    description: 'Save 20%',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(async () => {
    prisma = {
      coupon: {
        findUnique: jest.fn(),
        findFirst: jest.fn(),
        findMany: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CouponsService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();

    service = module.get<CouponsService>(CouponsService);
  });

  describe('create', () => {
    it('should create a coupon', async () => {
      prisma.coupon.findUnique.mockResolvedValue(null);
      prisma.coupon.create.mockResolvedValue(mockCoupon);
      const result = await service.create('store-1', {
        code: 'save20',
        discountType: 'percentage',
        discountValue: 20,
        minOrderAmount: 50,
        maxDiscount: 30,
      });
      expect(prisma.coupon.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          storeId: 'store-1',
          code: 'SAVE20',
          discountType: 'percentage',
          discountValue: 20,
          maxUses: 100,
        }),
      });
      expect(result).toEqual(mockCoupon);
    });

    it('should throw if coupon code already exists', async () => {
      prisma.coupon.findUnique.mockResolvedValue(mockCoupon);
      await expect(service.create('store-1', {
        code: 'SAVE20',
        discountType: 'percentage',
        discountValue: 20,
      })).rejects.toThrow(BadRequestException);
    });
  });

  describe('findByStore', () => {
    it('should return coupons for a store', async () => {
      prisma.coupon.findMany.mockResolvedValue([mockCoupon]);
      const result = await service.findByStore('store-1');
      expect(prisma.coupon.findMany).toHaveBeenCalledWith({
        where: { storeId: 'store-1' },
        orderBy: { createdAt: 'desc' },
      });
      expect(result).toEqual([mockCoupon]);
    });
  });

  describe('validateAndApply', () => {
    it('should validate and apply a valid coupon', async () => {
      prisma.coupon.findUnique.mockResolvedValue(mockCoupon);
      const result = await service.validateAndApply('store-1', { code: 'SAVE20', orderTotal: 100 });
      expect(result.valid).toBe(true);
      expect(result.discount).toBe(20);
      expect(result.couponId).toBe('coupon-1');
    });

    it('should cap discount at maxDiscount', async () => {
      prisma.coupon.findUnique.mockResolvedValue(mockCoupon);
      const result = await service.validateAndApply('store-1', { code: 'SAVE20', orderTotal: 200 });
      expect(result.discount).toBe(30);
    });

    it('should throw if coupon not found', async () => {
      prisma.coupon.findUnique.mockResolvedValue(null);
      await expect(service.validateAndApply('store-1', { code: 'INVALID', orderTotal: 100 }))
        .rejects.toThrow(NotFoundException);
    });

    it('should throw if coupon belongs to different store', async () => {
      prisma.coupon.findUnique.mockResolvedValue(mockCoupon);
      await expect(service.validateAndApply('store-2', { code: 'SAVE20', orderTotal: 100 }))
        .rejects.toThrow(BadRequestException);
    });

    it('should throw if coupon is inactive', async () => {
      prisma.coupon.findUnique.mockResolvedValue({ ...mockCoupon, isActive: false });
      await expect(service.validateAndApply('store-1', { code: 'SAVE20', orderTotal: 100 }))
        .rejects.toThrow(BadRequestException);
    });

    it('should throw if coupon has reached max uses', async () => {
      prisma.coupon.findUnique.mockResolvedValue({ ...mockCoupon, currentUses: 100, maxUses: 100 });
      await expect(service.validateAndApply('store-1', { code: 'SAVE20', orderTotal: 100 }))
        .rejects.toThrow(BadRequestException);
    });

    it('should throw if coupon has expired', async () => {
      prisma.coupon.findUnique.mockResolvedValue({ ...mockCoupon, expiresAt: new Date(Date.now() - 86400000) });
      await expect(service.validateAndApply('store-1', { code: 'SAVE20', orderTotal: 100 }))
        .rejects.toThrow(BadRequestException);
    });

    it('should throw if coupon not yet valid', async () => {
      prisma.coupon.findUnique.mockResolvedValue({ ...mockCoupon, startsAt: new Date(Date.now() + 86400000) });
      await expect(service.validateAndApply('store-1', { code: 'SAVE20', orderTotal: 100 }))
        .rejects.toThrow(BadRequestException);
    });

    it('should throw if order total below min order amount', async () => {
      prisma.coupon.findUnique.mockResolvedValue(mockCoupon);
      await expect(service.validateAndApply('store-1', { code: 'SAVE20', orderTotal: 30 }))
        .rejects.toThrow(BadRequestException);
    });
  });

  describe('useCoupon', () => {
    it('should increment currentUses', async () => {
      prisma.coupon.update.mockResolvedValue(mockCoupon);
      await service.useCoupon('coupon-1');
      expect(prisma.coupon.update).toHaveBeenCalledWith({
        where: { id: 'coupon-1' },
        data: { currentUses: { increment: 1 } },
      });
    });
  });

  describe('toggleActive', () => {
    it('should toggle isActive', async () => {
      prisma.coupon.findFirst.mockResolvedValue(mockCoupon);
      prisma.coupon.update.mockResolvedValue({ ...mockCoupon, isActive: false });
      const result = await service.toggleActive('coupon-1', 'store-1');
      expect(prisma.coupon.update).toHaveBeenCalledWith({
        where: { id: 'coupon-1' },
        data: { isActive: !mockCoupon.isActive },
      });
      expect(result.isActive).toBe(false);
    });

    it('should throw if coupon not found for store', async () => {
      prisma.coupon.findFirst.mockResolvedValue(null);
      await expect(service.toggleActive('coupon-1', 'store-1'))
        .rejects.toThrow(NotFoundException);
    });
  });
});

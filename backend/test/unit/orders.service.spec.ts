import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException, BadRequestException } from '@nestjs/common';
import { OrdersService } from '../../src/modules/orders/orders.service';
import { PrismaService } from '../../src/database/prisma.service';
import { RedisService } from '../../src/redis/redis.service';

describe('OrdersService', () => {
  let service: OrdersService;
  let prisma: any;
  let redis: any;

  const mockOffer = {
    id: 'offer-1',
    storeId: 'store-1',
    productId: 'prod-1',
    discountedPrice: 15.00,
    status: 'active',
    endTime: new Date(Date.now() + 3600000),
    stockRemaining: 50,
    maxPerCustomer: 5,
    store: { id: 'store-1', name: 'Test Store' },
    product: { id: 'prod-1', name: 'Test Product' },
  };

  beforeEach(async () => {
    prisma = {
      offer: {
        findUnique: jest.fn().mockResolvedValue(mockOffer),
        update: jest.fn(),
      },
      order: {
        create: jest.fn().mockResolvedValue({
          id: 'order-1',
          orderNumber: 'LH-ABC123',
          status: 'confirmed',
          quantity: 2,
          totalAmount: 31.50,
        }),
        findUnique: jest.fn(),
      },
      $transaction: jest.fn((fn: any) => fn(prisma)),
      $queryRawUnsafe: jest.fn().mockResolvedValue([{ success: true, remaining: 48 }]),
    };

    redis = {
      decrementStock: jest.fn().mockResolvedValue({ code: 0, remaining: 48 }),
      initStock: jest.fn(),
      getStock: jest.fn().mockResolvedValue(48),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrdersService,
        { provide: PrismaService, useValue: prisma },
        { provide: RedisService, useValue: redis },
      ],
    }).compile();

    service = module.get<OrdersService>(OrdersService);
  });

  describe('placeOrder', () => {
    it('should place order successfully', async () => {
      const result = await service.placeOrder(
        { offerId: 'offer-1', quantity: 2, payment: { provider: 'stripe', paymentMethodId: 'pm_test' } },
        'user-1',
      );

      expect(result).toBeDefined();
      expect(result.status).toBe('confirmed');
      expect(redis.decrementStock).toHaveBeenCalledWith('offer-1', 2, expect.any(Number));
    });

    it('should throw when offer expired', async () => {
      prisma.offer.findUnique.mockResolvedValue({
        ...mockOffer,
        status: 'expired',
      });

      await expect(
        service.placeOrder(
          { offerId: 'offer-1', quantity: 2, payment: { provider: 'stripe', paymentMethodId: 'pm_test' } },
          'user-1',
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw when stock insufficient in Redis', async () => {
      redis.decrementStock.mockResolvedValue({ code: -1, remaining: 1 });

      await expect(
        service.placeOrder(
          { offerId: 'offer-1', quantity: 5, payment: { provider: 'stripe', paymentMethodId: 'pm_test' } },
          'user-1',
        ),
      ).rejects.toThrow(ConflictException);
    });

    it('should throw when exceeding max per customer', async () => {
      await expect(
        service.placeOrder(
          { offerId: 'offer-1', quantity: 10, payment: { provider: 'stripe', paymentMethodId: 'pm_test' } },
          'user-1',
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('should restore Redis stock on PG failure', async () => {
      prisma.$transaction.mockRejectedValue(new Error('DB error'));

      await expect(
        service.placeOrder(
          { offerId: 'offer-1', quantity: 2, payment: { provider: 'stripe', paymentMethodId: 'pm_test' } },
          'user-1',
        ),
      ).rejects.toThrow('DB error');

      expect(redis.initStock).toHaveBeenCalledWith('offer-1', 50);
    });
  });
});

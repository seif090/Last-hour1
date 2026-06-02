import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException, BadRequestException } from '@nestjs/common';
import { getQueueToken } from '@nestjs/bull';
import { OrdersService } from '../../src/modules/orders/orders.service';
import { PrismaService } from '../../src/database/prisma.service';
import { RedisService } from '../../src/redis/redis.service';
import { PaymentsService } from '../../src/modules/payments/payments.service';
import { OffersGateway } from '../../src/modules/offers/offers.gateway';
import { NotificationsService } from '../../src/modules/notifications/notifications.service';
import { CouponsService } from '../../src/modules/coupons/coupons.service';
import { ReferralsService } from '../../src/modules/referrals/referrals.service';

describe('OrdersService', () => {
  let service: OrdersService;
  let prisma: any;
  let redis: any;
  let paymentsService: any;
  let offersGateway: any;
  let notificationsService: any;
  let couponsService: any;
  let referralsService: any;
  let orderTimeoutQueue: any;

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
          unitPrice: 15.00,
          subtotal: 30.00,
          serviceFee: 1.50,
          totalAmount: 31.50,
          currency: 'EGP',
          createdAt: new Date(),
        }),
        findUnique: jest.fn(),
        findFirst: jest.fn().mockResolvedValue(null),
        update: jest.fn().mockImplementation((args: any) => Promise.resolve({
          id: args.where?.id || 'order-1',
          orderNumber: 'LH-ABC123',
          status: args.data?.status || 'confirmed',
          quantity: 2,
          unitPrice: 15.00,
          subtotal: 30.00,
          serviceFee: 1.50,
          totalAmount: 31.50,
          currency: 'EGP',
          createdAt: new Date(),
        })),
      },
      payment: {
        create: jest.fn().mockResolvedValue({
          id: 'pay-1',
          provider: 'stripe',
          amount: 31.50,
          status: 'captured',
          metadata: {},
        }),
        findUnique: jest.fn().mockResolvedValue({
          id: 'pay-1',
          provider: 'stripe',
          amount: 31.50,
          status: 'captured',
          metadata: {},
        }),
      },
      $transaction: jest.fn((fn: any) => fn(prisma)),
      $queryRawUnsafe: jest.fn().mockResolvedValue([{ success: true, remaining: 48 }]),
    };

    redis = {
      decrementStock: jest.fn().mockResolvedValue({ code: 0, remaining: 48 }),
      initStock: jest.fn(),
      getStock: jest.fn().mockResolvedValue(48),
    };

    paymentsService = {
      charge: jest.fn().mockResolvedValue({
        providerTxId: 'ch_test',
        status: 'captured',
      }),
    };

    offersGateway = {
      broadcastStockUpdate: jest.fn(),
      broadcastOrderStatus: jest.fn(),
    };

    notificationsService = {
      onOrderConfirmed: jest.fn(),
    };

    couponsService = {
      validateAndApply: jest.fn(),
      useCoupon: jest.fn(),
    };

    orderTimeoutQueue = {
      add: jest.fn(),
    };

    referralsService = {
      rewardReferral: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrdersService,
        { provide: PrismaService, useValue: prisma },
        { provide: RedisService, useValue: redis },
        { provide: PaymentsService, useValue: paymentsService },
        { provide: OffersGateway, useValue: offersGateway },
        { provide: NotificationsService, useValue: notificationsService },
        { provide: CouponsService, useValue: couponsService },
        { provide: ReferralsService, useValue: referralsService },
        { provide: getQueueToken('order-timeout'), useValue: orderTimeoutQueue },
      ],
    }).compile();

    service = module.get<OrdersService>(OrdersService);
  });

  describe('placeOrder', () => {
    it('should place order successfully via Stripe (synchronous capture)', async () => {
      const result = await service.placeOrder(
        {
          offerId: 'offer-1',
          quantity: 2,
          payment: { provider: 'stripe', paymentMethodId: 'pm_test' },
        },
        'user-1',
      );

      expect(result).toBeDefined();
      expect(result.order.status).toBe('confirmed');
      expect(result.payment.status).toBe('captured');
      expect(redis.decrementStock).toHaveBeenCalledWith('offer-1', 2, expect.any(Number));
      expect(paymentsService.charge).toHaveBeenCalledWith(
        { provider: 'stripe', paymentMethodId: 'pm_test' },
        expect.objectContaining({ totalAmount: 31.5 }),
      );
      expect(offersGateway.broadcastStockUpdate).toHaveBeenCalledWith('offer-1', 'store-1', 48);
      expect(offersGateway.broadcastOrderStatus).toHaveBeenCalledWith('order-1', 'user-1', 'confirmed');
      expect(notificationsService.onOrderConfirmed).toHaveBeenCalledWith('order-1', 'user-1');
    });

    it('should place order successfully via Paymob (asynchronous pending redirection)', async () => {
      // Mock Paymob response
      paymentsService.charge.mockResolvedValue({
        providerTxId: 'tok_test',
        status: 'pending',
        iframeUrl: 'https://paymob.iframe.url',
        paymentKey: 'tok_test',
      });

      prisma.order.create.mockResolvedValue({
        id: 'order-1',
        orderNumber: 'LH-ABC123',
        status: 'pending',
        quantity: 2,
        unitPrice: 15.00,
        subtotal: 30.00,
        serviceFee: 1.50,
        totalAmount: 31.50,
        currency: 'EGP',
        createdAt: new Date(),
      });

      prisma.payment.create.mockResolvedValue({
        id: 'pay-1',
        provider: 'paymob',
        amount: 31.50,
        status: 'pending',
        metadata: { iframeUrl: 'https://paymob.iframe.url' },
      });

      const result = await service.placeOrder(
        {
          offerId: 'offer-1',
          quantity: 2,
          payment: { provider: 'paymob', paymentMethodId: 'pm_test' },
        },
        'user-1',
      );

      expect(result).toBeDefined();
      expect(result.order.status).toBe('pending');
      expect(result.payment.status).toBe('pending');
      expect(result.payment.iframeUrl).toBe('https://paymob.iframe.url');
      expect(orderTimeoutQueue.add).toHaveBeenCalledWith(
        'confirm-timeout',
        { orderId: 'order-1' },
        { delay: 600000 },
      );
    });

    it('should throw ConflictException if duplicate active order exists', async () => {
      prisma.order.findFirst.mockResolvedValue({ id: 'existing-order' });

      await expect(
        service.placeOrder(
          {
            offerId: 'offer-1',
            quantity: 2,
            payment: { provider: 'stripe', paymentMethodId: 'pm_test' },
          },
          'user-1',
        ),
      ).rejects.toThrow(ConflictException);
    });

    it('should throw when offer expired', async () => {
      prisma.offer.findUnique.mockResolvedValue({
        ...mockOffer,
        status: 'expired',
      });

      await expect(
        service.placeOrder(
          {
            offerId: 'offer-1',
            quantity: 2,
            payment: { provider: 'stripe', paymentMethodId: 'pm_test' },
          },
          'user-1',
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw when stock insufficient in Redis', async () => {
      redis.decrementStock.mockResolvedValue({ code: -1, remaining: 1 });

      await expect(
        service.placeOrder(
          {
            offerId: 'offer-1',
            quantity: 5,
            payment: { provider: 'stripe', paymentMethodId: 'pm_test' },
          },
          'user-1',
        ),
      ).rejects.toThrow(ConflictException);
    });

    it('should throw when exceeding max per customer', async () => {
      await expect(
        service.placeOrder(
          {
            offerId: 'offer-1',
            quantity: 10,
            payment: { provider: 'stripe', paymentMethodId: 'pm_test' },
          },
          'user-1',
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('should restore Redis stock on PG failure', async () => {
      prisma.$transaction.mockRejectedValue(new Error('DB error'));

      await expect(
        service.placeOrder(
          {
            offerId: 'offer-1',
            quantity: 2,
            payment: { provider: 'stripe', paymentMethodId: 'pm_test' },
          },
          'user-1',
        ),
      ).rejects.toThrow('DB error');

      expect(redis.initStock).toHaveBeenCalledWith('offer-1', 50);
    });
  });
});

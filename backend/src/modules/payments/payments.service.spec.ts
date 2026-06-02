import { Test, TestingModule } from '@nestjs/testing';
import { PaymentsService } from './payments.service';
import { StripeProvider } from './providers/stripe.provider';
import { PaymobProvider } from './providers/paymob.provider';
import { PrismaService } from '../../database/prisma.service';
import { RedisService } from '../../redis/redis.service';
import { OffersGateway } from '../offers/offers.gateway';
import { NotificationsService } from '../notifications/notifications.service';

describe('PaymentsService', () => {
  let service: PaymentsService;
  let prismaMock: any;
  const stripeMock = { charge: jest.fn() };
  const paymobMock = { charge: jest.fn(), verifyWebhook: jest.fn() };
  const redisMock = { getStock: jest.fn(), initStock: jest.fn() };
  const offersGatewayMock = { broadcastOrderStatus: jest.fn() };
  const notificationsMock = { onOrderConfirmed: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();
    prismaMock = {
      order: { findUnique: jest.fn(), update: jest.fn() },
      payment: { update: jest.fn() },
      offer: { update: jest.fn(), findUnique: jest.fn() },
      $transaction: jest.fn((fn: any) => fn(prismaMock)),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PaymentsService,
        { provide: StripeProvider, useValue: stripeMock },
        { provide: PaymobProvider, useValue: paymobMock },
        { provide: PrismaService, useValue: prismaMock },
        { provide: RedisService, useValue: redisMock },
        { provide: OffersGateway, useValue: offersGatewayMock },
        { provide: NotificationsService, useValue: notificationsMock },
      ],
    }).compile();

    service = module.get<PaymentsService>(PaymentsService);
  });

  describe('charge', () => {
    it('should route to StripeProvider for stripe', async () => {
      stripeMock.charge.mockResolvedValue({ provider: 'stripe', status: 'captured', amount: 100 });

      const result = await service.charge({ provider: 'stripe', paymentMethodId: 'pm_test' }, { id: 'order-1', totalAmount: 100 });

      expect(stripeMock.charge).toHaveBeenCalled();
      expect(result.provider).toBe('stripe');
    });

    it('should route to PaymobProvider for paymob', async () => {
      paymobMock.charge.mockResolvedValue({ provider: 'paymob', status: 'pending', amount: 100 });

      const result = await service.charge({ provider: 'paymob' }, { id: 'order-2', totalAmount: 50 });

      expect(paymobMock.charge).toHaveBeenCalled();
      expect(result.provider).toBe('paymob');
    });

    it('should throw for unsupported provider', async () => {
      await expect(
        service.charge({ provider: 'unknown' }, { id: 'order-1', totalAmount: 100 }),
      ).rejects.toThrow('Unsupported payment provider: unknown');
    });
  });

  describe('verifyPaymobWebhook', () => {
    it('should delegate to PaymobProvider', () => {
      paymobMock.verifyWebhook.mockReturnValue(true);

      const result = service.verifyPaymobWebhook('test-hmac', { some: 'data' });

      expect(paymobMock.verifyWebhook).toHaveBeenCalledWith('test-hmac', { some: 'data' });
      expect(result).toBe(true);
    });
  });

  describe('handlePaymobWebhook', () => {
    it('should confirm order on successful payment', async () => {
      prismaMock.order.findUnique.mockResolvedValue({
        id: 'order-1',
        status: 'pending',
        customerId: 'user-1',
        storeId: 'store-1',
        offerId: 'offer-1',
        quantity: 2,
      });

      await service.handlePaymobWebhook({
        success: true,
        pending: false,
        id: 'tx-123',
        order: { merchant_order_id: 'order-1' },
      });

      expect(prismaMock.$transaction).toHaveBeenCalled();
      expect(offersGatewayMock.broadcastOrderStatus).toHaveBeenCalledWith('order-1', 'user-1', 'confirmed');
      expect(notificationsMock.onOrderConfirmed).toHaveBeenCalledWith('order-1', 'user-1');
    });

    it('should cancel order on failed payment and restore stock', async () => {
      prismaMock.order.findUnique.mockResolvedValue({
        id: 'order-1',
        status: 'pending',
        customerId: 'user-1',
        storeId: 'store-1',
        offerId: 'offer-1',
        quantity: 2,
      });
      redisMock.getStock.mockResolvedValue(48);

      await service.handlePaymobWebhook({
        success: false,
        pending: false,
        id: 'tx-456',
        order: { merchant_order_id: 'order-1' },
      });

      expect(prismaMock.$transaction).toHaveBeenCalled();
      expect(redisMock.initStock).toHaveBeenCalledWith('offer-1', 50);
      expect(offersGatewayMock.broadcastOrderStatus).toHaveBeenCalledWith('order-1', 'user-1', 'cancelled');
    });

    it('should skip if order is not pending', async () => {
      prismaMock.order.findUnique.mockResolvedValue({
        id: 'order-1',
        status: 'confirmed',
      });

      await service.handlePaymobWebhook({
        success: true,
        pending: false,
        id: 'tx-789',
        order: { merchant_order_id: 'order-1' },
      });

      expect(prismaMock.$transaction).not.toHaveBeenCalled();
    });
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { OffersService } from './offers.service';
import { PrismaService } from '../../database/prisma.service';

describe('OffersService', () => {
  let service: OffersService;
  const prismaMock = {
    offer: { findUnique: jest.fn() },
    order: { count: jest.fn() },
  } as any;

  const mockOffer = {
    id: 'offer-1',
    title: 'Test Offer',
    description: 'A test offer',
    discountedPrice: 50,
    originalPrice: 100,
    stockRemaining: 20,
    stockInitial: 50,
    endTime: new Date(Date.now() + 3600000),
    maxPerCustomer: 5,
    store: { id: 'store-1', name: 'Test Store', slug: 'test-store', cuisineType: 'bakery', ratingAvg: 4.5, ratingCount: 10 },
    product: { id: 'prod-1', name: 'Croissant', category: 'Pastry' },
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OffersService,
        { provide: PrismaService, useValue: prismaMock },
      ],
    }).compile();

    service = module.get<OffersService>(OffersService);
  });

  describe('getOfferDetail', () => {
    it('should return offer detail with customer purchase count', async () => {
      prismaMock.offer.findUnique.mockResolvedValue(mockOffer);
      prismaMock.order.count.mockResolvedValue(2);

      const result = await service.getOfferDetail('offer-1', 'user-1');

      expect(result.id).toBe('offer-1');
      expect(result.discounted_price).toBe(50);
      expect(result.stock_remaining).toBe(20);
      expect(result.customer_purchased_count).toBe(2);
      expect(result.store.name).toBe('Test Store');
      expect(result.product.name).toBe('Croissant');
    });

    it('should return zero purchase count for guest users', async () => {
      prismaMock.offer.findUnique.mockResolvedValue(mockOffer);

      const result = await service.getOfferDetail('offer-1', null);

      expect(result.customer_purchased_count).toBe(0);
      expect(prismaMock.order.count).not.toHaveBeenCalled();
    });

    it('should throw NotFoundException for missing offer', async () => {
      prismaMock.offer.findUnique.mockResolvedValue(null);

      await expect(service.getOfferDetail('bad-id', null))
        .rejects.toThrow(NotFoundException);
    });
  });
});

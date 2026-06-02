import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { CreateCouponDto, ApplyCouponDto } from './dto/create-coupon.dto';

@Injectable()
export class CouponsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(storeId: string, dto: CreateCouponDto) {
    const existing = await this.prisma.coupon.findUnique({ where: { code: dto.code } });
    if (existing) throw new BadRequestException('Coupon code already exists');

    return this.prisma.coupon.create({
      data: {
        storeId,
        code: dto.code.toUpperCase(),
        discountType: dto.discountType,
        discountValue: dto.discountValue,
        minOrderAmount: dto.minOrderAmount,
        maxDiscount: dto.maxDiscount,
        maxUses: dto.maxUses ?? 100,
        expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : null,
        description: dto.description,
      },
    });
  }

  async findByStore(storeId: string) {
    return this.prisma.coupon.findMany({
      where: { storeId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async validateAndApply(storeId: string, dto: ApplyCouponDto) {
    const coupon = await this.prisma.coupon.findUnique({ where: { code: dto.code } });
    if (!coupon) throw new NotFoundException('Coupon not found');
    if (coupon.storeId !== storeId) throw new BadRequestException('Coupon does not apply to this store');
    if (!coupon.isActive) throw new BadRequestException('Coupon is inactive');
    if (coupon.currentUses >= coupon.maxUses) throw new BadRequestException('Coupon has reached max uses');
    if (coupon.expiresAt && new Date() > coupon.expiresAt) throw new BadRequestException('Coupon has expired');
    if (coupon.startsAt && new Date() < coupon.startsAt) throw new BadRequestException('Coupon not yet valid');
    if (coupon.minOrderAmount && dto.orderTotal < Number(coupon.minOrderAmount)) {
      throw new BadRequestException(`Minimum order amount of ${coupon.minOrderAmount} required`);
    }

    let discount = coupon.discountType === 'percentage'
      ? dto.orderTotal * (Number(coupon.discountValue) / 100)
      : Number(coupon.discountValue);

    if (coupon.maxDiscount && discount > Number(coupon.maxDiscount)) {
      discount = Number(coupon.maxDiscount);
    }
    if (discount > dto.orderTotal) discount = dto.orderTotal;

    return {
      valid: true,
      couponId: coupon.id,
      code: coupon.code,
      discountType: coupon.discountType,
      discountValue: Number(coupon.discountValue),
      discount,
      description: coupon.description,
    };
  }

  async useCoupon(couponId: string) {
    await this.prisma.coupon.update({
      where: { id: couponId },
      data: { currentUses: { increment: 1 } },
    });
  }

  async toggleActive(id: string, storeId: string) {
    const coupon = await this.prisma.coupon.findFirst({ where: { id, storeId } });
    if (!coupon) throw new NotFoundException('Coupon not found');
    return this.prisma.coupon.update({
      where: { id },
      data: { isActive: !coupon.isActive },
    });
  }
}

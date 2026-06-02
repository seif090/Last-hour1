import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { CreatePaymentMethodDto, UpdatePaymentMethodDto } from './dto/payment-method.dto';

@Injectable()
export class PaymentMethodsService {
  constructor(private readonly prisma: PrismaService) {}

  async findByUser(userId: string) {
    return this.prisma.savedPaymentMethod.findMany({
      where: { userId },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
    });
  }

  async create(userId: string, dto: CreatePaymentMethodDto) {
    if (dto.isDefault) {
      await this.prisma.savedPaymentMethod.updateMany({
        where: { userId },
        data: { isDefault: false },
      });
    }
    return this.prisma.savedPaymentMethod.create({
      data: { userId, ...dto } as any,
    });
  }

  async update(userId: string, id: string, dto: UpdatePaymentMethodDto) {
    if (dto.isDefault) {
      await this.prisma.savedPaymentMethod.updateMany({
        where: { userId, id: { not: id } },
        data: { isDefault: false },
      });
    }
    return this.prisma.savedPaymentMethod.update({
      where: { id },
      data: dto,
    });
  }

  async remove(userId: string, id: string) {
    return this.prisma.savedPaymentMethod.delete({
      where: { id, userId },
    });
  }
}

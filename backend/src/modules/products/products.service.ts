import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class ProductsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(storeId: string, data: {
    name: string;
    description?: string;
    category: string;
    originalPrice: number;
    unit?: string;
    imageUrls?: string[];
  }) {
    return this.prisma.product.create({
      data: { ...data, storeId },
    });
  }

  async update(productId: string, storeId: string, data: any) {
    const product = await this.prisma.product.findFirst({
      where: { id: productId, storeId },
    });
    if (!product) throw new NotFoundException('Product not found');

    return this.prisma.product.update({
      where: { id: productId },
      data,
    });
  }

  async delete(productId: string, storeId: string) {
    const product = await this.prisma.product.findFirst({
      where: { id: productId, storeId },
    });
    if (!product) throw new NotFoundException('Product not found');

    await this.prisma.product.update({
      where: { id: productId },
      data: { isActive: false },
    });
  }
}

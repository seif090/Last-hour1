import { Injectable, ConflictException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class FavoritesService {
  constructor(private readonly prisma: PrismaService) {}

  async add(userId: string, offerId: string) {
    const offer = await this.prisma.offer.findUnique({ where: { id: offerId }, select: { id: true } });
    if (!offer) throw new NotFoundException('Offer not found');

    try {
      return await this.prisma.favorite.create({
        data: { userId, offerId },
        include: {
          offer: {
            include: {
              store: { select: { id: true, name: true, slug: true } },
            },
          },
        },
      });
    } catch (err: unknown) {
      if (err instanceof Error && err.message.includes('Unique constraint')) {
        throw new ConflictException('Already favorited');
      }
      throw err;
    }
  }

  async remove(userId: string, offerId: string) {
    const fav = await this.prisma.favorite.findUnique({
      where: { userId_offerId: { userId, offerId } },
    });
    if (!fav) throw new NotFoundException('Favorite not found');
    await this.prisma.favorite.delete({ where: { id: fav.id } });
  }

  async list(userId: string) {
    return this.prisma.favorite.findMany({
      where: { userId },
      include: {
        offer: {
          include: {
            store: {
              select: { id: true, name: true, slug: true, ratingAvg: true, ratingCount: true },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async isFavorited(userId: string, offerId: string): Promise<boolean> {
    const fav = await this.prisma.favorite.findUnique({
      where: { userId_offerId: { userId, offerId } },
    });
    return fav !== null;
  }
}

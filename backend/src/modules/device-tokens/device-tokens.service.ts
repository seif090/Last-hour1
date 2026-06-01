import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class DeviceTokensService {
  constructor(private readonly prisma: PrismaService) {}

  async register(userId: string, token: string, platform: string) {
    await this.prisma.deviceToken.upsert({
      where: { userId_token: { userId, token } },
      create: { userId, token, platform, isActive: true },
      update: { isActive: true, platform },
    });
    return { success: true };
  }

  async findByUser(userId: string) {
    return this.prisma.deviceToken.findMany({
      where: { userId, isActive: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getActiveTokens(userIds: string[]): Promise<string[]> {
    if (userIds.length === 0) return [];
    const tokens = await this.prisma.deviceToken.findMany({
      where: { userId: { in: userIds }, isActive: true },
      select: { token: true },
    });
    return tokens.map((t) => t.token);
  }

  async deactivate(userId: string, token: string) {
    await this.prisma.deviceToken.updateMany({
      where: { userId, token },
      data: { isActive: false },
    });
  }
}

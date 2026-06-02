import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { InviteStaffDto, UpdateStaffDto } from './dto/staff.dto';

@Injectable()
export class StaffService {
  constructor(private readonly prisma: PrismaService) {}

  async list(merchantId: string) {
    return this.prisma.staffMember.findMany({
      where: { merchantId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async invite(merchantId: string, dto: InviteStaffDto) {
    const existing = await this.prisma.staffMember.findUnique({
      where: { merchantId_email: { merchantId, email: dto.email } },
    });
    if (existing) {
      if (!existing.isActive) {
        return this.prisma.staffMember.update({
          where: { id: existing.id },
          data: { isActive: true, role: (dto.role as any) ?? existing.role },
        });
      }
      throw new NotFoundException('Staff member already exists');
    }
    return this.prisma.staffMember.create({
      data: {
        merchantId,
        email: dto.email,
        name: dto.name,
        role: (dto.role as any) ?? 'staff',
      },
    });
  }

  async update(merchantId: string, id: string, dto: UpdateStaffDto) {
    const member = await this.prisma.staffMember.findFirst({
      where: { id, merchantId },
    });
    if (!member) throw new NotFoundException('Staff member not found');
    return this.prisma.staffMember.update({
      where: { id },
      data: {
        ...(dto.role ? { role: dto.role as any } : {}),
        ...(dto.name ? { name: dto.name } : {}),
        ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
      },
    });
  }

  async remove(merchantId: string, id: string) {
    const member = await this.prisma.staffMember.findFirst({
      where: { id, merchantId },
    });
    if (!member) throw new NotFoundException('Staff member not found');
    return this.prisma.staffMember.delete({ where: { id } });
  }
}

import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
  ) {}

  async register(email: string, password: string, role: string = 'customer', referralCode?: string) {
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) throw new ConflictException('Email already registered');

    const passwordHash = await bcrypt.hash(password, 12);

    // Generate unique referral code
    const genCode = () => {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      let code = 'LH-';
      for (let i = 0; i < 6; i++) code += chars[Math.floor(Math.random() * chars.length)];
      return code;
    };

    let referralCodeFinal: string | undefined;
    let referredById: string | undefined;

    if (referralCode) {
      const referrer = await this.prisma.user.findUnique({ where: { referralCode } });
      if (referrer) {
        referredById = referrer.id;
      }
    }

    // Try up to 5 times to generate a unique referral code
    for (let attempt = 0; attempt < 5; attempt++) {
      const candidate = genCode();
      const existingCode = await this.prisma.user.findUnique({ where: { referralCode: candidate } });
      if (!existingCode) {
        referralCodeFinal = candidate;
        break;
      }
    }

    const user = await this.prisma.user.create({
      data: {
        email,
        passwordHash,
        role: role as UserRole,
        referralCode: referralCodeFinal,
        referredById,
      },
    });

    // If referred, create a pending referral record
    if (referredById) {
      await this.prisma.referral.create({
        data: {
          referrerId: referredById,
          refereeId: user.id,
          status: 'pending',
        },
      });
    }

    return this.generateTokens(user.id, user.email, user.role);
  }

  async login(email: string, password: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) throw new UnauthorizedException('Invalid credentials');

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) throw new UnauthorizedException('Invalid credentials');

    return this.generateTokens(user.id, user.email, user.role);
  }

  private generateTokens(userId: string, email: string, role: string) {
    const payload = { sub: userId, email, role };

    const accessToken = this.jwtService.sign(payload);
    const refreshToken = this.jwtService.sign(payload, {
      expiresIn: this.config.get('JWT_REFRESH_EXPIRES_IN', '7d'),
    });

    return {
      accessToken,
      refreshToken,
      expiresIn: 900, // 15m in seconds
      user: { id: userId, email, role },
    };
  }
}

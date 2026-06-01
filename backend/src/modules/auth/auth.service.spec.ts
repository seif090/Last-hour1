import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
import { AuthService } from './auth.service';
import { PrismaService } from '../../database/prisma.service';

describe('AuthService', () => {
  let service: AuthService;
  const prismaMock = {
    user: { findUnique: jest.fn(), create: jest.fn() },
  } as any;

  const mockUser = {
    id: 'user-1',
    email: 'test@example.com',
    passwordHash: bcrypt.hashSync('StrongPass123!', 4),
    role: 'customer',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: JwtService, useValue: { sign: jest.fn().mockReturnValue('mock-token') } },
        { provide: ConfigService, useValue: { get: jest.fn().mockReturnValue('7d') } },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  describe('register', () => {
    it('should create a user and return tokens', async () => {
      prismaMock.user.findUnique.mockResolvedValue(null);
      prismaMock.user.create.mockResolvedValue(mockUser);

      const result = await service.register('test@example.com', 'StrongPass123!');

      expect(result.accessToken).toBe('mock-token');
      expect(result.refreshToken).toBe('mock-token');
      expect(result.user.email).toBe('test@example.com');
      expect(result.user.role).toBe('customer');
    });

    it('should throw ConflictException if email exists', async () => {
      prismaMock.user.findUnique.mockResolvedValue(mockUser);

      await expect(service.register('test@example.com', 'StrongPass123!'))
        .rejects.toThrow(ConflictException);
    });
  });

  describe('login', () => {
    it('should return tokens for valid credentials', async () => {
      prismaMock.user.findUnique.mockResolvedValue(mockUser);

      const result = await service.login('test@example.com', 'StrongPass123!');

      expect(result.accessToken).toBe('mock-token');
      expect(result.user.email).toBe('test@example.com');
    });

    it('should throw UnauthorizedException for unknown email', async () => {
      prismaMock.user.findUnique.mockResolvedValue(null);

      await expect(service.login('unknown@example.com', 'StrongPass123!'))
        .rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException for wrong password', async () => {
      prismaMock.user.findUnique.mockResolvedValue(mockUser);

      await expect(service.login('test@example.com', 'WrongPass123!'))
        .rejects.toThrow(UnauthorizedException);
    });
  });
});

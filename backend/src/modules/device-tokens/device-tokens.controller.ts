import { Controller, Post, Get, Body, UseGuards } from '@nestjs/common';
import { IsString, IsIn } from 'class-validator';
import { ApiBearerAuth } from '@nestjs/swagger';
import { DeviceTokensService } from './device-tokens.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

class RegisterTokenDto {
  @IsString()
  token: string;

  @IsIn(['ios', 'android', 'web'])
  platform: 'ios' | 'android' | 'web';
}

@Controller('device-tokens')
export class DeviceTokensController {
  constructor(private readonly service: DeviceTokensService) {}

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post()
  async register(@CurrentUser('id') userId: string, @Body() dto: RegisterTokenDto) {
    return this.service.register(userId, dto.token, dto.platform);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('mine')
  async getMyTokens(@CurrentUser('id') userId: string) {
    return this.service.findByUser(userId);
  }
}

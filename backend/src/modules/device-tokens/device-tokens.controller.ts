import { Controller, Post, Get, Body, UseGuards } from '@nestjs/common';
import { ApiBearerAuth } from '@nestjs/swagger';
import { DeviceTokensService } from './device-tokens.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

class RegisterTokenDto {
  token: string;
  platform: 'ios' | 'android' | 'web';
}

@Controller('device-tokens')
export class DeviceTokensController {
  constructor(private readonly service: DeviceTokensService) {}

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post()
  async register(@CurrentUser() user: any, @Body() dto: RegisterTokenDto) {
    return this.service.register(user.id, dto.token, dto.platform);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('mine')
  async getMyTokens(@CurrentUser() user: any) {
    return this.service.findByUser(user.id);
  }
}

import { Module } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { OffersGateway } from './offers.gateway';
import { OffersService } from './offers.service';
import { OffersController } from './offers.controller';
import { WsAuthGuard } from '../auth/guards/ws-auth.guard';

@Module({
  controllers: [OffersController],
  providers: [
    OffersGateway,
    OffersService,
    WsAuthGuard,
    JwtService,
    ConfigService,
  ],
  exports: [OffersGateway, OffersService],
})
export class OffersModule {}

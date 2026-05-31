import { Module } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { OffersGateway } from './offers.gateway';
import { WsAuthGuard } from '../auth/guards/ws-auth.guard';

@Module({
  providers: [
    OffersGateway,
    WsAuthGuard,
    JwtService,
    ConfigService,
  ],
  exports: [OffersGateway],
})
export class OffersModule {}

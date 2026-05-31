import { Module } from '@nestjs/common';
import { OffersGateway } from './offers.gateway';

@Module({
  providers: [OffersGateway],
  exports: [OffersGateway],
})
export class OffersModule {}

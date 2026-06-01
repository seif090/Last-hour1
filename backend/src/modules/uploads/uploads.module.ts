import { Module } from '@nestjs/common';
import { UploadsController } from './uploads.controller';
import { S3Service } from './uploads.service';

@Module({
  controllers: [UploadsController],
  providers: [S3Service],
  exports: [S3Service],
})
export class UploadsModule {}

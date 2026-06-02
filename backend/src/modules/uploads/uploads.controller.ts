import { Controller, Post, Body, UseGuards, Req } from '@nestjs/common';
import { IsString, IsIn, IsOptional } from 'class-validator';
import { ApiBearerAuth } from '@nestjs/swagger';
import { Request } from 'express';
import { S3Service } from './uploads.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

class PresignedUrlDto {
  @IsIn(['offers', 'stores', 'avatars'])
  folder: 'offers' | 'stores' | 'avatars';

  @IsIn(['jpg', 'jpeg', 'png', 'webp'])
  extension: 'jpg' | 'jpeg' | 'png' | 'webp';

  @IsOptional()
  @IsString()
  contentType?: string;
}

@Controller('uploads')
export class UploadsController {
  constructor(private readonly s3: S3Service) {}

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('presigned-url')
  async presignedUrl(@Req() req: Request, @Body() dto: PresignedUrlDto) {
    const userId = req.user!.id;
    const ext = dto.extension === 'jpeg' ? 'jpg' : dto.extension;
    const contentType = dto.contentType || `image/${ext === 'jpg' ? 'jpeg' : ext}`;
    const key = this.s3.buildKey(dto.folder, userId, ext);
    const result = await this.s3.generatePresignedPutUrl(key, contentType);
    return result;
  }
}

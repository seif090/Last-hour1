import { Controller, Post, Body, UseGuards, Req } from '@nestjs/common';
import { ApiBearerAuth } from '@nestjs/swagger';
import { S3Service } from './uploads.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

class PresignedUrlDto {
  folder: 'offers' | 'stores' | 'avatars';
  extension: 'jpg' | 'jpeg' | 'png' | 'webp';
  contentType?: string;
}

@Controller('uploads')
export class UploadsController {
  constructor(private readonly s3: S3Service) {}

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('presigned-url')
  async presignedUrl(@Req() req: any, @Body() dto: PresignedUrlDto) {
    const userId = req.user.id;
    const ext = dto.extension === 'jpeg' ? 'jpg' : dto.extension;
    const contentType = dto.contentType || `image/${ext === 'jpg' ? 'jpeg' : ext}`;
    const key = this.s3.buildKey(dto.folder, userId, ext);
    const result = await this.s3.generatePresignedPutUrl(key, contentType);
    return result;
  }
}

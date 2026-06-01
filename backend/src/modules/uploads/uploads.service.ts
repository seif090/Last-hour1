import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class S3Service {
  private readonly logger = new Logger(S3Service.name);
  private readonly s3: S3Client;
  private readonly bucket: string;

  constructor(config: ConfigService) {
    this.bucket = config.get<string>('AWS_S3_BUCKET')!;
    this.s3 = new S3Client({
      region: config.get<string>('AWS_S3_REGION', 'me-south-1'),
      credentials: {
        accessKeyId: config.get<string>('AWS_ACCESS_KEY_ID')!,
        secretAccessKey: config.get<string>('AWS_SECRET_ACCESS_KEY')!,
      },
    });
  }

  async generatePresignedPutUrl(
    key: string,
    contentType: string,
    expiresIn = 300,
  ): Promise<{ url: string; key: string }> {
    const command = new PutObjectCommand({
      Bucket: this.bucket,
      Key: key,
      ContentType: contentType,
    });

    const url = await getSignedUrl(this.s3, command, { expiresIn });

    return { url, key };
  }

  buildKey(folder: string, userId: string, ext: string): string {
    const timestamp = Date.now();
    return `${folder}/${userId}/${timestamp}.${ext}`;
  }
}

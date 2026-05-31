import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { PrismaService } from '../../database/prisma.service';
import { RedisService } from '../../redis/redis.service';
import { Public } from '../../common/decorators/public.decorator';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  @Public()
  @Get()
  @ApiOperation({ summary: 'Health check — used by ALB target group' })
  async check() {
    const checks = await Promise.allSettled([
      this.prisma.$queryRawUnsafe('SELECT 1 AS ok'),
      this.redis.getStock('health-check'),
    ]);

    const db = checks[0].status === 'fulfilled';
    const cache = checks[1].status === 'fulfilled';

    const healthy = db && cache;

    return {
      status: healthy ? 'healthy' : 'degraded',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      checks: {
        database: db ? 'up' : 'down',
        cache: cache ? 'up' : 'down',
      },
      version: process.env.npm_package_version || '1.0.0',
    };
  }
}

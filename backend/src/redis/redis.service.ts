import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private readonly client: Redis;
  private readonly prefix: string;
  private readonly stockTtl: number;
  private readonly offerTtl: number;

  private readonly DECREMENT_SCRIPT = `
    local current = redis.call('GET', KEYS[1])
    if not current then return {-2, 0} end
    current = tonumber(current)
    if current < tonumber(ARGV[1]) then return {-1, current} end
    local remaining = redis.call('DECRBY', KEYS[1], ARGV[1])
    return {0, remaining}
  `;

  private decrementSha: string;

  constructor(private config: ConfigService) {
    this.prefix = config.get('REDIS_PREFIX', 'lasthour:');
    this.stockTtl = config.get('REDIS_STOCK_TTL', 30);
    this.offerTtl = config.get('REDIS_OFFER_TTL', 60);

    this.client = new Redis(config.get('REDIS_URL'), {
      retryStrategy: (times) => Math.min(times * 50, 2000),
      enableReadyCheck: true,
      lazyConnect: false,
    });

    this.client.on('connect', () => this.logger.log('Connected to Redis'));
    this.client.on('error', (err) => this.logger.error('Redis error', err));

    this.loadScripts();
  }

  private async loadScripts(): Promise<void> {
    try {
      this.decrementSha = await this.client.script('LOAD', this.DECREMENT_SCRIPT);
    } catch (err) {
      this.logger.error('Failed to load Lua scripts', err);
    }
  }

  onModuleDestroy(): void {
    this.client.disconnect();
  }

  // ─── Stock Cache ─────────────────────────────────────────────

  private stockKey(offerId: string): string {
    return `${this.prefix}stock:${offerId}`;
  }

  private metaKey(offerId: string): string {
    return `${this.prefix}meta:${offerId}`;
  }

  async initStock(offerId: string, quantity: number): Promise<void> {
    await this.client.set(this.stockKey(offerId), quantity, 'EX', this.stockTtl);
  }

  async getStock(offerId: string): Promise<number | null> {
    const val = await this.client.get(this.stockKey(offerId));
    return val ? parseInt(val, 10) : null;
  }

  async decrementStock(
    offerId: string,
    quantity: number,
    nowEpoch: number,
  ): Promise<{ code: number; remaining: number }> {
    const key = this.stockKey(offerId);
    const metaKey = this.metaKey(offerId);

    try {
      const result = await this.client.evalsha(
        this.decrementSha,
        2,
        key,
        metaKey,
        quantity.toString(),
        offerId,
        nowEpoch.toString(),
      );

      if (Array.isArray(result) && result.length === 2) {
        return { code: Number(result[0]), remaining: Number(result[1]) };
      }
      return { code: -2, remaining: 0 };
    } catch {
      // Fallback to inline EVAL if SHA not cached
      try {
        const result = await this.client.eval(
          this.DECREMENT_SCRIPT,
          2,
          key,
          metaKey,
          quantity.toString(),
          offerId,
          nowEpoch.toString(),
        );
        if (Array.isArray(result) && result.length === 2) {
          return { code: Number(result[0]), remaining: Number(result[1]) };
        }
      } catch (err) {
        this.logger.error('Redis decrement failed, falling back to PG', err);
        return { code: -2, remaining: 0 };
      }
      return { code: -2, remaining: 0 };
    }
  }

  async setOfferMeta(
    offerId: string,
    meta: { status: string; endTimeEpoch: number; maxPerCustomer: number },
  ): Promise<void> {
    await this.client.hset(this.metaKey(offerId), {
      status: meta.status,
      end_time: meta.endTimeEpoch,
      max_per_customer: meta.maxPerCustomer,
    });
    await this.client.expire(this.metaKey(offerId), this.offerTtl);
  }

  async invalidateStock(offerId: string): Promise<void> {
    await this.client.del(this.stockKey(offerId), this.metaKey(offerId));
  }

  // ─── Offer Cache ─────────────────────────────────────────────

  async getCachedOffer(offerId: string): Promise<string | null> {
    return this.client.get(`${this.prefix}offer:${offerId}`);
  }

  async cacheOffer(offerId: string, data: string, ttl = 60): Promise<void> {
    await this.client.setex(`${this.prefix}offer:${offerId}`, ttl, data);
  }

  async invalidateOffer(offerId: string): Promise<void> {
    await this.client.del(`${this.prefix}offer:${offerId}`);
  }

  // ─── Session / Rate Limit ────────────────────────────────────

  async getClient(): Promise<Redis> {
    return this.client;
  }
}

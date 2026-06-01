import { registerAs } from '@nestjs/config';

export default registerAs('redis', () => ({
  url: process.env.REDIS_URL!,
  prefix: process.env.REDIS_PREFIX || 'lasthour:',
  stockTtl: parseInt(process.env.REDIS_STOCK_TTL || '30', 10),
  offerTtl: parseInt(process.env.REDIS_OFFER_TTL || '60', 10),
}));

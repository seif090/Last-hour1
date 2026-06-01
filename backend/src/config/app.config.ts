import { registerAs } from '@nestjs/config';

export default registerAs('app', () => ({
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  apiPrefix: process.env.API_PREFIX || '/api/v1',
  corsOrigins: process.env.CORS_ORIGINS?.split(',') || ['http://localhost:3000'],
  wsPath: process.env.WS_PATH || '/ws',
  wsPingInterval: parseInt(process.env.WS_PING_INTERVAL || '30000', 10),
  wsPingTimeout: parseInt(process.env.WS_PING_TIMEOUT || '10000', 10),
  throttleTtl: parseInt(process.env.THROTTLE_TTL || '60', 10),
  throttleLimit: parseInt(process.env.THROTTLE_LIMIT || '100', 10),
}));

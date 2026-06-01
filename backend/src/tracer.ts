import { Logger } from '@nestjs/common';

if (process.env.DD_TRACE_ENABLED === 'true') {
  try {
    require('dd-trace').init({
      service: process.env.DD_SERVICE || 'lasthour-backend',
      env: process.env.DD_ENV || process.env.NODE_ENV || 'development',
      logInjection: process.env.DD_LOGS_INJECTION === 'true',
      runtimeMetrics: true,
      profiling: true,
    });
    new Logger('Bootstrap').log('Datadog APM initialized');
  } catch (err: any) {
    new Logger('Bootstrap').warn(`Datadog init failed: ${err.message}`);
  }
}

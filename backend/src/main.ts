import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger, ShutdownSignal } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const logger = new Logger('Bootstrap');

  const app = await NestFactory.create(AppModule, {
    bufferLogs: true,
    cors: {
      origin: process.env.CORS_ORIGINS?.split(',') ?? '*',
      credentials: true,
    },
  });

  const configService = app.get(ConfigService);

  app.setGlobalPrefix(configService.get('API_PREFIX', '/api/v1'));

  app.use(helmet());

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  const swaggerConfig = new DocumentBuilder()
    .setTitle('Last Hour API')
    .setDescription('Real-time flash sale marketplace for surplus food')
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('docs', app, document);

  // Graceful shutdown signals
  app.enableShutdownHooks([ShutdownSignal.SIGTERM, ShutdownSignal.SIGINT]);

  const port = configService.get('PORT', 3000);
  await app.listen(port);

  logger.log(`Last Hour API running on port ${port}`);
  logger.log(`Swagger docs at http://localhost:${port}/docs`);
  logger.log(`Environment: ${configService.get('NODE_ENV', 'development')}`);
}

bootstrap();

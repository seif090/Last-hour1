import { PostgreSqlContainer, StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import { GenericContainer, StartedTestContainer } from 'testcontainers';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { AppModule } from '../../src/app.module';
import { execSync } from 'child_process';
import * as path from 'path';

let postgresContainer: StartedPostgreSqlContainer;
let redisContainer: StartedTestContainer;
let app: INestApplication;

export async function setupE2eTestApp(): Promise<INestApplication> {
  process.env.NODE_ENV = 'test';
  process.env.THROTTLE_LIMIT = '1000';
  process.env.JWT_SECRET = 'test-secret-32-characters-long-for-testing';
  process.env.BCRYPT_SALT_ROUNDS = '4';

  postgresContainer = await new PostgreSqlContainer('postgis/postgis:16-3.4')
    .withDatabase('lasthour_test')
    .withUsername('lasthour')
    .withPassword('lasthour_test')
    .start();

  const pgUri = postgresContainer
    .getConnectionUri()
    .replace('postgres://', 'postgresql://');
  process.env.DATABASE_URL = pgUri;

  redisContainer = await new GenericContainer('redis:7-alpine')
    .withExposedPorts(6379)
    .start();

  process.env.REDIS_URL = `redis://${redisContainer.getHost()}:${redisContainer.getMappedPort(6379)}`;

  execSync('npx prisma db push --force-reset --accept-data-loss', {
    env: { ...process.env, DATABASE_URL: pgUri },
    cwd: path.resolve(__dirname, '../..'),
    stdio: 'pipe',
  });

  execSync('npx ts-node prisma/seed.ts', {
    env: { ...process.env, DATABASE_URL: pgUri },
    cwd: path.resolve(__dirname, '../..'),
    stdio: 'pipe',
  });

  const moduleFixture: TestingModule = await Test.createTestingModule({
    imports: [AppModule],
  }).compile();

  app = moduleFixture.createNestApplication();
  app.setGlobalPrefix('/api/v1');
  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }),
  );

  await app.init();
  return app;
}

export async function teardownE2eTestApp(): Promise<void> {
  if (app) await app.close();
  if (postgresContainer) await postgresContainer.stop();
  if (redisContainer) await redisContainer.stop();
}

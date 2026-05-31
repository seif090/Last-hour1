# Last Hour 🕐

Real-time, location-based flash-sale marketplace for surplus food from restaurants, bakeries, and supermarkets.

## Quick Start

```bash
# 1. Start infrastructure (PostgreSQL + Redis)
docker compose up -d postgres redis

# 2. Install backend deps
cd backend && npm install

# 3. Generate Prisma client
npx prisma generate

# 4. Run migrations
npx prisma migrate dev

# 5. Start backend in dev mode
npm run start:dev

# 6. Launch full stack
docker compose up -d
```

## Key Documents

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](./ARCHITECTURE.md) | System architecture, data flow, scaling |
| [CONCURRENCY.md](./CONCURRENCY.md) | Flash sale concurrency strategy (Redis + PG) |
| [database/schema.sql](./database/schema.sql) | Full PostgreSQL DDL with PostGIS |
| [prisma/schema.prisma](./prisma/schema.prisma) | Prisma ORM schema |
| [backend/API_SPECIFICATION.md](./backend/API_SPECIFICATION.md) | All REST + WebSocket endpoints |
| [backend/](./backend) | NestJS backend with clean architecture |
| [flutter/](./flutter) | Flutter mobile apps (customer + merchant) |

## Environments

| Environment | URL |
|------------|-----|
| Production | `https://api.lasthour.app` |
| Staging | `https://staging-api.lasthour.app` |
| Local | `http://localhost:3000` |
| Swagger Docs | `http://localhost:3000/docs` |
| Adminer (DB) | `http://localhost:8080` |
| Redis Commander | `http://localhost:8081` |

## Architecture at a Glance

```
Flutter App → ALB → NestJS (ECS Fargate) → PostgreSQL + PostGIS
                   ↕                          ↕
              Redis (Cache + Atomic)     S3 (Images)
                   ↕
              WebSocket (Real-time)
```

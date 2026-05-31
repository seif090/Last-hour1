# Last Hour — Production Architecture Blueprint

## 1. System Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                              │
│  ┌─────────────────────┐   ┌───────────────────────────┐        │
│  │  Customer App       │   │  Merchant App             │        │
│  │  (Flutter + BLoC)   │   │  (Flutter + BLoC)         │        │
│  └────────┬────────────┘   └─────────┬─────────────────┘        │
│           │                          │                          │
└───────────┼──────────────────────────┼──────────────────────────┘
            │        HTTPS/WSS         │
┌───────────┼──────────────────────────┼──────────────────────────┐
│           ▼                          ▼                          │
│  ┌─────────────────────────────────────────────────────┐        │
│  │            API GATEWAY / LOAD BALANCER              │        │
│  │            (AWS ALB → EC2/ECS Fargate)              │        │
│  └────────────────────┬────────────────────────────────┘        │
│                       │                                         │
│  ┌────────────────────┼────────────────────────────────────┐    │
│  │                    ▼                                    │    │
│  │  ┌─────────────────────────────────────────────┐       │    │
│  │  │         NESTJS BACKEND (TypeScript)         │       │    │
│  │  │  ┌──────────┬──────────┬─────────────────┐  │       │    │
│  │  │  │ REST API │WebSocket │ Background Jobs │  │       │    │
│  │  │  │ (Express)│ (SocketIO)│ (Bull/Redis)   │  │       │    │
│  │  │  └──────────┴──────────┴─────────────────┘  │       │    │
│  │  └──────────────────┬──────────────────────────┘       │    │
│  │                     │                                  │    │
│  └─────────────────────┼──────────────────────────────────┘    │
│                        │                                       │
│           ┌────────────┼────────────┬──────────────┐           │
│           ▼            ▼            ▼              ▼           │
│  ┌────────────┐ ┌──────────┐ ┌───────────┐ ┌──────────────┐   │
│  │  PostgreSQL│ │  Redis   │ │    S3     │ │  ElastiCache │   │
│  │  + PostGIS │ │  (Cache) │ │ (Images)  │ │  (Session)   │   │
│  │  (RDS)     │ │          │ │           │ │              │   │
│  └────────────┘ └──────────┘ └───────────┘ └──────────────┘   │
│                        CLOUD LAYER (AWS)                       │
└────────────────────────────────────────────────────────────────┘
```

## 2. Tech Stack Matrix

| Layer        | Technology                     | Justification                                          |
|-------------|--------------------------------|--------------------------------------------------------|
| Mobile       | Flutter 3.x + BLoC             | Single codebase, native perf, real-time capable        |
| Backend      | NestJS 10 + TypeScript 5       | Opinionated, modular, built-in WS support              |
| Database     | PostgreSQL 16 + PostGIS 3.4    | Mature, spatial queries, transactional integrity       |
| Cache        | Redis 7 (ElastiCache)          | Atomic counters, pub/sub, TTL-based invalidation       |
| ORM          | Prisma 5                       | Type-safe, migration tooling, PostGIS support          |
| Auth         | JWT (RS256) + Passport.js      | Stateless, RBAC claims in payload                      |
| Payments     | Stripe Connect + Paymob        | Dual-provider abstraction                              |
| Maps         | Google Maps SDK + API          | Geocoding, autocomplete, distance matrix               |
| Queue        | Bull + Redis                   | Delayed order expiration, notification dispatch        |
| CI/CD        | GitHub Actions                 | Lint, test, build, deploy pipeline                     |
| Infra        | AWS ECS Fargate (containers)   | Auto-scaling, no server management                     |

## 3. Authentication & RBAC

### JWT Payload Structure
```json
{
  "sub": "user_uuid",
  "role": "customer | merchant | admin",
  "merchant_id": "uuid | null",
  "iat": 1700000000,
  "exp": 1700086400
}
```

### Role Matrix

| Endpoint Group               | Customer | Merchant | Admin |
|-----------------------------|:--------:|:--------:|:-----:|
| GET /api/v1/offers/nearby   |    ✅    |    ✅    |   ✅  |
| POST /api/v1/orders         |    ✅    |    ❌    |   ✅  |
| PATCH /api/v1/orders/:id    |    ❌    |    ✅    |   ✅  |
| POST /api/v1/merchant/offers|    ❌    |    ✅    |   ✅  |
| GET /api/v1/admin/*         |    ❌    |    ❌    |   ✅  |

### Auth Flow
```
Client → POST /api/v1/auth/login → { access_token, refresh_token }
Access Token: 15min expiry, signed RS256
Refresh Token: 7 day expiry, stored in Redis whitelist
```

## 4. Real-Time Architecture (WebSocket)

### Socket.IO Namespaces
- `/ws/customer` — Offer feed, order status, stock updates
- `/ws/merchant/{storeId}` — Incoming orders, stock alerts
- `/ws/admin` — Platform-wide metrics

### Event Protocol
```
CLIENT → SERVER:  { event: "subscribe", payload: { channel: "offer:store:uuid" } }
SERVER → CLIENT:  { event: "stock:update", payload: { offer_id, remaining, sold } }
SERVER → CLIENT:  { event: "order:status", payload: { order_id, status, eta } }
```

## 5. Data Flow: Flash Sale Order Placement

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Flutter │    │  NestJS  │    │  Redis   │    │    PG    │    │  Stripe  │
│  Client  │    │  Server  │    │  (Cache) │    │ (Source) │    │ Gateway  │
└────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘
     │                │                │                │                │
     │ POST /orders   │                │                │                │
     │───────────────►│                │                │                │
     │                │ CHECK STOCK    │                │                │
     │                │───────────────►│ DECRBY(qty)   │                │
     │                │◄── {ok: 5} ────│                │                │
     │                │                │                │                │
     │                │ BEGIN TX       │                │                │
     │                │───────────────────────────────►│                │
     │                │ INSERT order   │                │                │
     │                │ INSERT items   │                │                │
     │                │ UPDATE stock   │                │                │
     │                │────────────────────────────────►                │
     │                │◄── COMMIT ─────────────────────│                │
     │                │                │                │                │
     │                │ CHARGE CARD    │                │                │
     │                │───────────────────────────────────────────────►│
     │                │◄── charge.id ──────────────────────────────────│
     │                │                │                │                │
     │  {order, ok}  │                │                │                │
     │◄──────────────│                │                │                │
     │                │                │                │                │
     │ WS: stock:upd  │                │                │                │
     │◄───────────────│                │                │                │
```

## 6. Geo-Location Query Strategy

PostGIS `GEOGRAPHY` type with `ST_DWithin` for radius queries:

```sql
-- Index
CREATE INDEX idx_stores_location ON stores USING GIST (location);

-- Query: find stores with active offers within 5km
SELECT s.id, s.name, s.location,
       ST_Distance(s.location, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography) AS distance_m
FROM stores s
JOIN offers o ON o.store_id = s.id AND o.status = 'active' AND o.end_time > NOW()
WHERE ST_DWithin(
    s.location,
    ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
    5000  -- 5km in meters
)
ORDER BY distance_m;
```

Prisma raw query fallback via `$queryRawUnsafe` or a PostGIS view mapped to a Prisma model.

## 7. Caching & Invalidation Strategy

| Data                    | Cache Key Pattern                | TTL     | Invalidation Trigger              |
|------------------------|----------------------------------|---------|-----------------------------------|
| Active nearby offers   | `offers:nearby:{lat}:{lng}:{r}`  | 60s     | Any offer state change            |
| Single offer detail    | `offer:{id}`                     | 30s     | Stock change, expire              |
| Store profile          | `store:{id}`                     | 300s    | Merchant update                   |
| User session           | `session:{userId}`               | 900s    | Logout, token refresh             |
| Payment intent         | `payment:{orderId}`              | 3600s   | Charge completes                  |

## 8. Scaling Targets

| Metric              | Target            | Strategy                                    |
|--------------------|-------------------|---------------------------------------------|
| Concurrent users   | 50,000            | ALB → ECS auto-scale, Redis offload         |
| Orders/sec (peak)  | 500               | Redis atomic DECR, async PG write           |
| Offer queries/sec  | 2,000             | Geo-cached + materialized view              |
| WebSocket conns    | 10,000 (per node) | Socket.IO with Redis adapter, horizontal    |
| P99 latency        | < 500ms           | Redis hot-path, PG read replicas            |

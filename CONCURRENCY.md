# Last Hour — Concurrency & Performance Strategy

## Problem Statement

Flash sales generate extreme contention on stock_remaining. At peak, hundreds of users may attempt to purchase the same offer within seconds. Without proper safeguards, this leads to:

1. **Overselling** — stock goes negative; orders accepted with no inventory
2. **Race conditions** — two concurrent requests both see `stock_remaining = 5` and both succeed
3. **Hot-row contention** — the offers row becomes a database hotspot

---

## Solution Architecture (Three-Layer Defense)

```
┌─────────────────────────────────────────────────────────┐
│                    LAYER 1: REDIS                        │
│                                                         │
│  Fast path: atomic stock check + decrement              │
│  Key:  offer:stock:{offerId}                            │
│  Op:   EVAL "if redis.call('GET',KEYS[1]) >= ARGV[1]   │
│               then return redis.call('DECRBY',...)      │
│               else return -1 end"                       │
│  TTL:  30s (refreshed from PG on cache miss)            │
│  Miss: Load stock_remaining from PG → SET + TTL         │
│                                                         │
│  ┌──────────────────┐                                   │
│  │  Redis Lua Script│  (atomic, single-threaded)        │
│  │  Offer Decrement │                                   │
│  └──────────────────┘                                   │
└───────────────────────────┬─────────────────────────────┘
                            │ hit
                            ▼
┌─────────────────────────────────────────────────────────┐
│              LAYER 2: POSTGRES (PG)                      │
│                                                         │
│  Persistent source of truth. Fallback if Redis is down. │
│  Uses SELECT ... FOR UPDATE row-level locking.          │
│                                                         │
│  fn_atomic_decrement_stock(offer_id, qty)               │
│  ┌─────────────────────────────────────────┐            │
│  │ BEGIN;                                   │            │
│  │ SELECT stock_remaining FROM offers       │            │
│  │   WHERE id = $1 FOR UPDATE;              │ ← lock    │
│  │ CHECK >= quantity                        │            │
│  │ UPDATE offers SET stock_remaining -= qty │            │
│  │   WHERE id = $1;                         │            │
│  │ COMMIT;                                  │            │
│  └─────────────────────────────────────────┘            │
└───────────────────────────┬─────────────────────────────┘
                            │ fallback
                            ▼
┌─────────────────────────────────────────────────────────┐
│         LAYER 3: APPLICATION (Idempotency)              │
│                                                         │
│  Unique partial index on (customer_id, offer_id)        │
│  WHERE status IN ('pending','confirmed','preparing')    │
│                                                         │
│  X-Request-Id header for idempotency:                   │
│  ┌─────────────────────────────────────────┐            │
│  │ IF EXISTS(order with request_id)         │            │
│  │   RETURN existing_order                  │            │
│  │ ELSE                                      │            │
│  │   PROCEED with order creation             │            │
│  └─────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────┘
```

---

## Order Placement Flow (Detailed)

```
┌─────────┐     ┌──────────┐     ┌───────┐     ┌──────────┐
│ CLIENT  │     │  NESTJS  │     │ REDIS │     │ POSTGRES │
└────┬────┘     └────┬─────┘     └───┬───┘     └────┬─────┘
     │               │                │               │
     │ POST /orders  │                │               │
     │ X-Request-Id  │                │               │
     │──────────────►│                │               │
     │               │ CHECK IDEMPOTENCY              │
     │               │───────────────►               │
     │               │◄── no dup ────────────────────►│
     │               │                │               │
     │               │ REDIS DECRBY   │               │
     │               │ (Lua script)   │               │
     │               │───────────────►│               │
     │               │◄── ok, 7 ─────│               │
     │               │                │               │
     │               │ PG fn_atomic_  │               │
     │               │ decrement      │               │
     │               │ (fallback)     │               │
     │               │───────────────►               │
     │               │◄── true, 7 ──────────────────►│
     │               │                │               │
     │               │ BEGIN PG TX    │               │
     │               │───────────────────────────────►│
     │               │ INSERT order   │               │
     │               │ INSERT order_items             │
     │               │ INSERT payment  │               │
     │               │───────────────────────────────►│
     │               │◄── COMMIT ────────────────────►│
     │               │                │               │
     │               │ Sync stock to  │               │
     │               │ Redis (SET)    │               │
     │               │───────────────►│               │
     │               │                │               │
     │               │ WS broadcast   │               │
     │               │ (stock:update) │               │
     │   ◄───────────│────────────────│───────────────│
     │   ◄───────────│────────────────│───────────────│
     │ 201 + order   │                │               │
     │◄──────────────│                │               │
```

---

## Redis Lua Script (Atomic Decrement)

```lua
-- KEYS[1] = offer:stock:{offerId}
-- KEYS[2] = offer:meta:{offerId}
-- ARGV[1] = quantity
-- ARGV[2] = offer_id (for meta validation)

-- First validate the offer is still active via meta hash
local meta = redis.call('HGETALL', KEYS[2])
if #meta == 0 then
    -- Cache miss — mark for PG fallback, return "retry"
    return {-2, 0}
end

local metaTable = {}
for i = 1, #meta, 2 do
    metaTable[meta[i]] = meta[i+1]
end

if metaTable['status'] ~= 'active' then
    return {-3, 0}  -- Offer not active
end

if tonumber(metaTable['end_time']) < tonumber(ARGV[3]) then
    return {-4, 0}  -- Offer expired
end

-- Atomic decrement
local current = redis.call('GET', KEYS[1])
if not current then
    return {-2, 0}  -- Miss, retry from PG
end

current = tonumber(current)
if current < tonumber(ARGV[1]) then
    return {-1, current}  -- Insufficient stock
end

local remaining = redis.call('DECRBY', KEYS[1], ARGV[1])
return {0, remaining}
```

## Application-Level Concurrency

```typescript
// orders.service.ts — simplified flow
async placeOrder(dto: CreateOrderDto, userId: string): Promise<Order> {
  // 1. Idempotency check
  const existing = await this.checkIdempotency(dto.requestId);
  if (existing) return existing;

  // 2. Redis decrement (fast path)
  const [code, remaining] = await this.redisService.decrementStock(
    dto.offerId,
    dto.quantity,
  );

  if (code === -1) throw new InsufficientStockError(remaining);
  if (code < 0) {
    // Redis miss — fall back to PG
    await this.pgAtomicDecrement(dto.offerId, dto.quantity);
  }

  // 3. Create order in transaction
  const order = await this.prisma.$transaction(async (tx) => {
    // Lock and verify stock in PG as well (double-check)
    const offer = await tx.$queryRaw`
      SELECT * FROM fn_atomic_decrement_stock(${dto.offerId}, ${dto.quantity})
    `;

    if (!offer.success) {
      throw new InsufficientStockError(offer.remaining);
    }

    const newOrder = await tx.order.create({
      data: {
        customerId: userId,
        storeId: dto.storeId,
        offerId: dto.offerId,
        quantity: dto.quantity,
        // ...
      },
    });

    // 4. Charge payment
    const payment = await this.paymentService.charge(dto.payment, newOrder);
    await tx.payment.create({ data: payment });

    return newOrder;
  });

  // 5. Broadcast stock update via WebSocket
  this.offersGateway.broadcastStockUpdate(dto.offerId, remaining);

  // 6. Enqueue expiration watcher
  await this.queueService.addOrderTimeout(order.id, order.ttl);

  return order;
}
```

---

## Database-Level Optimizations

### Connection Pooling (PgBouncer)
```
pool: 50 connections (shared)
reservedPool: 10 connections (for admin/queue)
maxClientConn: 200
defaultPoolSize: 25
```

### Critical Indexes (already in schema.sql)
| Index                          | Why                                    |
|--------------------------------|----------------------------------------|
| `idx_offers_active`            | Filter active offers for a store       |
| `idx_orders_customer_offer_unique` | Prevents duplicate concurrent orders |
| `idx_stores_location (GIST)`   | 5km radius search in <10ms             |

### Partitioning (for scale > 10M orders)
```sql
-- Future: partition orders by month
CREATE TABLE orders (...) PARTITION BY RANGE (created_at);
CREATE TABLE orders_2026_05 PARTITION OF orders
  FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
```

---

## Caching Strategy Details

### Hot-Path Cache (Redis)
```
offer:stock:{offerId} → INTEGER       (TTL: 30s, refresh on read)
offer:meta:{offerId}  → HASH          (TTL: 60s, fields: status, end_time, max_per_customer)
offers:nearby:{hash}  → JSON ARRAY    (TTL: 60s, hash = fnv1a(lat|lng|radius))
```

### Cache-Aside Pattern
```
READ:  Check Redis → Hit? Return → Miss? Query PG → SET TTL → Return
WRITE: Write PG → DEL Redis key (lazy invalidation)
```

### Cache Warming
```typescript
// On merchant creates an offer → preload into Redis
await this.redisService.set(`offer:stock:${offer.id}`, offer.stockInitial, 30);
await this.redisService.hset(`offer:meta:${offer.id}`, {
  status: offer.status,
  end_time: offer.endTime.getTime(),
  max_per_customer: offer.maxPerCustomer,
});
```

---

## Performance Benchmarks (Target)

| Operation                     | P50       | P99       | Throughput      |
|------------------------------|-----------|-----------|-----------------|
| Nearby offers query          | 25ms      | 80ms      | 2,000 req/s     |
| Offer detail                 | 8ms       | 30ms      | 5,000 req/s     |
| Order placement (Redis path) | 45ms      | 120ms     | 500 req/s       |
| Order placement (PG path)    | 90ms      | 250ms     | 200 req/s       |
| WebSocket broadcast          | 5ms       | 20ms      | 10,000 msg/s    |
| Stock update broadcast       | 3ms       | 15ms      | 5,000 msg/s     |

---

## Monitoring & Alerting

### Redis Metrics (CloudWatch / Prometheus)
- `redis_stock_hit_ratio` — should be > 0.95
- `redis_stock_miss_rate` — alert if > 100/min
- `redis_decrement_contention` — alert on Lua script retries

### PG Metrics
- `pg_deadlocks` — alert on any
- `pg_row_lock_avg_ms` — alert if > 50ms
- `pg_offers_update_contention` — slow queries on offers table

### Business Metrics
- `orders_per_second` — peak tracking
- `stock_sold_out_seconds` — time from active to sold_out
- `order_failure_rate` — insufficient_stock / total attempts

# Last Hour — Backend (NestJS + TypeScript)

## Folder Structure

```
backend/
├── src/
│   ├── main.ts                          # Bootstrap, Swagger, ValidationPipe
│   ├── app.module.ts                    # Root module
│   ├── common/
│   │   ├── decorators/
│   │   │   ├── current-user.decorator.ts
│   │   │   ├── roles.decorator.ts
│   │   │   └── public.decorator.ts
│   │   ├── guards/
│   │   │   ├── jwt-auth.guard.ts
│   │   │   └── roles.guard.ts
│   │   ├── interceptors/
│   │   │   ├── timeout.interceptor.ts
│   │   │   └── logging.interceptor.ts
│   │   ├── filters/
│   │   │   └── http-exception.filter.ts
│   │   ├── pipes/
│   │   │   └── uuid-validation.pipe.ts
│   │   ├── middleware/
│   │   │   ├── rate-limit.middleware.ts
│   │   │   └── request-id.middleware.ts
│   │   └── types/
│   │       ├── pagination.type.ts
│   │       └── api-response.type.ts
│   │
│   ├── config/
│   │   ├── app.config.ts                # Env-based config (Joi validation)
│   │   ├── database.config.ts
│   │   ├── redis.config.ts
│   │   └── stripe.config.ts
│   │
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── auth.module.ts
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── strategies/
│   │   │   │   ├── jwt.strategy.ts
│   │   │   │   └── jwt-refresh.strategy.ts
│   │   │   ├── dto/
│   │   │   │   ├── login.dto.ts
│   │   │   │   ├── register.dto.ts
│   │   │   │   └── refresh-token.dto.ts
│   │   │   └── auth.guard.ts
│   │   │
│   │   ├── users/
│   │   │   ├── users.module.ts
│   │   │   ├── users.service.ts
│   │   │   └── users.controller.ts
│   │   │
│   │   ├── merchants/
│   │   │   ├── merchants.module.ts
│   │   │   ├── merchants.controller.ts
│   │   │   ├── merchants.service.ts
│   │   │   └── dto/
│   │   │       ├── register-merchant.dto.ts
│   │   │       └── update-store.dto.ts
│   │   │
│   │   ├── stores/
│   │   │   ├── stores.module.ts
│   │   │   ├── stores.controller.ts
│   │   │   ├── stores.service.ts
│   │   │   └── dto/
│   │   │       ├── create-store.dto.ts
│   │   │       └── nearby-query.dto.ts
│   │   │
│   │   ├── products/
│   │   │   ├── products.module.ts
│   │   │   ├── products.controller.ts
│   │   │   ├── products.service.ts
│   │   │   └── dto/
│   │   │       └── create-product.dto.ts
│   │   │
│   │   ├── offers/
│   │   │   ├── offers.module.ts
│   │   │   ├── offers.controller.ts
│   │   │   ├── offers.service.ts
│   │   │   ├── offers.gateway.ts            # WebSocket gateway
│   │   │   └── dto/
│   │   │       ├── create-offer.dto.ts
│   │   │       ├── update-stock.dto.ts
│   │   │       └── nearby-offers-query.dto.ts
│   │   │
│   │   ├── orders/
│   │   │   ├── orders.module.ts
│   │   │   ├── orders.controller.ts
│   │   │   ├── orders.service.ts
│   │   │   ├── orders.gateway.ts
│   │   │   └── dto/
│   │   │       ├── create-order.dto.ts
│   │   │       ├── update-order-status.dto.ts
│   │   │       └── order-response.dto.ts
│   │   │
│   │   ├── payments/
│   │   │   ├── payments.module.ts
│   │   │   ├── payments.service.ts
│   │   │   ├── providers/
│   │   │   │   ├── payment-provider.interface.ts
│   │   │   │   ├── stripe.provider.ts
│   │   │   │   └── paymob.provider.ts
│   │   │   └── dto/
│   │   │       └── create-payment-intent.dto.ts
│   │   │
│   │   ├── reviews/
│   │   │   ├── reviews.module.ts
│   │   │   ├── reviews.controller.ts
│   │   │   ├── reviews.service.ts
│   │   │   └── dto/
│   │   │       └── create-review.dto.ts
│   │   │
│   │   └── notifications/
│   │       ├── notifications.module.ts
│   │       ├── notifications.service.ts
│   │       └── providers/
│   │           ├── push.provider.ts          # Firebase Cloud Messaging
│   │           └── websocket.provider.ts
│   │
│   ├── redis/
│   │   ├── redis.module.ts
│   │   ├── redis.service.ts
│   │   └── redis.health.ts
│   │
│   ├── queue/
│   │   ├── queue.module.ts                  # Bull module
│   │   └── jobs/
│   │       ├── offer-expiration.processor.ts
│   │       ├── order-timeout.processor.ts
│   │       └── notification-dispatch.processor.ts
│   │
│   └── database/
│       ├── database.module.ts
│       ├── prisma.service.ts
│       └── migrations/
│
├── test/
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
├── .env.example
├── .eslintrc.js
├── .prettierrc
├── nest-cli.json
├── tsconfig.json
├── tsconfig.build.json
└── package.json
```

## Key Architectural Decisions

### Layered Architecture
```
Controller (DTO validation) → Service (Business logic) → Repository (Prisma)
                                            ↕
                                      Redis Cache
                                            ↕
                                      WebSocket Gateway
```

### Dependency Injection
- `PrismaService` — Singleton, injected across all services
- `RedisService` — Singleton, injected into cache-heavy services
- `OffersGateway` — Injected into `OrdersService` to broadcast stock updates

### Module Dependencies
```
AppModule
├── AuthModule          (JWT, Passport)
├── UsersModule         (CRUD)
├── MerchantsModule     (CRUD)
├── StoresModule        (Geo queries, CRUD)
├── ProductsModule      (CRUD)
├── OffersModule        (Flash sale logic, WebSocket)
├── OrdersModule        (Order placement, concurrency)
├── PaymentsModule      (Stripe/Paymob abstraction)
├── ReviewsModule       (CRUD)
├── NotificationsModule (FCM, WS)
├── RedisModule         (Cache, atomic ops)
├── QueueModule         (Bull, background jobs)
└── DatabaseModule      (Prisma)
```

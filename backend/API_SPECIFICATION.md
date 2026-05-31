# Last Hour — REST API Specification v1

Base URL: `https://api.lasthour.app/api/v1`

## Authentication

All protected endpoints require:
```
Authorization: Bearer <access_token>
X-Request-Id: <uuid>        (idempotency key for POST/PATCH)
```

---

## 1. Customer Endpoints

### 1.1 Browse Nearby Offers

```
GET /offers/nearby?lat=30.0444&lng=31.2357&radius=5000&category=bakery&page=1&limit=20
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "offers": [
      {
        "id": "uuid",
        "title": "Fresh Croissant Pack",
        "discounted_price": 15.00,
        "original_price": 35.00,
        "discount_percent": 57,
        "stock_remaining": 12,
        "stock_initial": 50,
        "end_time": "2026-05-31T22:00:00Z",
        "expires_in_seconds": 3600,
        "max_per_customer": 5,
        "image_url": "https://cdn.lasthour.app/offers/abc.jpg",
        "store": {
          "id": "uuid",
          "name": "Bread Factory",
          "slug": "bread-factory",
          "cuisine_type": "bakery",
          "rating_avg": 4.5,
          "rating_count": 128,
          "distance_m": 420
        },
        "product": {
          "id": "uuid",
          "name": "Fresh Croissant Pack",
          "category": "bakery"
        }
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 87,
      "has_more": true
    }
  }
}
```

### 1.2 Get Offer Detail

```
GET /offers/:offerId
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "title": "Fresh Croissant Pack",
    "description": "6 freshly baked croissants, 50% off",
    "discounted_price": 15.00,
    "original_price": 35.00,
    "stock_remaining": 12,
    "stock_initial": 50,
    "end_time": "2026-05-31T22:00:00Z",
    "max_per_customer": 5,
    "store": { ... },
    "product": { ... },
    "customer_purchased_count": 0
  }
}
```

### 1.3 Place Order (High Concurrency)

```
POST /orders
```

**Request Body:**
```json
{
  "offer_id": "uuid",
  "quantity": 3,
  "payment": {
    "provider": "stripe",
    "payment_method_id": "pm_xyz",
    "save_for_future": false
  },
  "notes": "Please pack separately"
}
```

**Response 201 (Success):**
```json
{
  "success": true,
  "data": {
    "order": {
      "id": "uuid",
      "order_number": "LH-7A3F2B",
      "status": "confirmed",
      "quantity": 3,
      "unit_price": 15.00,
      "subtotal": 45.00,
      "service_fee": 2.25,
      "total_amount": 47.25,
      "currency": "EGP",
      "estimated_ready_at": "2026-05-31T20:15:00Z",
      "created_at": "2026-05-31T19:45:00Z"
    },
    "payment": {
      "id": "uuid",
      "provider": "stripe",
      "status": "captured",
      "amount": 47.25
    },
    "stock_remaining": 9,
    "message": null
  }
}
```

**Response 409 (Stock Exhausted):**
```json
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_STOCK",
    "message": "Only 2 items remaining, requested 3",
    "stock_remaining": 2
  }
}
```

**Response 429 (Concurrent — Duplicate Order):**
```json
{
  "success": false,
  "error": {
    "code": "DUPLICATE_ORDER",
    "message": "You already have an active order for this offer"
  }
}
```

### 1.4 List My Orders

```
GET /orders?status=confirmed&page=1&limit=20
```

### 1.5 Get Order Detail

```
GET /orders/:orderId
```

### 1.6 Track Order (Real-time)

```
GET /orders/:orderId/track
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "order_id": "uuid",
    "order_number": "LH-7A3F2B",
    "status": "preparing",
    "status_history": [
      { "status": "confirmed", "at": "2026-05-31T19:45:00Z" },
      { "status": "preparing", "at": "2026-05-31T19:47:00Z" }
    ],
    "estimated_ready_at": "2026-05-31T20:15:00Z",
    "store": {
      "name": "Bread Factory",
      "lat": 30.0444,
      "lng": 31.2357,
      "address": "15 Tahrir St, Downtown"
    }
  }
}
```

### 1.7 Submit Review

```
POST /reviews
```

```json
{
  "order_id": "uuid",
  "rating": 5,
  "comment": "Amazing fresh croissants!"
}
```

---

## 2. Merchant Endpoints

### 2.1 Create Flash Offer

```
POST /merchant/offers
```

```json
{
  "product_id": "uuid",
  "title": "Fresh Croissant Pack - Last Hour Deal",
  "description": "6 freshly baked croissants",
  "discounted_price": 15.00,
  "original_price": 35.00,
  "stock_initial": 50,
  "max_per_customer": 5,
  "start_time": "2026-05-31T19:00:00Z",
  "end_time": "2026-05-31T22:00:00Z",
  "image_url": "https://cdn.lasthour.app/uploads/offer.jpg",
  "tags": ["bakery", "breakfast", "deal"]
}
```

### 2.2 Update Live Stock

```
PATCH /merchant/offers/:offerId/stock
```

```json
{
  "stock_remaining": 25
}
```

### 2.3 List Merchant Offers

```
GET /merchant/offers?status=active&page=1&limit=20
```

### 2.4 Today's Sales Report

```
GET /merchant/sales/today
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "date": "2026-05-31",
    "total_orders": 42,
    "total_revenue": 840.00,
    "total_fees": 42.00,
    "net_revenue": 798.00,
    "items_sold": 156,
    "offers_active": 3,
    "offers_sold_out": 2,
    "orders_by_hour": [
      { "hour": 19, "count": 12 },
      { "hour": 20, "count": 22 },
      { "hour": 21, "count": 8 }
    ]
  }
}
```

### 2.5 Update Order Status

```
PATCH /merchant/orders/:orderId/status
```

```json
{
  "status": "ready"
}
```

---

## 3. Admin Endpoints

```
GET    /admin/merchants                    # List all merchants
PATCH  /admin/merchants/:id/verify         # Verify merchant
GET    /admin/offers                       # All offers (cross-platform)
GET    /admin/stats                        # Platform-wide metrics
```

---

## 4. WebSocket Events

### Connection
```
wss://api.lasthour.app/ws?token=<jwt_token>
```

### Client → Server

| Event           | Payload                                    | Description              |
|-----------------|--------------------------------------------|--------------------------|
| `subscribe`     | `{ channel: "offer:store:{storeId}" }`     | Watch store's offers     |
| `subscribe`     | `{ channel: "order:{orderId}" }`           | Track specific order     |
| `unsubscribe`   | `{ channel: "offer:store:{storeId}" }`     | Unwatch                  |
| `ping`          | `{}`                                       | Keepalive                |

### Server → Client

| Event            | Payload                                                   | Description              |
|------------------|-----------------------------------------------------------|--------------------------|
| `stock:update`   | `{ offer_id, stock_remaining, sold_count }`               | Flash sale stock change  |
| `offer:expired`  | `{ offer_id }`                                            | Offer ended              |
| `order:status`   | `{ order_id, status, estimated_ready_at }`                | Order status transition  |
| `offer:created`  | `{ offer: { ...full offer object } }`                     | New offer near you       |
| `offer:sold_out` | `{ offer_id }`                                            | Offer fully sold          |
| `pong`           | `{}`                                                      | Keepalive response       |

## 5. Rate Limiting

| Endpoint Group     | Limit                    |
|--------------------|-------------------------|
| Auth (login/register) | 10 req/min per IP      |
| Offer browsing      | 100 req/min per user    |
| Order placement     | 30 req/min per user     |
| Merchant operations | 60 req/min per user     |
| WebSocket messages  | 120 msg/min per conn    |

Headers returned: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

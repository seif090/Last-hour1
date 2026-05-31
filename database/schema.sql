-- ================================================================
-- LAST HOUR — Production PostgreSQL Schema + PostGIS
-- ================================================================
-- Requirements: PostgreSQL 16 + PostGIS 3.4
-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- ================================================================
-- ENUMS
-- ================================================================
CREATE TYPE user_role AS ENUM ('customer', 'merchant', 'admin');
CREATE TYPE offer_status AS ENUM ('draft', 'active', 'paused', 'sold_out', 'expired', 'cancelled');
CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'cancelled', 'refunded');
CREATE TYPE payment_provider AS ENUM ('stripe', 'paymob');
CREATE TYPE payment_status AS ENUM ('pending', 'authorized', 'captured', 'failed', 'refunded');
CREATE TYPE business_type AS ENUM ('restaurant', 'bakery', 'supermarket', 'cafe', 'other');

-- ================================================================
-- USERS (unified auth principal)
-- ================================================================
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email           VARCHAR(255) NOT NULL UNIQUE,
    phone           VARCHAR(20),
    password_hash   VARCHAR(255) NOT NULL,
    role            user_role NOT NULL DEFAULT 'customer',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    avatar_url      VARCHAR(512),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_role ON users (role);

-- ================================================================
-- MERCHANTS
-- ================================================================
CREATE TABLE merchants (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    business_name   VARCHAR(255) NOT NULL,
    business_type   business_type NOT NULL,
    description     TEXT,
    tax_id          VARCHAR(50),
    is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
    commission_rate DECIMAL(5,4) NOT NULL DEFAULT 0.1500, -- 15%
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_merchant_user UNIQUE (user_id)
);

CREATE INDEX idx_merchants_verified ON merchants (is_verified) WHERE is_verified = TRUE;

-- ================================================================
-- STORES (with PostGIS geography point)
-- ================================================================
CREATE TABLE stores (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id     UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    name            VARCHAR(255) NOT NULL,
    slug            VARCHAR(255) NOT NULL UNIQUE,
    description     TEXT,
    location        GEOGRAPHY(Point, 4326) NOT NULL,  -- PostGIS spatial
    address_line1   VARCHAR(255) NOT NULL,
    address_line2   VARCHAR(255),
    city            VARCHAR(100) NOT NULL,
    district        VARCHAR(100),
    postal_code     VARCHAR(20),
    country         VARCHAR(2) NOT NULL DEFAULT 'EG',
    cuisine_type    VARCHAR(100),
    cover_image_url VARCHAR(512),
    logo_url        VARCHAR(512),
    opens_at        TIME,                               -- HH:MM local
    closes_at       TIME,
    timezone        VARCHAR(50) NOT NULL DEFAULT 'Africa/Cairo',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    rating_avg      DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    rating_count    INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Spatial index for radius queries
CREATE INDEX idx_stores_location ON stores USING GIST (location);
-- Partial index for active stores only
CREATE INDEX idx_stores_active ON stores (id) WHERE is_active = TRUE;
-- Index for proximity search filtering
CREATE INDEX idx_stores_city ON stores (city);

-- ================================================================
-- PRODUCTS (menu items / inventory)
-- ================================================================
CREATE TABLE products (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id        UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    name            VARCHAR(255) NOT NULL,
    description     TEXT,
    category        VARCHAR(100) NOT NULL,
    image_urls      TEXT[] DEFAULT '{}',
    original_price  DECIMAL(10,2) NOT NULL CHECK (original_price > 0),
    unit            VARCHAR(20) NOT NULL DEFAULT 'piece',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_products_store ON products (store_id);
CREATE INDEX idx_products_category ON products (store_id, category);

-- ================================================================
-- OFFERS (flash sale instances — time-bound discounts)
-- ================================================================
CREATE TABLE offers (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id        UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    product_id      UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    original_price  DECIMAL(10,2) NOT NULL,
    discounted_price DECIMAL(10,2) NOT NULL CHECK (discounted_price > 0 AND discounted_price < original_price),
    stock_initial   INTEGER NOT NULL CHECK (stock_initial > 0),
    stock_remaining  INTEGER NOT NULL CHECK (stock_remaining >= 0),
    max_per_customer INTEGER NOT NULL DEFAULT 5 CHECK (max_per_customer > 0),
    start_time      TIMESTAMPTZ NOT NULL,
    end_time        TIMESTAMPTZ NOT NULL CHECK (end_time > start_time),
    status          offer_status NOT NULL DEFAULT 'draft',
    image_url       VARCHAR(512),
    tags            TEXT[] DEFAULT '{}',
    version         INTEGER NOT NULL DEFAULT 1,  -- Optimistic locking
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_stock_positive CHECK (stock_remaining >= 0),
    CONSTRAINT ck_stock_not_exceed CHECK (stock_remaining <= stock_initial)
);

-- Core query: active offers ending soon
CREATE INDEX idx_offers_active ON offers (store_id, status, end_time)
    WHERE status = 'active';
-- Fast lookup: offers expiring within window
CREATE INDEX idx_offers_expiring ON offers (end_time)
    WHERE status = 'active';
-- FK index
CREATE INDEX idx_offers_product ON offers (product_id);
-- Composite for merchant dashboard
CREATE INDEX idx_offers_store_status ON offers (store_id, status);

-- Trigger: auto-expire offers when end_time passes (safety net)
CREATE OR REPLACE FUNCTION fn_auto_expire_offers()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE offers SET status = 'expired', updated_at = NOW()
    WHERE status = 'active' AND end_time <= NOW();
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE EVENT TRIGGER trg_auto_expire_offers
    ON ddl_command_end
    WHEN TAG IN ('ALTER TABLE')
    EXECUTE FUNCTION fn_auto_expire_offers();

-- ================================================================
-- ORDERS
-- ================================================================
CREATE TABLE orders (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number    VARCHAR(20) NOT NULL UNIQUE,  -- Human-readable: LH-XXXXXX
    customer_id     UUID NOT NULL REFERENCES users(id),
    store_id        UUID NOT NULL REFERENCES stores(id),
    offer_id        UUID NOT NULL REFERENCES offers(id),
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      DECIMAL(10,2) NOT NULL,
    subtotal        DECIMAL(10,2) NOT NULL,
    service_fee     DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_amount    DECIMAL(10,2) NOT NULL,
    currency        VARCHAR(3) NOT NULL DEFAULT 'EGP',
    status          order_status NOT NULL DEFAULT 'pending',
    notes           TEXT,
    estimated_ready_at TIMESTAMPTZ,
    picked_up_at    TIMESTAMPTZ,
    cancelled_at    TIMESTAMPTZ,
    cancel_reason   TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Critical: optimistic lock + concurrency-safe unique constraint
-- Prevents duplicate orders in the same flash window
CREATE UNIQUE INDEX idx_orders_customer_offer_unique
    ON orders (customer_id, offer_id)
    WHERE status IN ('pending', 'confirmed', 'preparing', 'ready');

CREATE INDEX idx_orders_customer ON orders (customer_id, created_at DESC);
CREATE INDEX idx_orders_store ON orders (store_id, created_at DESC);
CREATE INDEX idx_orders_status ON orders (status);
CREATE INDEX idx_orders_offer ON orders (offer_id);

-- ================================================================
-- ORDER ITEMS (normalized for audit trail)
-- ================================================================
CREATE TABLE order_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id        UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id      UUID NOT NULL REFERENCES products(id),
    product_name    VARCHAR(255) NOT NULL,   -- Snapshot at time of order
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      DECIMAL(10,2) NOT NULL,
    subtotal        DECIMAL(10,2) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_order_items_order ON order_items (order_id);

-- ================================================================
-- PAYMENTS
-- ================================================================
CREATE TABLE payments (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id        UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    provider        payment_provider NOT NULL,
    provider_tx_id  VARCHAR(255),              -- Stripe PaymentIntent ID / Paymob tx
    amount          DECIMAL(10,2) NOT NULL,
    currency        VARCHAR(3) NOT NULL DEFAULT 'EGP',
    status          payment_status NOT NULL DEFAULT 'pending',
    fee             DECIMAL(10,2) DEFAULT 0,
    net_amount      DECIMAL(10,2),
    refunded_amount DECIMAL(10,2) DEFAULT 0,
    metadata        JSONB DEFAULT '{}',
    paid_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_order ON payments (order_id);
CREATE UNIQUE INDEX idx_payments_provider_tx ON payments (provider, provider_tx_id)
    WHERE provider_tx_id IS NOT NULL;

-- ================================================================
-- RATINGS & REVIEWS
-- ================================================================
CREATE TABLE reviews (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id        UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE UNIQUE,
    customer_id     UUID NOT NULL REFERENCES users(id),
    store_id        UUID NOT NULL REFERENCES stores(id),
    rating          SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment         TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reviews_store ON reviews (store_id, rating);
CREATE INDEX idx_reviews_customer ON reviews (customer_id);

-- ================================================================
-- MATERIALIZED VIEW: Active Offers with Store Geo (refresh every 60s)
-- ================================================================
CREATE MATERIALIZED VIEW mv_active_offers AS
SELECT
    o.id AS offer_id,
    o.title,
    o.discounted_price,
    o.original_price,
    o.stock_remaining,
    o.stock_initial,
    o.end_time,
    o.max_per_customer,
    o.image_url,
    o.tags,
    s.id AS store_id,
    s.name AS store_name,
    s.slug AS store_slug,
    s.cuisine_type,
    s.rating_avg,
    s.rating_count,
    s.cover_image_url AS store_cover,
    ST_Y(s.location::geometry) AS lat,
    ST_X(s.location::geometry) AS lng,
    s.city,
    s.district,
    p.id AS product_id,
    p.name AS product_name,
    p.category
FROM offers o
JOIN stores s ON s.id = o.store_id
JOIN products p ON p.id = o.product_id
WHERE o.status = 'active'
  AND o.end_time > NOW()
  AND s.is_active = TRUE;

CREATE UNIQUE INDEX idx_mv_active_offers_id ON mv_active_offers (offer_id);
CREATE INDEX idx_mv_active_offers_category ON mv_active_offers (category);
CREATE INDEX idx_mv_active_offers_city ON mv_active_offers (city);
-- Note: spatial index on materialized view requires PostGIS 3+
CREATE INDEX idx_mv_active_offers_location ON mv_active_offers USING GIST (
    ST_SetSRID(ST_MakePoint(lng, lat), 4326)
);

-- Refresh function (called via pg_cron or application scheduler)
CREATE OR REPLACE FUNCTION fn_refresh_mv_active_offers()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_active_offers;
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- FUNCTION: Atomic stock decrement with optimistic lock
-- Returns 0 if stock insufficient or offer expired, 1 on success
-- ================================================================
CREATE OR REPLACE FUNCTION fn_atomic_decrement_stock(
    p_offer_id      UUID,
    p_quantity      INTEGER
)
RETURNS TABLE(success BOOLEAN, remaining INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_remaining INTEGER;
    v_status            offer_status;
    v_end_time          TIMESTAMPTZ;
BEGIN
    -- Lock row to prevent concurrent decrements
    SELECT stock_remaining, status, end_time
    INTO v_current_remaining, v_status, v_end_time
    FROM offers
    WHERE id = p_offer_id
    FOR UPDATE;

    -- Validate
    IF v_status != 'active' OR v_end_time <= NOW() THEN
        RETURN QUERY SELECT FALSE, v_current_remaining;
        RETURN;
    END IF;

    IF v_current_remaining < p_quantity THEN
        RETURN QUERY SELECT FALSE, v_current_remaining;
        RETURN;
    END IF;

    -- Decrement
    UPDATE offers
    SET stock_remaining = stock_remaining - p_quantity,
        version = version + 1,
        updated_at = NOW(),
        status = CASE WHEN stock_remaining - p_quantity = 0 THEN 'sold_out'::offer_status ELSE status END
    WHERE id = p_offer_id;

    RETURN QUERY SELECT TRUE, v_current_remaining - p_quantity;
END;
$$;

-- ================================================================
-- FUNCTION: Nearby stores with active offers
-- ================================================================
CREATE OR REPLACE FUNCTION fn_nearby_offers(
    p_lat       DOUBLE PRECISION,
    p_lng       DOUBLE PRECISION,
    p_radius_m  DOUBLE PRECISION DEFAULT 5000,
    p_category  VARCHAR DEFAULT NULL,
    p_limit     INTEGER DEFAULT 50
)
RETURNS TABLE(
    offer_id        UUID,
    title           VARCHAR,
    discounted_price DECIMAL,
    store_id        UUID,
    store_name      VARCHAR,
    distance_m      DOUBLE PRECISION,
    lat             DOUBLE PRECISION,
    lng             DOUBLE PRECISION,
    category        VARCHAR,
    stock_remaining INTEGER,
    end_time        TIMESTAMPTZ
)
LANGUAGE SQL STABLE
AS $$
    SELECT
        o.id,
        o.title,
        o.discounted_price,
        s.id,
        s.name,
        ST_Distance(
            s.location,
            ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
        ) AS distance_m,
        ST_Y(s.location::geometry) AS lat,
        ST_X(s.location::geometry) AS lng,
        p.category,
        o.stock_remaining,
        o.end_time
    FROM offers o
    JOIN stores s ON s.id = o.store_id
    JOIN products p ON p.id = o.product_id
    WHERE o.status = 'active'
      AND o.end_time > NOW()
      AND s.is_active = TRUE
      AND ST_DWithin(
            s.location,
            ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
            p_radius_m
          )
      AND (p_category IS NULL OR p.category = p_category)
    ORDER BY distance_m
    LIMIT p_limit;
$$;

-- ================================================================
-- TRIGGER: Auto-update updated_at on row change
-- ================================================================
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_merchants_updated_at BEFORE UPDATE ON merchants
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_stores_updated_at BEFORE UPDATE ON stores
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_offers_updated_at BEFORE UPDATE ON offers
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_payments_updated_at BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ================================================================
-- SEED DATA (development only)
-- ================================================================
-- INSERT INTO users (email, password_hash, role) VALUES
--   ('admin@lasthour.com', crypt('admin123', gen_salt('bf')), 'admin');

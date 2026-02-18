-- ═══════════════════════════════════════════════
-- SAVVIT — Supabase Schema
-- Run this in Supabase SQL Editor
-- ═══════════════════════════════════════════════

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── WATCHLIST ───
-- User's tracked products
CREATE TABLE watchlist (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  query TEXT NOT NULL,
  source_url TEXT,
  target_price INTEGER, -- in INR (paise-free, whole rupees)
  notify_on_drop BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_watchlist_user ON watchlist(user_id);

-- ─── VERDICTS ───
-- AI-generated buy/wait/don't-buy verdicts
CREATE TABLE verdicts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  watchlist_id UUID REFERENCES watchlist(id) ON DELETE CASCADE,
  product_query TEXT NOT NULL,
  verdict TEXT NOT NULL CHECK (verdict IN ('BUY_NOW', 'WAIT', 'DONT_BUY')),
  confidence REAL NOT NULL DEFAULT 0.5,
  short_reason TEXT, -- one-liner for free users
  reason TEXT, -- full explanation
  best_price INTEGER, -- in INR
  best_retailer TEXT,
  all_prices JSONB DEFAULT '[]', -- [{retailer, price, url, offers}]
  pro_analysis JSONB DEFAULT '{}', -- detailed Pro-only analysis
  launch_intel JSONB, -- upcoming product info
  next_sale JSONB, -- next sale event info
  price_history JSONB, -- keepa/historical data
  citations TEXT[] DEFAULT '{}',
  generated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_verdicts_watchlist ON verdicts(watchlist_id);
CREATE INDEX idx_verdicts_generated ON verdicts(generated_at DESC);

-- ─── PRICE HISTORY ───
-- Stored price snapshots (builds our own history over time)
CREATE TABLE price_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_query TEXT NOT NULL,
  retailer TEXT NOT NULL,
  price INTEGER NOT NULL, -- in INR
  currency TEXT DEFAULT 'INR',
  url TEXT,
  offers TEXT,
  in_stock BOOLEAN DEFAULT true,
  checked_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_price_history_query ON price_history(product_query);
CREATE INDEX idx_price_history_checked ON price_history(checked_at DESC);

-- ─── PRODUCTS ───
-- Normalized product catalog (built over time from searches)
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  normalized_name TEXT NOT NULL, -- lowercase, trimmed for dedup
  category TEXT,
  brand TEXT,
  amazon_asin TEXT,
  image_url TEXT,
  first_seen TIMESTAMPTZ DEFAULT now(),
  last_searched TIMESTAMPTZ DEFAULT now()
);

CREATE UNIQUE INDEX idx_products_normalized ON products(normalized_name);
CREATE INDEX idx_products_asin ON products(amazon_asin) WHERE amazon_asin IS NOT NULL;

-- ─── SALE EVENTS ───
-- Upcoming sale events (can be updated dynamically later)
CREATE TABLE sale_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  retailer TEXT NOT NULL,
  start_date DATE,
  end_date DATE,
  avg_discount_pct TEXT,
  categories TEXT[] DEFAULT '{}',
  confirmed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─── ROW LEVEL SECURITY ───
ALTER TABLE watchlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE verdicts ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_events ENABLE ROW LEVEL SECURITY;

-- Watchlist: users can only see their own items
CREATE POLICY "Users see own watchlist"
  ON watchlist FOR SELECT
  USING (user_id = auth.uid()::text);

CREATE POLICY "Users insert own watchlist"
  ON watchlist FOR INSERT
  WITH CHECK (user_id = auth.uid()::text);

CREATE POLICY "Users delete own watchlist"
  ON watchlist FOR DELETE
  USING (user_id = auth.uid()::text);

CREATE POLICY "Users update own watchlist"
  ON watchlist FOR UPDATE
  USING (user_id = auth.uid()::text);

-- Verdicts: accessible via watchlist ownership
CREATE POLICY "Users see own verdicts"
  ON verdicts FOR SELECT
  USING (
    watchlist_id IN (
      SELECT id FROM watchlist WHERE user_id = auth.uid()::text
    )
  );

-- Price history: public read (anonymized market data)
CREATE POLICY "Public read price history"
  ON price_history FOR SELECT
  USING (true);

-- Products: public read
CREATE POLICY "Public read products"
  ON products FOR SELECT
  USING (true);

-- Sale events: public read
CREATE POLICY "Public read sale events"
  ON sale_events FOR SELECT
  USING (true);

-- Service role bypasses RLS for backend operations
-- (Supabase service_role key already bypasses RLS by default)

-- ─── UPDATED_AT TRIGGER ───
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER watchlist_updated_at
  BEFORE UPDATE ON watchlist
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

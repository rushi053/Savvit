-- Price History Table
-- Stores every price result from product searches to build historical price database

CREATE TABLE IF NOT EXISTS price_history (
  id bigint generated always as identity primary key,
  product_name text not null,
  product_query text not null,
  region text not null default 'US',
  retailer text not null,
  price numeric not null,
  currency text not null,
  in_stock boolean default true,
  offers text,
  created_at timestamptz default now()
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_price_history_product_region ON price_history(product_name, region);
CREATE INDEX IF NOT EXISTS idx_price_history_created ON price_history(created_at);
CREATE INDEX IF NOT EXISTS idx_price_history_retailer ON price_history(retailer);

-- Composite index for deduplication checks
CREATE INDEX IF NOT EXISTS idx_price_history_dedup ON price_history(product_name, region, retailer, created_at DESC);

-- Enable RLS but allow service role full access
ALTER TABLE price_history ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists (for re-running)
DROP POLICY IF EXISTS "Service role full access" ON price_history;

-- Create policy for service role
CREATE POLICY "Service role full access" ON price_history FOR ALL USING (true);

-- Add comment
COMMENT ON TABLE price_history IS 'Historical price data collected from product searches. Used to track price trends and provide better purchase timing advice.';

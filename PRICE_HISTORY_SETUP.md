# Price History System - Setup & Overview

## What Was Built

A complete price history collection system that stores every price from product searches into Supabase and serves it back as historical data. This builds Savvit's own price database over time without any external API dependencies.

## Components Created

### 1. Database Migration (`server/migrations/001_price_history.sql`)

**Table: `price_history`**
- Stores every price result from product searches
- Fields: product_name, product_query, region, retailer, price, currency, in_stock, offers, created_at
- Indexes optimized for:
  - Fast product+region lookups
  - Date-based filtering
  - Deduplication checks

**To run:**
1. Go to Supabase SQL Editor: https://supabase.com/dashboard/project/zamecftkxpgkjqtbanmt/sql/new
2. Copy contents of `server/migrations/001_price_history.sql`
3. Paste and click "Run"

### 2. Price History Service (`server/src/services/price-history.ts`)

**`storePrices()`**
- Fire-and-forget async storage (doesn't block API response)
- Deduplicates: won't store same product+retailer+price if stored in last 6 hours
- Normalizes product names for consistent matching
- Logs all operations for debugging

**`getPriceHistory()`**
- Fetches historical prices for a product
- Groups by date (daily aggregation)
- Calculates comprehensive stats:
  - `currentAvg` - Average of all recent prices
  - `thirtyDayAvg` - 30-day average
  - `ninetyDayAvg` - 90-day average
  - `allTimeHigh` - Highest price ever seen
  - `allTimeLow` - Lowest price ever seen
  - `trend` - "rising" | "falling" | "stable" (based on last 7d vs previous 7d)
  - `percentFromLow` - How far current price is from all-time low
  - `percentFromHigh` - How far current price is from all-time high

### 3. Integration into Products Route (`server/src/routes/products.ts`)

**POST `/v1/products/search` now:**
1. Stores prices after every search (fire-and-forget)
2. Fetches historical data from database
3. Includes price history in API response
4. Passes stats to Gemini for smarter verdicts

**API Response includes:**
```json
{
  "priceHistory": {
    "allTimeLow": 99999,
    "allTimeHigh": 129999,
    "avg90d": 115000,
    "avg30d": 112000,
    "trend": "falling",
    "percentFromLow": 10.0,
    "percentFromHigh": -15.4
  }
}
```

### 4. Enhanced Gemini Prompts (`server/src/services/gemini.ts`)

Gemini now receives rich price context:
- "Current average price is ₹110,000. The 90-day average is ₹115,000 (current price is 4.3% below average). All-time low: ₹99,999."
- Highlights if price is at/below all-time low 🔥
- Warns if price is suspiciously high ⚠️

This helps Gemini make much better BUY_NOW vs WAIT decisions.

## How It Works

### First Search (Cold Start)
1. User searches "iPhone 16 Pro"
2. Prices fetched from retailers
3. Prices stored in database (but no history yet)
4. Response: `priceHistory: null`

### Subsequent Searches (Building History)
1. Same product searched again (hours/days/weeks later)
2. New prices stored
3. System calculates trends from accumulated data
4. Response includes full price history stats
5. Gemini gets context: "Price has dropped 8% in the last 30 days"

### Over Time
- More searches = more data points
- Better trend detection
- More accurate "all-time low" tracking
- Smarter buy/wait recommendations

## Configuration

No additional env vars needed — uses existing:
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

Both are already configured in the project via `server/src/utils/auth.ts`.

## Testing

### 1. Run the Migration
Execute `server/migrations/001_price_history.sql` in Supabase SQL Editor.

### 2. Make a Test Search
```bash
curl -X POST http://localhost:3000/v1/products/search \
  -H "Content-Type: application/json" \
  -d '{"query": "iPhone 16 Pro", "region": "IN"}'
```

### 3. Check Database
In Supabase dashboard:
```sql
SELECT * FROM price_history ORDER BY created_at DESC LIMIT 10;
```

You should see price records inserted.

### 4. Search Again (After a Few Hours)
Run the same search again — the deduplication will prevent duplicate entries if prices haven't changed.

### 5. Search Different Products
Search multiple products over time to build up the database.

### 6. Verify Trends
After 2+ weeks of data:
```sql
SELECT 
  product_name,
  COUNT(*) as records,
  MIN(price) as lowest,
  MAX(price) as highest,
  AVG(price) as average
FROM price_history
WHERE region = 'IN'
GROUP BY product_name
ORDER BY records DESC;
```

## Benefits

1. **No External API Costs** - Keepa costs $40-150/month. This is free (using our own data).
2. **Region-Specific** - Tracks prices per region (IN, US, AU, etc.).
3. **Real-Time** - Data collected every time someone searches.
4. **Cumulative** - Gets better over time as more searches happen.
5. **Privacy-Friendly** - No user tracking, just anonymous price data.
6. **Trend Detection** - Can tell if prices are rising, falling, or stable.
7. **Smarter Verdicts** - Gemini makes better BUY/WAIT decisions with historical context.

## What's Next

### Short Term (Weeks 1-2)
- Monitor database growth
- Verify deduplication is working
- Check for any errors in logs

### Medium Term (Months 1-3)
- Add weekly/monthly aggregation for faster queries
- Build price alert system (notify when price drops below threshold)
- Create admin dashboard to visualize price trends

### Long Term (Months 3-6)
- Price prediction (ML model trained on our data)
- Competitor analysis (which retailers have best prices over time)
- Seasonal trend detection (identify best time to buy each category)

## Notes

- Deduplication window is 6 hours (configurable in code)
- Product names are normalized (lowercased, trimmed) for consistent matching
- Fire-and-forget storage means API stays fast (~same latency)
- RLS enabled but service role has full access (secure by default)

## Troubleshooting

**No price history showing?**
- Check if migration ran successfully
- Verify `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are set
- Check server logs for "[price-history]" messages

**Duplicate prices?**
- Deduplication checks last 6 hours
- If price changes slightly, it will store the new price
- Check database: `SELECT COUNT(*), product_name FROM price_history GROUP BY product_name;`

**Slow queries?**
- Indexes should handle 100k+ records efficiently
- If queries slow down, add more specific indexes
- Consider partitioning by month after 1M+ records

---

**Status:** ✅ Implemented and ready to deploy
**Git Commit:** 8226aeb
**Author:** Subagent (via OpenClaw)
**Date:** 2026-03-07

# Savvit Backend — Comprehensive Improvement Plan

*Generated: March 7, 2026*

## ✅ Already Done (today)
1. Response caching (1hr full response cache) — repeat queries instant
2. Expired deal filtering (past validUntil dates)
3. Stale sale event filtering (Republic Day in March, etc.)
4. WAIT bias fix (don't recommend waiting 60+ days)
5. More retailers in Perplexity prompt (3+ required)
6. Today's date injected into all prompts
7. Launch intel fact-checking (cross-ref product cycles, citation scoring, date sanity)

---

## 🔴 HIGH IMPACT — Must Do

### 8. Wire up Keepa for price history (THE killer feature)
**Why**: Without price history, we can't tell users if the current price is good or bad. This is what makes us different from just Googling.
**Status**: Keepa code is fully written (`services/keepa.ts`) but `KEEPA_API_KEY` env var is empty.
**Cost**: Keepa API starts at €15/mo for 10K lookups (more than enough for MVP).
**What to do**:
- Get Keepa API key (https://keepa.com/#!api)
- Set env var on Render
- In `products.ts`, extract ASIN from prices (Amazon URL or Keepa search) → call `getAmazonPriceHistory()`
- Feed history into Gemini verdict (already wired up in VerdictInput)
- Return `priceHistory` in response (app already expects it)
**Effort**: 2-3 hours (code is 90% done)

### 9. ASIN extraction for Keepa lookups
**Why**: Keepa needs an ASIN. We need to extract it from Amazon URLs or search Keepa by product name.
**What to do**:
- Add `extractAsinFromPrices()` — scan prices array for Amazon retailer, extract ASIN from URL
- Fallback: use Keepa search API (`searchAmazonProduct()` already written)
- For non-Amazon products: skip Keepa, mention "Amazon price history not available"
**Effort**: 1 hour

### 10. Parallel + streaming response
**Why**: 8-24s is way too long. Users leave after 3 seconds.
**Options**:
- **SSE (Server-Sent Events)**: Stream partial results as they arrive. Send prices first (~3s), then deals, then verdict. App shows progressively.
- **Pre-fetch popular products**: Cache top 100 searches (iphone, macbook, ps5, etc.) via cron
- **Reduce Perplexity calls**: Currently 3 parallel calls (prices + launch + deals). Could combine prices+deals into 1 prompt.
**Recommended**: SSE streaming + combine prices+deals prompt
**Effort**: 4-6 hours for SSE, 1 hour for combined prompt

### 11. Combine prices + deals into single Perplexity call
**Why**: 2 Perplexity calls → 1. Saves ~3-4 seconds + API cost.
**How**: Merge the prices and deals system prompts. Ask Perplexity for both in one JSON response.
**Risk**: Response quality might decrease (asking for too much). Test first.
**Effort**: 1-2 hours

### 12. Smart sale calendar — match product categories to relevant sales
**Why**: Currently returns the next sale regardless of product type. An iPhone shouldn't suggest "Memorial Day appliance sale."
**How**: `getNextSaleEvent()` already has `categories` in SaleEvent. Match product category to sale categories.
**What to do**:
- Add product category detection (electronics, fashion, home, gaming, etc.)
- Filter `SALE_CALENDAR` by matching categories
- Return the most relevant upcoming sale, not just the next one
**Effort**: 1-2 hours

---

## 🟡 MEDIUM IMPACT — Should Do

### 13. Direct product URLs instead of search URLs
**Why**: Users want to tap and buy. Search URLs add friction.
**How**: Perplexity often returns actual product page URLs in citations. Extract and use those.
**What to do**:
- Parse Perplexity citations for retailer URLs
- Match citations to retailers in the prices array
- Replace search URLs with direct product URLs when available
- Fallback: keep search URLs
**Effort**: 2 hours

### 14. Price normalization + outlier detection
**Why**: Sometimes Perplexity returns weird prices (accessories priced as main product, wrong variant pricing).
**How**:
- Calculate median price across retailers
- Flag any price that's >50% away from median as suspicious
- Add `priceConfidence` field: "confirmed" / "estimated" / "suspicious"
- Filter out obvious outliers (e.g., a case priced as the phone)
**Effort**: 1-2 hours

### 15. Pre-warm popular searches via cron
**Why**: First search for popular products is slow. If we pre-cache the top 50-100 products, most users get instant results.
**How**:
- Add a cron job that searches popular products every 6 hours
- Products: iPhone 16 Pro, MacBook Air M4, PS5, AirPods Pro, Galaxy S25, etc.
- Region-specific: IN and US top 50 each
**Effort**: 1-2 hours (+ cron setup)

### 16. Supabase persistent cache (survive restarts)
**Why**: In-memory cache dies on every Render deploy/restart. Users get slow results after every push.
**How**:
- Add Supabase table: `search_cache(key, data, expires_at)`
- Check Supabase before making API calls
- Write to both memory cache + Supabase
- Memory cache = fast reads, Supabase = persistence
**Effort**: 2-3 hours

### 17. Rate limiting
**Why**: No rate limiting = someone could drain our API credits.
**How**:
- IP-based rate limit: 10 searches/hour for unauthenticated
- 30 searches/hour for authenticated users
- Pro users: 100/hour
- Use Hono middleware
**Effort**: 1 hour

### 18. Error responses with retry guidance
**Why**: When Perplexity/Gemini fail, users get generic errors.
**How**:
- Return structured errors: `{ error, code, retryAfter, suggestion }`
- Codes: `RATE_LIMITED`, `SEARCH_FAILED`, `TIMEOUT`, `REGION_NOT_SUPPORTED`
- Include `retryAfter` in seconds for rate limits
**Effort**: 30 min

---

## 🟢 NICE TO HAVE — Polish

### 19. Product category auto-detection
**Why**: Better sale matching, better Perplexity prompts, better Gemini verdicts.
**How**: Keyword-based + Perplexity can tag category in response.
- "iphone" → smartphones, "macbook" → laptops, "ps5" → gaming, etc.
**Effort**: 1 hour

### 20. Multi-variant support
**Why**: "iPhone 16 Pro" has 128GB, 256GB, 512GB, 1TB. Prices differ wildly.
**How**: Detect storage/color/size variants. Return all variants with prices.
**Effort**: 3-4 hours

### 21. Confidence explanation
**Why**: Users see 0.8 confidence but don't know what it means.
**How**: Add `confidenceExplanation`: "High confidence — 6 retailers checked, prices consistent, verified launch data"
**Effort**: 30 min

### 22. Analytics endpoint
**Why**: Know what users are searching for → pre-cache, improve prompts.
**How**: Log searches to Supabase, add admin endpoint to view top queries.
**Effort**: 1-2 hours

### 23. Keepa domain support beyond IN
**Why**: Currently Keepa is hardcoded to Amazon India (domain=10).
**How**: Map region codes to Keepa domain codes (US=1, UK=2, DE=3, etc.)
**Effort**: 30 min (once Keepa is wired up)

---

## Priority Order (suggested)

### Phase 1: Quick Wins (this weekend)
- [x] ~~#1-7 (done today)~~
- [ ] #11 — Combine prices+deals prompt (saves 3-4s)
- [ ] #12 — Smart sale calendar (match product category)
- [ ] #14 — Price outlier detection
- [ ] #17 — Rate limiting
- [ ] #18 — Better error responses

### Phase 2: Killer Feature (next week)
- [ ] #8 — Wire up Keepa (need API key)
- [ ] #9 — ASIN extraction
- [ ] #23 — Multi-region Keepa

### Phase 3: Speed (next week)
- [ ] #10 — SSE streaming response
- [ ] #15 — Pre-warm popular searches
- [ ] #16 — Supabase persistent cache

### Phase 4: Polish
- [ ] #13 — Direct product URLs
- [ ] #19 — Category auto-detection
- [ ] #20 — Multi-variant support
- [ ] #21 — Confidence explanation
- [ ] #22 — Analytics

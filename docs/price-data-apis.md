# Savvit — Price Data Sources: Comprehensive Research
*Research date: 2026-02-18*

---

## 1. Amazon Product Advertising API 5.0 (PA-API)

| Aspect | Details |
|--------|---------|
| **Data you get** | Current price (list, sale, savings), buy box price, availability, offers from multiple sellers, product details, images, reviews summary. **NO historical prices.** |
| **Cost** | **Free** — no subscription. But you MUST be an Amazon Associate (affiliate). |
| **Rate limits** | Initial: **1 TPS, 8,640 TPD** for first 30 days. Then scales with affiliate revenue: 1 TPD per $0.05 shipped revenue, 1 TPS per $4,320 revenue (max 10 TPS). **If zero sales for 30 days → access revoked.** |
| **India support** | ✅ Supports amazon.in locale. Prices in INR. Docs note "refer to Creators API" but PA-API still works. |
| **Historical data** | ❌ None. Current prices only. |
| **Gotchas** | • Must generate affiliate sales or lose access — chicken-and-egg problem for MVP. • Rate limits tied to revenue = unpredictable scaling. • Must display affiliate links. • Can't cache prices beyond 24 hours per TOS. • India PA-API may have less documentation/support. |
| **Verdict** | Essential for real-time Amazon prices. But you MUST build your own price history by storing snapshots over time. |

---

## 2. Flipkart Affiliate API

| Aspect | Details |
|--------|---------|
| **Status (2025-2026)** | ✅ **Active and available.** Register at affiliate.flipkart.com. |
| **Data you get** | Product details (title, description, images, price, MRP, discount), category browsing, keyword search, deals of the day, affiliate order tracking. JSON/XML over HTTPS. |
| **Cost** | **Free** — tied to affiliate program. Commissions up to 12% by category. |
| **Rate limits** | Not publicly documented in detail — likely modest. Need to test after registration. |
| **India support** | ✅ **India-only** (Flipkart is India-only). |
| **Historical data** | ❌ None. Current prices only. |
| **Access** | Register at affiliate.flipkart.com → get API credentials. Straightforward. |
| **Verdict** | **Must-have for India MVP.** Flipkart is the #2 e-commerce platform. Same limitation as Amazon — must build your own history. |

---

## 3. SerpApi (Google Shopping)

| Aspect | Details |
|--------|---------|
| **Data you get** | Product title, price, seller, rating, reviews, shipping info, product link — scraped from Google Shopping SERP results. Multi-seller comparison. |
| **Cost** | Free: 100 searches/mo. Starter: $25/mo (1K). Developer: $75/mo (5K). Production: $150/mo (15K). ~$0.01-0.025 per request. |
| **Rate limits** | Based on plan tier. |
| **India support** | ✅ Supports `gl=in` (India) and `hl=en` parameters. Google Shopping works in India. |
| **Historical data** | ❌ None. Point-in-time SERP snapshots only. |
| **Reliability** | Good — Google Shopping aggregates multiple sellers. But accuracy depends on Google's own indexing. Not all products appear on Google Shopping India. |
| **Alternatives** | Serper ($0.001/req, cheaper), ScrapingDog ($0.001/req). |
| **Verdict** | Great for cross-platform price comparison (finds prices from multiple retailers in one call). Not a primary source — supplementary. Useful for "is this cheaper elsewhere?" feature. |

---

## 4. Keepa API

| Aspect | Details |
|--------|---------|
| **Data you get** | **Full Amazon price history** — buy box price, new/used prices, sales rank, offer counts, review counts, rating history, stock availability, all over time. Interactive charts. |
| **Cost** | Token-based, €49/mo (20 tokens/min) → €4,499/mo (4,000 tokens/min). Basic plan sufficient for MVP. |
| **India support** | ✅ **Supports amazon.in** — one of 12 supported Amazon marketplaces. |
| **Historical data** | ✅✅✅ **This is Keepa's entire value proposition.** Years of price history per ASIN. |
| **Rate limits** | Token-based. Each API call costs tokens. 20 tokens/min on basic = ~28,800 tokens/day. A product lookup costs ~1-2 tokens. |
| **Limitations** | **Amazon-only.** No Flipkart, no other retailers. |
| **Verdict** | **🏆 CRITICAL for MVP.** Solves the cold-start problem for Amazon price history. Without Keepa, you'd need months of your own data collection before AI verdicts are meaningful. €49/mo is very reasonable for what you get. |

---

## 5. Other Price Data APIs

### PriceAPI (priceapi.com)
| Aspect | Details |
|--------|---------|
| **What** | Real-time price collection from Amazon, Google Shopping, eBay, and other marketplaces. |
| **Cost** | €99/mo (5K credits) → €1,499/mo (500K credits). Free trial: 1K credits. |
| **India** | Not explicitly confirmed; supports Amazon globally. |
| **Historical** | ❌ Real-time only. |
| **Verdict** | Expensive for what you get vs. using PA-API + scraping directly. Better for B2B competitor monitoring. |

### Prisync
| Aspect | Details |
|--------|---------|
| **What** | Competitor price monitoring for retailers. |
| **Cost** | $99-$399/mo. |
| **Historical** | Up to 2 years. |
| **Verdict** | Designed for retailers repricing their own products, not consumer price tracking apps. Wrong use case. |

### Price2Spy
| Aspect | Details |
|--------|---------|
| **What** | Enterprise price monitoring. Real-time + hourly updates. |
| **Cost** | $25-$1,580/mo. |
| **Historical** | Up to 10 years. |
| **Verdict** | Enterprise-focused, overkill and expensive for a consumer app. |

### Oxylabs / Bright Data (Web Scraping APIs)
| Aspect | Details |
|--------|---------|
| **What** | Managed scraping infrastructure with proxy rotation, CAPTCHA solving. |
| **Cost** | $49-500+/mo depending on volume. |
| **India** | ✅ Support Indian sites. |
| **Verdict** | Good fallback if you need to scrape at scale without building your own infra. Consider for V2. |

---

## 6. Web Scraping as Fallback

### Legal Considerations (India)
- **No explicit anti-scraping law** in India.
- **IT Act Section 43**: Penalizes "unauthorized access" — scraping public pages is generally okay; bypassing login walls is not.
- **DPDPA**: Exempts publicly available data but has contradictions around consent.
- **hiQ v. LinkedIn precedent**: Public data scraping generally upheld (US case, but persuasive).
- **Platform TOS**: Both Amazon and Flipkart explicitly prohibit scraping. Risk = account bans, cease-and-desist, IP blocks.
- **Bottom line**: Scraping **public product pages** is legally low-risk in India. But use APIs first, scraping as fallback.

### Tools
| Tool | Best For |
|------|----------|
| **Playwright** | Full browser rendering, JS-heavy sites, stealth mode. Best for Flipkart. |
| **Puppeteer** | Similar to Playwright, Chrome-only. |
| **Cheerio + Axios** | Lightweight HTML parsing for simpler pages. |
| **Scrapy (Python)** | High-volume crawling with built-in scheduling. |

### Reliability
- **Amazon**: Heavy anti-bot measures. Rotating proxies essential. Detection rate high.
- **Flipkart**: Moderate anti-bot. More scraping-friendly than Amazon but still blocks aggressively.
- **Expect 5-15% failure rate** without proxy rotation. With good proxies: <2%.

### Recommendation
Use scraping for:
- Sites without APIs (Myntra, Croma, Tata CLiQ, etc.)
- Supplementing API data gaps
- V2 expansion to non-Amazon/Flipkart retailers

---

## 7. UPC/Barcode Lookup APIs

| API | Free Tier | Database Size | India Coverage | Notes |
|-----|-----------|---------------|----------------|-------|
| **UPCitemdb** | 100 req/day | Large | Unclear | No signup needed. Best free option. |
| **Go-UPC** | Limited | 500M+ products | Partial (Asia) | Good international coverage. |
| **Open Food Facts** | Unlimited | Food/grocery only | Decent for food | Open source. India grocery coverage growing. |
| **Scanbot SDK** | Lookup tool | 500M+ | Unknown | SDK-based, not just API. |
| **Google Barcode API** | Via Vision API | Google's index | Good | Costs per call. |

**India-specific issue**: Many Indian products use **EAN-13** (not UPC-A). Indian barcodes start with **890**. Coverage in global databases is spotty for India-only brands.

**Recommendation**: Use UPCitemdb for MVP (free, no signup). Supplement with user-submitted product links (more reliable for India). Barcode scanning is a nice-to-have, not critical path.

---

## 8. How Existing Apps Get Their Data

### Keepa (Browser Extension)
- **Crowdsourced + API**: Browser extension users contribute price data as they browse Amazon. Millions of users = massive passive data collection.
- Combined with Amazon PA-API for real-time prices.
- This is why their historical data is so good — years of crowdsourced snapshots.

### PriceSense
- Web scraping + Google Shopping data for US retailers (Amazon, Best Buy, Walmart, Target).
- AI layer on top for price prediction.

### Retrack
- Amazon PA-API + likely scraping for non-Amazon sources.

### Price History (India app - pricehistory.app)
- **Scraping-based** for Indian platforms: Amazon India, Flipkart, Myntra, TataCliq, Croma, Ajio, Snapdeal.
- Stores price snapshots on their servers, displays as charts.
- This is basically what Savvit needs to do, but with AI on top.

### Industry Standard Pattern
1. **APIs where available** (Amazon PA-API, Flipkart Affiliate API)
2. **Scheduled scraping** for everything else (hourly/daily cron jobs)
3. **Store every price snapshot** in time-series DB
4. **Message queue** (Kafka/RabbitMQ) to decouple collection from processing
5. **Proxy rotation** for scraping reliability
6. **Cache layer** for fast reads

---

## Comparison Table

| Source | Real-time Price | Historical | India | Cost | Reliability | Effort |
|--------|:-:|:-:|:-:|--------|:-:|:-:|
| **Amazon PA-API 5.0** | ✅ | ❌ | ✅ | Free (affiliate req.) | ⭐⭐⭐⭐ | Low |
| **Flipkart Affiliate API** | ✅ | ❌ | ✅ | Free (affiliate req.) | ⭐⭐⭐⭐ | Low |
| **Keepa API** | ✅ | ✅✅✅ | ✅ (Amazon only) | €49+/mo | ⭐⭐⭐⭐⭐ | Low |
| **SerpApi/Google Shopping** | ✅ | ❌ | ✅ | $25+/mo | ⭐⭐⭐ | Low |
| **PriceAPI** | ✅ | ❌ | Partial | €99+/mo | ⭐⭐⭐⭐ | Low |
| **Own Scraping** | ✅ | ✅ (self-built) | ✅✅ | Proxy costs ~$50+/mo | ⭐⭐⭐ | High |
| **Prisync/Price2Spy** | ✅ | ✅ | Partial | $99+/mo | ⭐⭐⭐⭐ | Low |
| **UPCitemdb** | N/A | N/A | Weak | Free | ⭐⭐⭐ | Low |

---

## 🏆 Recommended Stack

### MVP (Launch in ~2 months)

| Layer | Solution | Cost | Why |
|-------|----------|------|-----|
| **Amazon prices (real-time)** | Amazon PA-API 5.0 | Free | Official, reliable, India support |
| **Amazon price history** | Keepa API (Basic) | €49/mo (~₹4,500) | Instant years of history. Solves cold-start. Critical for AI verdicts. |
| **Flipkart prices** | Flipkart Affiliate API | Free | Official, India-only, reliable |
| **Flipkart price history** | Self-built (store daily snapshots) | Infra cost only | No Keepa equivalent for Flipkart. Start collecting from day 1. |
| **Cross-platform comparison** | SerpApi or Serper | $25-75/mo | "Is it cheaper elsewhere?" feature |
| **Product identification** | User-submitted URLs (primary) + UPCitemdb (barcode) | Free | URL parsing is more reliable than barcode for India |
| **Storage** | PostgreSQL + TimescaleDB | Infra cost | Time-series extension for price history |

**MVP Monthly Cost: ~€75-125/mo (~₹7,000-11,000)**

### V2 (3-6 months post-launch)

| Addition | Solution | Why |
|----------|----------|-----|
| **More Indian retailers** | Playwright scraping (Myntra, Croma, TataCliq, Ajio) | Expand coverage. Use proxy rotation (Oxylabs/Bright Data). |
| **Better Flipkart history** | By now you have 3-6 months of your own data | AI verdicts become meaningful |
| **Global expansion** | Add Keepa for US/UK/DE markets | Same API, different locale |
| **Price prediction ML** | Train on Keepa historical + your own data | "Buy now vs wait" with confidence scores |
| **Crowdsourced data** | Optional browser extension / share feature | Long-term moat, like Keepa's model |

### Architecture Summary

```
User submits URL/barcode
        ↓
  URL Parser / Barcode Lookup
        ↓
  Route to correct data source
   ├── Amazon → PA-API (real-time) + Keepa (history)
   ├── Flipkart → Affiliate API (real-time) + own DB (history)
   └── Others → SerpApi / Scraper
        ↓
  Store price snapshot → TimescaleDB
        ↓
  AI Verdict Engine (current price vs. historical patterns)
        ↓
  "Buy Now 🟢" / "Wait 🟡" / "Don't Buy 🔴"
```

### Key Insight
**Keepa is the secret weapon.** Without it, your AI verdicts are meaningless until you've collected months of your own data. With Keepa, you have instant access to years of Amazon price history on day one — enabling accurate "buy now vs wait" verdicts from launch. €49/mo is a steal for this.

For Flipkart, there's no equivalent to Keepa, so start collecting price snapshots immediately. Your Flipkart AI verdicts will be weaker at launch but improve over time.

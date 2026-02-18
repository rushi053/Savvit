# Savvit — Product Specification
### "Should I buy this now?"

*Single source of truth. Last updated: 2026-02-18*

---

## 🎯 What Is Savvit?

An iOS app that answers one question: **"Should I buy this now — or wait?"**

User searches for any product → gets an instant AI-powered verdict with:
- 🟢 BUY NOW / 🟡 WAIT / 🔴 DON'T BUY
- Best price across all Indian retailers right now
- Where to buy if buying today (with reasoning)
- Why to wait if waiting is smarter (upcoming sales, new model launches, price trends)
- Full price history chart

**One screen replaces** 30 minutes of Googling, checking 5 retailer websites, reading "best time to buy" articles, and searching for launch dates.

---

## 👤 Target User

- Indian consumers aged 18-35
- Tech buyers (phones, laptops, gadgets, gaming)
- Deal-conscious shoppers who research before buying
- Anyone who's ever Googled "should I buy iPhone now or wait"

---

## 📱 Core User Flow

### Adding a Product
1. **Search** — Type product name ("iPhone 16 Pro 256GB")
2. **Paste URL** — Amazon/Flipkart product link
3. **Barcode scan** — Camera (V2, not MVP)

### The Verdict Screen (The Hero)
```
┌─────────────────────────────────────┐
│  iPhone 16 Pro 256GB                │
│                                      │
│  🟡 WAIT — New model in 5 weeks     │
│  You could save ₹25,000-30,000      │
│                                      │
│  ─── IF YOU WANT IT NOW ───         │
│                                      │
│  Best price: Flipkart  ₹1,18,999 ✅│
│  Amazon        ₹1,19,900            │
│  Croma         ₹1,21,990            │
│  Reliance      ₹1,19,900            │
│                                      │
│  💡 Flipkart has no-cost EMI +      │
│     extra ₹2,000 off with HDFC      │
│                                      │
│  ─── IF YOU CAN WAIT ───           │
│                                      │
│  📅 iPhone 17 Pro — Sep 2026        │
│     → Current model drops 15-25%    │
│     → Expected price: ~₹89,900     │
│                                      │
│  📅 Amazon Great Indian Festival    │
│     Oct 2026 — historically 18% off │
│     → Expected price: ~₹97,000     │
│                                      │
│  ─── PRICE HISTORY ───             │
│  [📈 Chart: 1Y Amazon price]        │
│  All-time low: ₹99,900 (Oct '25)   │
│                                      │
│  [🛒 Buy on Flipkart — ₹1,18,999]  │
│  [🔔 Alert me when below ₹___]     │
└─────────────────────────────────────┘
```

### Watchlist (Home Screen)
- Cards showing each tracked product with verdict badge
- Quick glance: 🟢🟡🔴 + current best price + one-line reason
- Pull to refresh

---

## 🆓 Free vs Pro

| Feature | Free | Pro |
|---------|------|-----|
| Items on watchlist | 3 | Unlimited |
| Verdict (🟢🟡🔴) | ✅ | ✅ |
| Basic reason (1 line) | ✅ | ✅ |
| Best current price (1 retailer) | ✅ | ✅ |
| **All retailer prices** | 🔒 | ✅ |
| **Detailed AI analysis** (savings estimate, best time, launch alerts) | 🔒 Blurred teaser | ✅ |
| **Price history chart** | 30 days | Full history |
| **Price drop alerts** | ❌ | ✅ |
| **Target price alerts** | ❌ | ✅ |
| **Sale calendar predictions** | ❌ | ✅ |
| **Product launch intelligence** | ❌ | ✅ |

### Pricing
| Region | Monthly | Yearly |
|--------|---------|--------|
| India | ₹79 | ₹499 |
| Global | $2.99 | $19.99 |

### Pro Teaser UX
Every free verdict shows a blurred "Pro Insight" card below the basic verdict. User can see there's specific savings info and detailed analysis but can't read it. Creates natural conversion pressure.

---

## 🧠 Intelligence Architecture

### Data Flow
```
User: "iPhone 16 Pro 256GB"
    │
    ├─→ Perplexity Sonar #1: Current prices
    │   Query: "iPhone 16 Pro 256GB price India 2026"
    │   Returns: prices from Amazon, Flipkart, Croma,
    │   Reliance Digital, Vijay Sales + any offers/EMI
    │
    ├─→ Keepa API: Amazon price history
    │   Returns: all-time low, avg, 30/90/180/365 day trends
    │
    ├─→ Perplexity Sonar #2: Launch intelligence (cached 7 days)
    │   Query: "iPhone 17 Pro launch date 2026"
    │   Returns: expected date, leaked features, etc.
    │
    ├─→ Sale Calendar (hardcoded JSON + cached)
    │   Returns: next Amazon/Flipkart sale event + dates
    │
    ├─→ Product Cycles (hardcoded JSON)
    │   Returns: typical launch month, historical price drop %
    │
    └─→ ALL fed to Gemini Flash Lite as structured context
        │
        ↓
    Structured JSON verdict:
    {
      verdict, confidence, reason,
      best_deal: { retailer, price, url, offers },
      all_prices: [{ retailer, price, url }],
      wait_reasons: [{ event, date, expected_price, savings }],
      launch_alert: { product, date, impact },
      price_history_summary: { low, high, avg, trend }
    }
```

### Models & Roles
| Model | Role | Cost |
|-------|------|------|
| **Perplexity Sonar** | Real-time web price search + launch news | ~$0.01/call |
| **Keepa API** | Amazon historical price data (years) | €49/mo flat |
| **Gemini 2.5 Flash Lite** | Verdict generation from structured data | ~$0.0001/call |
| **Hardcoded JSON** | Sale calendar + product launch cycles | Free |

### Cost Per Lookup
- 2 Perplexity calls (~$0.02) + 1 Keepa lookup (flat rate) + 1 Gemini call (~$0.0001)
- **~$0.02 per full product lookup**
- Cached aggressively: prices 6-12h, launch news 7 days, sale calendar 30 days
- Estimated cost at 1,000 DAU: ~$20-40/month

### Caching Strategy
| Data | Cache Duration | Storage |
|------|---------------|---------|
| Current prices | 6-12 hours | Supabase |
| Keepa price history | 24 hours | Supabase |
| Launch intelligence | 7 days | Supabase |
| Sale calendar | 30 days (manual update) | Hardcoded JSON |
| Product cycles | Evergreen (manual update) | Hardcoded JSON |
| Generated verdicts | 12 hours (or until price change) | Supabase |

---

## 🏗️ Tech Stack

### iOS App
| Layer | Choice |
|-------|--------|
| UI | SwiftUI |
| Architecture | MVVM + Swift Concurrency |
| Local DB | SwiftData (watchlist cache, offline verdicts) |
| Charts | Swift Charts |
| Payments | RevenueCat |
| Analytics | PostHog iOS SDK |
| Push | APNs |
| Min iOS | 17.0 |

### Backend
| Layer | Choice |
|-------|--------|
| Runtime | Node.js + TypeScript |
| Framework | Hono |
| Database | Supabase (PostgreSQL) |
| Hosting | Render |
| Cron | Render Cron Jobs |
| Auth | Supabase Auth (Apple + Google Sign In) |

### External Services
| Service | Purpose | Cost |
|---------|---------|------|
| Perplexity Sonar API | Price search + launch news | ~$25-50/mo |
| Keepa API | Amazon price history | €49/mo |
| Gemini Flash Lite | Verdict generation | ~$1-5/mo |
| Supabase | Database + Auth | Free tier |
| Render | Backend hosting + cron | Free → $7/mo |
| RevenueCat | Subscription management | Free under $2.5K MRR |
| PostHog | Analytics | Free tier |
| Apple Developer | App Store | ₹8,700/yr (existing) |

**Total monthly cost: ~₹8,000-12,000** ($95-145)

---

## 🔐 Auth & Onboarding

### Sign In Options
- **Apple Sign In** (required by App Store)
- **Google Sign In** (covers most Indian users)
- No email/password for MVP

### Onboarding Flow (Value-First)
```
First Launch
    ↓
Screen 1: "Should you buy this now?"
    Hero visual: 🟢🟡🔴 concept
    "Savvit tells you the perfect time to buy"
    ↓
Screen 2: "How it works"
    Search → Compare → Decide
    ↓
Screen 3: "Track what matters"
    "Add up to 3 items free"
    ↓
[Go straight to home — NO sign-in gate]
    ↓
User adds first item → sees verdict → hooked
    ↓
Sign-in prompted when:
    - Adding 2nd item (soft: "Sign in to save watchlist")
    - Enabling push notifications
    - Hitting Pro paywall
```

---

## 💰 Revenue Model

### Stream 1: Pro Subscriptions
₹79/mo × subscribers via RevenueCat

### Stream 2: Affiliate Commissions
Every "Buy on [Retailer]" button is an affiliate link:
- Amazon Associates India: 1-10% (avg ~4%)
- Flipkart Affiliate: up to 7.5-9%

### Stream 3: Sponsored Placements (V2+)
Retailers pay for "Recommended" badge

---

## 📣 Marketing Plan

### Pre-Launch
- Reserve savvit.app domain
- Reserve @savvitapp on X, Instagram
- Build-in-public posts on @rushirajjj

### Launch
- App Store ASO: "price tracker india", "buy or wait", "deal finder"
- Product Hunt: "From the maker of CashLens (3K+ downloads)"
- Reddit: r/india, r/indiangaming, r/dealsforindia
- Time near major sale event for maximum relevance

### Ongoing
- X/Instagram: savings stories, "I saved ₹15K by waiting"
- Short-form video demos (Reels/Shorts)

### Tagline
**"Should you buy it now? Ask Savvit."**

---

## 📅 Build Plan

### Pre-Build (Day 0) — Rushi's Setup Tasks
- [ ] Buy savvit.app domain on Namecheap
- [ ] Reserve "Savvit" on App Store (App Store Connect)
- [ ] Create GitHub repo: rushi053/savvit (private)
- [ ] Sign up for Amazon Associates India (affiliate.amazon.in)
- [ ] Sign up for Flipkart Affiliate (affiliate.flipkart.com)
- [ ] Sign up for Keepa API (keepa.com/#!api)
- [ ] Get Perplexity API key (if not already have one)
- [ ] Verify Gemini API key works (existing from Simon project)
- [ ] Reserve @savvitapp on X and Instagram

### Week 1: Foundation
**Backend (Clawdbot builds):**
- [ ] Hono API skeleton on Render
- [ ] Supabase schema (users, products, watchlist, price_history, verdicts, sale_events)
- [ ] Supabase Auth setup (Apple + Google providers)
- [ ] Perplexity price search endpoint
- [ ] Keepa integration endpoint
- [ ] Gemini verdict engine
- [ ] Product search + lookup API
- [ ] Hardcoded sale calendar + product cycles JSON

**iOS (Rushi builds in Cursor with Claude):**
- [ ] Xcode project setup (SwiftUI, SwiftData, MVVM)
- [ ] Onboarding screens (3 screens)
- [ ] Home screen — watchlist with verdict cards
- [ ] Search screen — product search
- [ ] Add by URL — paste Amazon/Flipkart link
- [ ] API client — connect to backend

### Week 2: Intelligence + Polish
**Backend:**
- [ ] Cron job: refresh prices every 12h for watched products
- [ ] Cron job: refresh verdicts when prices change
- [ ] Push notification triggers (price drops, launch alerts)
- [ ] Caching layer (Supabase)

**iOS:**
- [ ] Verdict detail screen (the hero screen from spec)
- [ ] Price history chart (Swift Charts)
- [ ] RevenueCat paywall integration
- [ ] Pro vs Free gating (blurred Pro Insight)
- [ ] Apple + Google Sign In
- [ ] Push notification registration
- [ ] Settings screen

### Week 3: Ship It
- [ ] App Store screenshots + metadata
- [ ] TestFlight beta
- [ ] Bug fixes + polish
- [ ] App Store submission
- [ ] PostHog analytics events
- [ ] Landing page on savvit.app

### Post-Launch (V2)
- [ ] Barcode scanning
- [ ] URL share extension (add from Safari)
- [ ] Home screen widget (verdict badges)
- [ ] SerpApi for broader retailer coverage
- [ ] Price comparison between specific models
- [ ] Social sharing ("I saved ₹15K with Savvit")

---

## 🗂️ Code & Project Management

### Repository Structure
```
savvit/
├── ios/                    # Xcode project (Rushi in Cursor)
│   ├── Savvit/
│   │   ├── App/            # App entry, config
│   │   ├── Models/         # SwiftData models
│   │   ├── ViewModels/     # MVVM view models
│   │   ├── Views/          # SwiftUI views
│   │   ├── Services/       # API client, auth, RevenueCat
│   │   └── Utils/          # Helpers, extensions
│   └── Savvit.xcodeproj
│
├── server/                 # Backend (Clawdbot builds)
│   ├── src/
│   │   ├── routes/         # API routes
│   │   ├── services/       # Perplexity, Keepa, Gemini, APNs
│   │   ├── data/           # Sale calendar, product cycles JSON
│   │   ├── utils/          # Cache, auth middleware, helpers
│   │   └── index.ts        # Hono app entry
│   ├── package.json
│   └── tsconfig.json
│
├── docs/                   # This spec + architecture docs
└── README.md
```

### Workflow
- **GitHub**: Private repo `rushi053/savvit`
- **Rushi**: Builds iOS in Cursor (Claude Sonnet 4 / Opus 4)
- **Clawdbot**: Builds backend, reviews iOS code, handles deployment
- **Branching**: `main` (production), feature branches for big changes
- **Deploy**: Push to main → Render auto-deploys backend

### How Clawdbot Sees The Code
- Clone repo to `~/Desktop/savvit` (Rushi's machine)
- Clawdbot reads/writes via filesystem access
- Can review iOS code, suggest fixes, write backend code directly
- Can push to GitHub, trigger deploys

---

## ⚠️ Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Amazon PA-API revoked (no sales in 30 days) | Perplexity web search as primary, PA-API as bonus |
| Perplexity prices inaccurate | Cross-reference with Keepa, cache + validate |
| Gemini verdicts wrong | Conservative defaults (more WAIT than BUY), confidence %, disclaimers |
| Keepa cost not justified early | Start with Keepa, drop if costs > revenue |
| Apple App Store rejection | Using official APIs, no scraping, no misleading claims |
| Scope creep | THIS SPEC is the scope. V2 features stay in V2. |

---

*This is the plan. Stick to it. Ship in 3 weeks.*

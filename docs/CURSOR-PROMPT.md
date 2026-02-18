# Savvit iOS App — Full Build Specification

You are building **Savvit**, an iOS app that answers: "Should I buy this now — or wait?"

Users search for any product → get an instant AI verdict: 🟢 BUY NOW / 🟡 WAIT / 🔴 DON'T BUY, with multi-retailer prices, launch intelligence, and sale predictions.

## Tech Stack
- **SwiftUI** (iOS 17.0+)
- **SwiftData** for local persistence
- **MVVM architecture** with Swift Concurrency (async/await)
- **Swift Charts** for price history
- **No external dependencies** for MVP (RevenueCat + PostHog added later)
- Native frameworks only: Foundation, SwiftUI, SwiftData, Charts, AuthenticationServices

## Backend API
Base URL: `https://savvit-api.onrender.com`

### Endpoints:
1. **POST /v1/products/search** — Search for a product, returns full verdict
   - Body: `{ "query": "iPhone 16 Pro 256GB" }`
   - Returns: verdict, prices, launch intel, sale predictions, pro analysis
   
2. **GET /v1/watchlist** — Get user's watchlist (auth required)
   - Header: `Authorization: Bearer <token>`
   
3. **POST /v1/watchlist** — Add to watchlist (auth required)
   - Body: `{ "productName": "...", "query": "...", "sourceUrl": "...", "targetPrice": 100000 }`
   
4. **DELETE /v1/watchlist/:id** — Remove from watchlist (auth required)

5. **GET /v1/verdicts/:watchlistId** — Full verdict detail (auth required)

6. **GET /health** — Health check

### Example API Response (POST /v1/products/search):
```json
{
  "query": "iPhone 16 Pro 256GB",
  "product": "iPhone 16 Pro 256GB",
  "verdict": "WAIT",
  "confidence": 0.9,
  "shortReason": "Wait for iPhone 17 Pro launch & sales",
  "reason": "The iPhone 17 Pro is expected in September 2026, which will likely trigger significant price drops on the iPhone 16 Pro.",
  "bestPrice": {
    "retailer": "Flipkart",
    "price": 115900,
    "currency": "INR",
    "url": "https://flipkart.com/...",
    "offers": "SBI card discount + no-cost EMI from ₹5,843/month",
    "inStock": true
  },
  "prices": [
    { "retailer": "Flipkart", "price": 115900, "offers": "...", "inStock": true },
    { "retailer": "Amazon India", "price": 119900, "offers": "", "inStock": true },
    { "retailer": "Croma", "price": 121990, "offers": "", "inStock": true }
  ],
  "proAnalysis": {
    "bestCurrentDeal": "Flipkart at ₹1,15,900 with SBI card discount",
    "waitReason": "iPhone 17 Pro launches Sep 2026, current model drops 15-25%",
    "estimatedSavings": "₹25,000-30,000",
    "bestTimeToBuy": "September 2026 after iPhone 17 Pro launch",
    "launchAlert": "iPhone 17 Pro expected September 2026"
  },
  "launchIntel": {
    "upcomingProduct": "iPhone 17 Pro",
    "expectedDate": "September 2026",
    "summary": "iPhone 17 Pro expected Sep 2026..."
  },
  "nextSale": {
    "name": "Flipkart Big Saving Days",
    "month": 5,
    "discount": "15-35% on electronics"
  },
  "priceHistory": null,
  "citations": ["https://..."]
}
```

---

## 🎨 Design System

### Brand Identity
- **App Name**: Savvit
- **Tagline**: "Should you buy it now? Ask Savvit."
- **Personality**: Smart, confident, minimal, trustworthy
- **Inspiration**: Linear, Revolut, CashLens — clean, modern, premium feel

### Color Palette
```swift
// Primary Colors
static let savvitPrimary = Color(hex: "#6C5CE7")     // Deep purple — brand color
static let savvitSecondary = Color(hex: "#A29BFE")    // Light purple — accents

// Verdict Colors
static let verdictBuy = Color(hex: "#00B894")         // Green — BUY NOW
static let verdictWait = Color(hex: "#FDCB6E")        // Amber — WAIT
static let verdictDont = Color(hex: "#E17055")         // Red-orange — DON'T BUY

// Backgrounds
static let bgPrimary = Color(hex: "#0A0A0F")          // Near-black — main background (dark)
static let bgSecondary = Color(hex: "#14141F")         // Slightly lighter — card backgrounds
static let bgTertiary = Color(hex: "#1E1E2E")          // Cards, surfaces

// Text
static let textPrimary = Color.white
static let textSecondary = Color(hex: "#A0A0B0")       // Muted gray
static let textTertiary = Color(hex: "#6B6B80")         // Very muted

// Light mode equivalents
static let bgPrimaryLight = Color(hex: "#F8F8FC")
static let bgSecondaryLight = Color.white
static let bgTertiaryLight = Color(hex: "#F0F0F5")
static let textPrimaryLight = Color(hex: "#1A1A2E")
static let textSecondaryLight = Color(hex: "#6B6B80")
```

### Typography
```swift
// Use SF Pro (system font) — no custom fonts needed
.font(.system(size: 32, weight: .bold, design: .rounded))    // Hero titles
.font(.system(size: 24, weight: .bold))                       // Section titles  
.font(.system(size: 17, weight: .semibold))                   // Card titles
.font(.system(size: 15, weight: .regular))                    // Body text
.font(.system(size: 13, weight: .medium))                     // Captions, labels
.font(.system(size: 11, weight: .regular))                    // Fine print
```

### Design Principles
1. **Dark-first** — dark mode is the default, light mode supported
2. **Verdict is the hero** — the 🟢🟡🔴 badge is always the most prominent element
3. **Cards everywhere** — content in rounded cards with subtle backgrounds
4. **Generous spacing** — don't cram. Let content breathe. 16-20pt padding minimum.
5. **Subtle animations** — spring animations on appear, smooth transitions, haptic feedback
6. **Blur & glass** — use `.ultraThinMaterial` for overlays and Pro teasers
7. **No sharp corners** — 16pt corner radius on cards, 12pt on buttons
8. **Shadows** — subtle drop shadows on cards in light mode, none in dark mode

### Animations & Micro-interactions
```swift
// Card appear animation — stagger children
.transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
.animation(.spring(response: 0.5, dampingFraction: 0.8), value: isLoaded)

// Verdict badge pulse on appear
.scaleEffect(showVerdict ? 1.0 : 0.5)
.opacity(showVerdict ? 1.0 : 0)
.animation(.spring(response: 0.6, dampingFraction: 0.6), value: showVerdict)

// Price update shimmer
// Use a shimmer/skeleton loading state while API loads

// Pull to refresh with haptic
.refreshable { await viewModel.refresh() }
// Add UIImpactFeedbackGenerator(style: .medium).impactOccurred()

// Tab bar — use smooth spring transitions between tabs
// Button press — scale down to 0.96, spring back

// Loading state — animated gradient shimmer on placeholder cards
```

### Haptic Feedback
```swift
// On verdict reveal — medium impact
UIImpactFeedbackGenerator(style: .medium).impactOccurred()

// On add to watchlist — success notification  
UINotificationFeedbackGenerator().notificationOccurred(.success)

// On button taps — light impact
UIImpactFeedbackGenerator(style: .light).impactOccurred()

// On delete — warning notification
UINotificationFeedbackGenerator().notificationOccurred(.warning)
```

---

## 📁 Project Structure

```
Savvit/
├── App/
│   ├── SavvitApp.swift              # App entry point
│   ├── ContentView.swift            # Root view with tab navigation
│   └── Theme.swift                  # Design system (colors, fonts, spacing)
│
├── Models/
│   ├── Product.swift                # Product search result model
│   ├── Verdict.swift                # Verdict model (BUY_NOW/WAIT/DONT_BUY)
│   ├── WatchlistItem.swift          # SwiftData model for watchlist
│   ├── PriceInfo.swift              # Price from a retailer
│   └── LaunchIntel.swift            # Upcoming product launch info
│
├── ViewModels/
│   ├── SearchViewModel.swift        # Product search logic
│   ├── WatchlistViewModel.swift     # Watchlist CRUD
│   ├── VerdictViewModel.swift       # Verdict detail logic
│   └── OnboardingViewModel.swift    # Onboarding state
│
├── Views/
│   ├── Onboarding/
│   │   ├── OnboardingView.swift     # 3-screen onboarding flow
│   │   └── OnboardingPageView.swift # Individual onboarding page
│   │
│   ├── Home/
│   │   ├── HomeView.swift           # Watchlist / main screen
│   │   ├── WatchlistCard.swift      # Product card with verdict badge
│   │   └── EmptyStateView.swift     # Empty watchlist state
│   │
│   ├── Search/
│   │   ├── SearchView.swift         # Search screen
│   │   ├── SearchResultCard.swift   # Quick result before full verdict
│   │   └── URLInputView.swift       # Paste URL input
│   │
│   ├── Verdict/
│   │   ├── VerdictDetailView.swift  # THE hero screen — full verdict
│   │   ├── VerdictBadge.swift       # 🟢🟡🔴 animated badge
│   │   ├── PriceComparisonView.swift # Retailer price list
│   │   ├── PriceChartView.swift     # Swift Charts price history
│   │   ├── LaunchAlertCard.swift    # Upcoming product launch card
│   │   ├── SaleEventCard.swift      # Next sale event card
│   │   └── ProInsightCard.swift     # Blurred Pro teaser
│   │
│   ├── Settings/
│   │   ├── SettingsView.swift       # Settings & account
│   │   └── ProUpgradeView.swift     # Pro subscription paywall
│   │
│   └── Components/
│       ├── ShimmerView.swift        # Loading skeleton animation
│       ├── GlassCard.swift          # Glassmorphism card component
│       ├── AnimatedGradient.swift   # Background gradient animation
│       └── HapticButton.swift       # Button with haptic feedback
│
├── Services/
│   ├── APIClient.swift              # Network layer — talks to our backend
│   ├── AuthService.swift            # Apple/Google Sign In
│   └── CacheService.swift           # Local caching layer
│
└── Utils/
    ├── Extensions.swift             # Color hex init, number formatting
    ├── Constants.swift              # API URLs, free tier limits, etc.
    └── Formatters.swift             # Currency formatting (₹1,15,900)
```

---

## 📱 Screen-by-Screen Specification

### Screen 1: Onboarding (first launch only)

3 pages with smooth horizontal paging. Each page has:
- Hero illustration/icon area (top 40%)
- Title (large, bold)
- Subtitle (2 lines, secondary text)
- Page indicator dots
- "Continue" button on last page

**Page 1:**
- Icon: Large 🟢🟡🔴 badges stacked with a subtle glow
- Title: "Should you buy it now?"
- Subtitle: "Savvit uses AI to analyze prices, sale events, and product launches to tell you the perfect time to buy."

**Page 2:**
- Icon: Search bar with sparkle ✨ animation
- Title: "Search any product"
- Subtitle: "Type a product name or paste an Amazon/Flipkart link. We'll find the best prices across all retailers."

**Page 3:**
- Icon: Phone with verdict card mockup
- Title: "Save thousands. Effortlessly."
- Subtitle: "Track up to 3 items for free. Get instant verdicts and never overpay again."
- Button: "Get Started" → navigates to Home

Store `hasSeenOnboarding` in UserDefaults/AppStorage.

### Screen 2: Home (Watchlist)

**Navigation**: Tab bar at bottom with 3 tabs:
- 🏠 Home (watchlist)
- 🔍 Search
- ⚙️ Settings

**Home screen layout:**

**If watchlist is empty:**
```
┌────────────────────────────────┐
│  Savvit                    👤  │
│                                │
│        [Illustration]          │
│                                │
│    Your watchlist is empty     │
│                                │
│  Search for a product to get   │
│  your first AI verdict         │
│                                │
│  [🔍 Search a Product]         │
│  [🔗 Paste a Link]             │
│                                │
│  [🏠]     [🔍]     [⚙️]       │
└────────────────────────────────┘
```

**If watchlist has items:**
```
┌────────────────────────────────┐
│  Savvit                    👤  │
│                                │
│  ┌────────────────────────┐   │
│  │ 🟡  iPhone 16 Pro      │   │
│  │     ₹1,15,900          │   │
│  │     Wait — new model    │   │
│  │     in 5 weeks          │   │
│  └────────────────────────┘   │
│                                │
│  ┌────────────────────────┐   │
│  │ 🟢  MacBook Air M3     │   │
│  │     ₹89,990             │   │
│  │     Near all-time low   │   │
│  └────────────────────────┘   │
│                                │
│         ＋ Add Item            │
│                                │
│  [🏠]     [🔍]     [⚙️]       │
└────────────────────────────────┘
```

**Watchlist card specs:**
- Rounded card (16pt radius) with `bgSecondary` background
- Left side: Verdict badge (colored circle with icon) — 🟢 checkmark, 🟡 clock, 🔴 X
- Product name: 17pt semibold
- Best price: 15pt regular, formatted as ₹1,15,900
- Short reason: 13pt, secondary text color
- Tap → navigates to VerdictDetailView
- Swipe left to delete (with confirmation)
- Cards appear with staggered animation on load

**Add Item FAB or button:**
- If < 3 items (free limit): "＋ Add Item" button
- If = 3 items: "＋ Add Item" → shows Pro upgrade prompt
- Button has subtle bounce animation

### Screen 3: Search

**Layout:**
```
┌────────────────────────────────┐
│  ← Search                      │
│                                │
│  ┌────────────────────────┐   │
│  │ 🔍 Search any product  │   │
│  └────────────────────────┘   │
│                                │
│  ─── OR ───                    │
│                                │
│  ┌────────────────────────┐   │
│  │ 🔗 Paste Amazon/Flipkart│  │
│  │    link                 │   │
│  └────────────────────────┘   │
│                                │
│  Recent searches:              │
│  iPhone 16 Pro                 │
│  MacBook Air M3                │
│  Samsung Galaxy S25            │
│                                │
│  [🏠]     [🔍]     [⚙️]       │
└────────────────────────────────┘
```

**Search flow:**
1. User types in search field
2. On submit → show full-screen loading state with shimmer animation
3. Call `POST /v1/products/search` with query
4. On response → animate to VerdictDetailView with the result
5. Save query to recent searches (UserDefaults, max 10)

**URL paste flow:**
1. Text field for URL
2. Detect Amazon/Flipkart URL pattern
3. Extract product name from URL or use as-is
4. Same flow as search

**Loading state:**
- Full screen takeover
- Animated shimmer cards (skeleton UI)
- "Finding the best prices..." text with animated dots
- Subtle pulsing Savvit logo
- Takes ~15 seconds — need to make this feel fast:
  - Show progress steps: "Checking retailers..." → "Analyzing prices..." → "Generating verdict..."

### Screen 4: Verdict Detail (THE HERO SCREEN)

This is the most important screen. It must be beautiful, informative, and make users go "wow."

**Layout (scrollable):**
```
┌────────────────────────────────┐
│  ← iPhone 16 Pro 256GB    ⋮   │
│                                │
│         ┌──────────┐           │
│         │  🟡 WAIT │           │
│         └──────────┘           │
│    90% confidence              │
│                                │
│  "Wait for iPhone 17 Pro       │
│   launch & upcoming sales"     │
│                                │
│  ═══════════════════════       │
│                                │
│  📍 IF YOU BUY NOW             │
│  ┌────────────────────────┐   │
│  │ ✅ Flipkart  ₹1,15,900│   │
│  │    SBI card + EMI       │   │
│  │ ── Amazon    ₹1,19,900 │   │
│  │ ── Croma     ₹1,21,990 │   │
│  └────────────────────────┘   │
│  [🛒 Buy on Flipkart]         │
│                                │
│  ⏳ IF YOU CAN WAIT            │
│  ┌────────────────────────┐   │
│  │ 📅 iPhone 17 Pro        │   │
│  │    Expected Sep 2026    │   │
│  │    Current model drops  │   │
│  │    15-25% after launch  │   │
│  │    Save: ₹25,000-30,000│   │
│  └────────────────────────┘   │
│                                │
│  ┌────────────────────────┐   │
│  │ 🏷️ Flipkart Big Saving │   │
│  │    May 2026             │   │
│  │    15-35% off typical   │   │
│  └────────────────────────┘   │
│                                │
│  ┌─ 🔒 PRO INSIGHT ──────┐   │
│  │ ░░░░░░░░░░░░░░░░░░░░ │   │
│  │ ░ Detailed savings    ░ │   │
│  │ ░ analysis + best     ░ │   │
│  │ ░ time to buy         ░ │   │
│  │ ░░░░░░░░░░░░░░░░░░░░ │   │
│  │  [Unlock Pro — ₹79/mo] │   │
│  └────────────────────────┘   │
│                                │
│  📈 PRICE HISTORY              │
│  [Swift Charts line graph]     │
│  All-time low: ₹99,900        │
│                                │
│  [➕ Add to Watchlist]          │
│                                │
└────────────────────────────────┘
```

**Verdict badge animation:**
- Starts small (0.5 scale) and invisible
- Springs to full size with overshoot (dampingFraction: 0.6)
- Background has a subtle radial gradient glow matching verdict color
- Badge pulses once subtly after appearing

**"If you buy now" section:**
- Retailer list sorted by price (lowest first)
- Best price row has ✅ checkmark and slightly bolder styling
- Each row shows: retailer name, price (₹ formatted), offers if any
- "Buy on [Retailer]" button → opens URL in Safari (affiliate link later)

**"If you can wait" section:**
- Launch alert card with gradient border (purple)
- Sale event card with gradient border (amber)
- Each shows: event name, expected date, historical discount, estimated savings

**Pro Insight card:**
- `.ultraThinMaterial` background
- Content is blurred (use `.blur(radius: 6)` on the text)
- Show just enough to tease: savings amount partially visible
- "Unlock Pro — ₹79/mo" button at bottom
- Subtle lock icon in corner

**Price history chart (Swift Charts):**
- Line chart with gradient fill below the line
- X-axis: dates, Y-axis: price in ₹
- Mark all-time low with a dot and annotation
- Mark current price with a dot
- If no Keepa data yet: show "Price history building... check back soon" placeholder

**Add to Watchlist button:**
- Sticky at bottom of scroll view
- Full-width, savvitPrimary color
- "➕ Add to Watchlist" if not in watchlist
- "✅ In Your Watchlist" (disabled, green) if already added
- Haptic feedback on tap
- If at 3-item limit: show Pro upgrade sheet

### Screen 5: Settings

```
┌────────────────────────────────┐
│  Settings                      │
│                                │
│  ┌────────────────────────┐   │
│  │ 👤 Sign In              │   │
│  │    Sign in to save your │   │
│  │    watchlist             │   │
│  │  [  Apple] [ Google]   │   │
│  └────────────────────────┘   │
│                                │
│  ┌────────────────────────┐   │
│  │ ⭐ Savvit Pro           │   │
│  │    Unlimited items,     │   │
│  │    full analysis, alerts│   │
│  │  [Upgrade — ₹79/mo]    │   │
│  └────────────────────────┘   │
│                                │
│  Preferences                   │
│  ├─ Appearance (Auto/Dark/Light)│
│  ├─ Notifications              │
│  └─ Currency (INR default)     │
│                                │
│  About                         │
│  ├─ Rate on App Store          │
│  ├─ Share Savvit               │
│  ├─ Privacy Policy             │
│  ├─ Terms of Service           │
│  └─ Version 1.0.0              │
│                                │
│  [🏠]     [🔍]     [⚙️]       │
└────────────────────────────────┘
```

### Screen 6: Pro Upgrade (Sheet)

Presented as a sheet/modal when user hits the paywall.

```
┌────────────────────────────────┐
│                            ✕   │
│                                │
│         ⭐ Savvit Pro          │
│                                │
│  ┌────────────────────────┐   │
│  │ ∞  Unlimited items     │   │
│  │ 📊 Full price analysis  │   │
│  │ 🔔 Price drop alerts   │   │
│  │ 📅 Sale predictions    │   │
│  │ 🚀 Launch intelligence │   │
│  │ 📈 Full price history  │   │
│  └────────────────────────┘   │
│                                │
│  ┌────────────────────────┐   │
│  │  ₹79/month             │   │
│  └────────────────────────┘   │
│  ┌────────────────────────┐   │
│  │  ₹499/year  SAVE 47%   │   │
│  └────────────────────────┘   │
│                                │
│  [Subscribe]                   │
│                                │
│  Restore Purchases             │
│  Terms · Privacy               │
└────────────────────────────────┘
```

---

## 🔌 API Client Implementation

```swift
// Services/APIClient.swift

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case watchlistLimit
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .networkError(let e): return e.localizedDescription
        case .decodingError: return "Failed to parse response"
        case .serverError(let msg): return msg
        case .watchlistLimit: return "Free plan allows 3 items"
        case .unauthorized: return "Please sign in"
        }
    }
}

@Observable
class APIClient {
    static let shared = APIClient()
    
    private let baseURL = "https://savvit-api.onrender.com"
    private var authToken: String?
    
    func setAuthToken(_ token: String?) {
        self.authToken = token
    }
    
    // MARK: - Product Search (no auth needed)
    func searchProduct(query: String) async throws -> ProductSearchResult {
        let url = URL(string: "\(baseURL)/v1/products/search")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["query": query])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }
        
        if httpResponse.statusCode != 200 {
            let errorBody = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(errorBody?.error ?? "Server error")
        }
        
        return try JSONDecoder().decode(ProductSearchResult.self, from: data)
    }
    
    // Add similar methods for watchlist CRUD and verdicts
}
```

---

## 📐 Key SwiftUI Patterns

### Currency Formatting
```swift
extension Int {
    var inrFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        // Indian grouping: ₹1,15,900
        formatter.locale = Locale(identifier: "en_IN")
        return formatter.string(from: NSNumber(value: self)) ?? "₹\(self)"
    }
}
```

### Color from Hex
```swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
```

### Verdict Badge Component
```swift
struct VerdictBadge: View {
    let verdict: String // "BUY_NOW", "WAIT", "DONT_BUY"
    let size: CGFloat
    
    var color: Color {
        switch verdict {
        case "BUY_NOW": return Theme.verdictBuy
        case "WAIT": return Theme.verdictWait
        case "DONT_BUY": return Theme.verdictDont
        default: return .gray
        }
    }
    
    var icon: String {
        switch verdict {
        case "BUY_NOW": return "checkmark.circle.fill"
        case "WAIT": return "clock.fill"
        case "DONT_BUY": return "xmark.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    var label: String {
        switch verdict {
        case "BUY_NOW": return "BUY NOW"
        case "WAIT": return "WAIT"
        case "DONT_BUY": return "DON'T BUY"
        default: return "ANALYZING"
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: size * 0.5, weight: .bold))
            Text(label)
                .font(.system(size: size * 0.4, weight: .heavy, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(color.gradient)
                .shadow(color: color.opacity(0.4), radius: 12, y: 4)
        )
    }
}
```

---

## ⚡ Implementation Order

Build in this exact order:

### Phase 1: Core (get it working)
1. `Theme.swift` — all colors, fonts, spacing constants
2. `Extensions.swift` — Color hex, currency formatting
3. `Constants.swift` — API URL, free tier limits
4. Models — `ProductSearchResult`, `PriceInfo`, `Verdict`, `LaunchIntel`
5. `APIClient.swift` — just the search endpoint
6. `SearchViewModel.swift` — search logic with loading states
7. `SearchView.swift` — basic search screen
8. `VerdictDetailView.swift` — display search results
9. `VerdictBadge.swift` — the 🟢🟡🔴 component
10. `ContentView.swift` — tab bar with Search tab
11. **TEST: Search → see verdict. If this works, the core is done.**

### Phase 2: Polish (make it beautiful)
12. `ShimmerView.swift` — loading skeleton animation
13. `GlassCard.swift` — reusable card component
14. `PriceComparisonView.swift` — retailer price list
15. `LaunchAlertCard.swift` — launch intelligence card
16. `SaleEventCard.swift` — upcoming sale card
17. `ProInsightCard.swift` — blurred Pro teaser
18. `HapticButton.swift` — button with haptic feedback
19. Add animations to VerdictDetailView (badge appear, staggered cards)
20. Loading state with progress steps

### Phase 3: Watchlist (persistence)
21. `WatchlistItem.swift` — SwiftData model
22. `WatchlistViewModel.swift` — CRUD logic
23. `HomeView.swift` — watchlist display
24. `WatchlistCard.swift` — product card for home
25. `EmptyStateView.swift` — empty watchlist
26. Add "Add to Watchlist" button on VerdictDetailView
27. Free tier limit check (3 items)

### Phase 4: Onboarding & Settings
28. `OnboardingView.swift` — 3-page onboarding
29. `SettingsView.swift` — basic settings
30. `ProUpgradeView.swift` — paywall (UI only, RevenueCat later)
31. `PriceChartView.swift` — Swift Charts (show when data available)

### Phase 5: Auth (add when needed)
32. `AuthService.swift` — Apple + Google Sign In
33. Wire auth token to APIClient
34. Sign-in prompt when adding 2nd watchlist item

---

## 🚫 What NOT to Build for MVP
- Barcode scanning
- Share extension
- Widgets
- Push notifications (needs APNs setup)
- Actual RevenueCat payment processing (just UI)
- iCloud sync
- Social features
- Product comparison (vs other products)

---

## ✅ Quality Checklist
- [ ] App works in dark mode AND light mode
- [ ] All text uses dynamic type (accessibility)
- [ ] Loading states have shimmer animations
- [ ] Error states show friendly messages with retry button
- [ ] Haptic feedback on all interactive elements
- [ ] Cards have smooth appear/disappear animations
- [ ] Currency is always formatted as ₹X,XX,XXX (Indian format)
- [ ] Verdict badge is always the visual hero
- [ ] Pro content is visibly blurred (not hidden)
- [ ] Tab bar highlights current tab
- [ ] Pull to refresh on watchlist
- [ ] Search field auto-focuses on appear
- [ ] Recent searches saved and displayed
- [ ] Back navigation works from every screen

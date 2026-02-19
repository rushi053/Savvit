# Savvit iOS Redesign — Cursor Prompt

## Reference
Inspired by Koval Bank (Behance: behance.net/gallery/244142595). Match that level of cleanliness, minimalism, and polish. Light-first, system dark mode support.

---

## Design System

### Colors — Light Mode (Primary)
```swift
// Backgrounds
static let bgPrimary = Color.white                          // #FFFFFF — main canvas
static let bgSecondary = Color(hex: "F5F5F5")              // #F5F5F5 — cards, inputs
static let bgTertiary = Color(hex: "EBEBEB")               // #EBEBEB — dividers, borders

// Brand Accent
static let savvitGreen = Color(hex: "C5FF00")              // #C5FF00 — CTAs, active states, badges
static let savvitGreenDark = Color(hex: "A8D900")          // #A8D900 — pressed state

// Verdict Colors
static let verdictBuy = Color(hex: "22C55E")               // #22C55E — 🟢 BUY NOW
static let verdictWait = Color(hex: "EAB308")              // #EAB308 — 🟡 WAIT
static let verdictDont = Color(hex: "EF4444")              // #EF4444 — 🔴 DON'T BUY

// Text
static let textPrimary = Color(hex: "1A1A1A")              // #1A1A1A — headlines, prices
static let textSecondary = Color(hex: "999999")            // #999999 — labels, captions
static let textTertiary = Color(hex: "C4C4C4")             // #C4C4C4 — placeholders, disabled
```

### Colors — Dark Mode (System Toggle)
```swift
static let bgPrimaryDark = Color(hex: "0A0A0A")            // #0A0A0A
static let bgSecondaryDark = Color(hex: "1A1A1A")          // #1A1A1A
static let bgTertiaryDark = Color(hex: "2A2A2A")           // #2A2A2A
static let textPrimaryDark = Color.white                     // #FFFFFF
static let textSecondaryDark = Color(hex: "9CA3AF")         // #9CA3AF
// savvitGreen stays the same — it works on both light and dark
// Verdict colors stay the same
```

### Typography — SF Pro (System Font)
```swift
// Use Apple's native text styles with custom sizing
static let heroText = Font.system(size: 34, weight: .bold)           // Verdict result
static let title1 = Font.system(size: 28, weight: .semibold)        // Product name
static let title2 = Font.system(size: 22, weight: .semibold)        // Section headers
static let title3 = Font.system(size: 20, weight: .medium)          // Card titles
static let body = Font.system(size: 17, weight: .regular)           // Content
static let bodyEmphasis = Font.system(size: 17, weight: .semibold)  // Prices, key data
static let caption = Font.system(size: 15, weight: .regular)        // Labels
static let footnote = Font.system(size: 13, weight: .regular)       // Fine print
```

### Spacing & Layout
```swift
static let spacingXS: CGFloat = 4
static let spacingSM: CGFloat = 8
static let spacingMD: CGFloat = 12
static let spacingLG: CGFloat = 16
static let spacingXL: CGFloat = 24
static let spacingXXL: CGFloat = 32

// Component specs
static let cornerRadius: CGFloat = 16        // Cards
static let cornerRadiusSM: CGFloat = 12      // Buttons, chips
static let cornerRadiusPill: CGFloat = 24    // Pills, CTAs
static let inputHeight: CGFloat = 56         // Search bar, inputs
static let buttonHeight: CGFloat = 50        // Primary CTAs
static let horizontalPadding: CGFloat = 16   // Screen margins
```

---

## Component Specs

### Cards
- Background: `bgSecondary` (#F5F5F5 light / #1A1A1A dark)
- Corner radius: 16pt
- NO border. NO shadow. NO glassmorphism. NO blur.
- Depth via background color difference only
- Internal padding: 16pt all sides
- Optional: 1px border in `bgTertiary` only if needed for contrast

### Primary CTA Button (Koval Style)
```swift
// Full-width lime green pill button
Text("Search")
    .font(.system(size: 17, weight: .semibold))
    .foregroundStyle(Color(hex: "1A1A1A"))       // Dark text on green
    .frame(maxWidth: .infinity)
    .frame(height: 50)
    .background(Color.savvitGreen)
    .clipShape(Capsule())
```

### Chip / Pill Tags
- Active: `savvitGreen` background, dark text
- Inactive: `bgSecondary` background, `textSecondary` text
- Corner radius: fully rounded (Capsule)
- Padding: 8pt vertical, 16pt horizontal
- Used for: filter chips, category tags, verdict badges

### Search Bar
```swift
HStack(spacing: 12) {
    Image(systemName: "magnifyingglass")
        .foregroundStyle(.textSecondary)
    TextField("Search or paste a product link...", text: $query)
        .font(.body)
}
.padding(.horizontal, 16)
.frame(height: 56)
.background(Color.bgSecondary)
.clipShape(RoundedRectangle(cornerRadius: 16))
```

---

## Screen Blueprints

### 1. Search Screen
Structure (top to bottom):
1. **Navigation title**: "Savvit" (large title, left-aligned, bold)
2. **Search bar**: 56pt height, `bgSecondary` background, rounded 16pt
   - Icon changes: 🔍 (text) → 🔗 (URL detected)
   - "Identifying product..." state with small spinner when resolving URL
3. **Suggestion chips** (if empty): "iPhone 16 Pro", "AirPods Pro", "MacBook Air" — `bgSecondary` pills
4. **Recent searches**: Simple list, clock icon + text + arrow, max 5 items
   - Swipe to delete
5. **Generous whitespace** — don't fill space for the sake of it

### 2. Loading Screen
1. **Centered icon**: `sparkle.magnifyingglass` in `savvitGreen`, pulsing
2. **Loading text**: Cycles through:
   - "Checking retailers..." (0s)
   - "Comparing prices..." (2s)
   - "Analyzing deals..." (4s)
   - "Generating verdict..." (6s)
3. **Shimmer cards**: 2-3 skeleton cards below, white gradient sweep on `bgSecondary`
4. Background: white, clean, no decoration

### 3. Verdict Screen (THE SIGNATURE SCREEN)
Structure (top to bottom, in ScrollView):

**A. Verdict Hero**
1. Verdict circle badge: 80pt diameter
   - Fill: verdict color gradient (e.g., green gradient for BUY)
   - Icon: SF Symbol inside (checkmark/clock/xmark), white, bold
   - Outer glow: verdict color at 15% opacity, blur 20pt
   - Animation: scale from 0.5→1.0, spring(0.4, 0.6)
   - Haptic: `.success` / `.warning` / `.error`
2. Verdict text: "BUY NOW" — 34pt Bold, verdict color
3. Confidence: "94% confidence" — 15pt, `textSecondary`, fade in with 0.2s delay
4. Short reason: "Best prices available now" — 20pt Medium, `textPrimary`, center-aligned

**B. Best Price CTA**
```
┌─────────────────────────────────┐
│  Buy on Flipkart     ₹1,15,900 │  ← savvitGreen background
│  Best price available           │     dark text, full width
└─────────────────────────────────┘
```
- Full width, `savvitGreen` background, Capsule shape, 56pt height
- Retailer name + price on one line
- "Best price available" subtitle below in smaller text
- Haptic `.medium` on tap

**C. Other Retailers**
- Clean list, NO cards. Just rows:
```
Amazon India        ₹1,19,900    →
Croma               ₹1,21,990    →
```
- Each row: retailer name (left, semibold) + price (right) + chevron
- Divider: thin 1px `bgTertiary` line
- Tapping opens retailer search URL

**D. If You Can Wait (conditional)**
- Section header: "IF YOU CAN WAIT" — 13pt, `textSecondary`, uppercase tracking
- Cards for launch intel and sale events:
  - `bgSecondary` background, 16pt corner radius
  - Icon + title + date + description
  - Small `verdictWait` accent on the icon

**E. Pro Insight (paywall)**
- Section header: "PRO INSIGHT" with 🔒 icon
- Show ONE teaser line unlocked: "Best time to buy: May 2026"
- Rest is a `bgSecondary` card with:
  - "Full analysis available in Pro"
  - `savvitGreen` "Unlock Pro — ₹79/mo" pill button
- NO blur. NO frosted glass. Clean lock icon + clear messaging.

**F. Add to Watchlist**
- Full width button at bottom:
  - If not in watchlist: `savvitGreen` pill, "Add to Watchlist"
  - If already in watchlist: outlined/`bgSecondary` pill, "✓ In Your Watchlist"

**G. Sources**
- Small footnote section: "Sources" header + 2-3 citation URLs as tappable links
- `textTertiary` color, 13pt

### 4. Watchlist Tab
- Tab bar icon: bookmark or list icon
- List of tracked products:
  - Each row: verdict color dot (small, 8pt) + product name + best price + retailer
  - Right chevron to navigate to full verdict
- Empty state: large gray icon + "Your watchlist is empty" + "Track products to get alerts" + "Browse Products" CTA

---

## Animation & Interaction Specs

### Spring Constants
```swift
static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.7)
static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
static let gentle = Animation.spring(response: 0.5, dampingFraction: 0.8)
```

### Haptic Map
| Interaction | Haptic |
|-------------|--------|
| Any button tap | `.light` |
| Primary CTA (buy link) | `.medium` |
| Add to watchlist | `.success` |
| Verdict reveal: BUY | `.success` |
| Verdict reveal: WAIT | `.warning` |
| Verdict reveal: DON'T BUY | `.error` |
| Search submit | `.medium` |
| Error state | `.error` |

### Verdict Screen Animation Sequence
```swift
// 1. Badge (0s) — spring bounce + haptic
withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
    showBadge = true
}
UINotificationFeedbackGenerator().notificationOccurred(.success)

// 2. Text (0.2s delay) — fade + slide up
withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
    showText = true
}

// 3. Content sections stagger (0.4s, 0.5s, 0.6s)
withAnimation(.easeOut(duration: 0.3).delay(0.4)) { showPrices = true }
withAnimation(.easeOut(duration: 0.3).delay(0.5)) { showWait = true }
withAnimation(.easeOut(duration: 0.3).delay(0.6)) { showPro = true }
```

### Transitions
- Screen push: default iOS navigation (slide left)
- Loading → Verdict: `.opacity` crossfade, 0.3s
- Bottom sheets: `.move(edge: .bottom)` with spring

---

## Anti-Slop Rules (CRITICAL)

1. ❌ NO generic gradients anywhere (except the verdict badge glow)
2. ❌ NO glassmorphism / blur effects on cards
3. ❌ NO dark purple or neon purple
4. ❌ NO excessive shadows
5. ❌ NO decorative elements that serve no purpose
6. ✅ Solid color backgrounds
7. ✅ Separation through spacing, not borders
8. ✅ One accent color: `#C5FF00` (savvitGreen)
9. ✅ Verdict colors are the ONLY other colors
10. ✅ White space = confidence, don't fill it
11. ✅ Support `@Environment(\.colorScheme)` for automatic light/dark

---

## Tab Bar (Koval-Style Floating)
```swift
// Floating tab bar with pill selection indicator
// 4 tabs: Search (magnifyingglass), Watchlist (bookmark), History (clock), Settings (gearshape)
// Active tab: savvitGreen icon + label + subtle pill background
// Inactive tabs: gray icons + labels
// Tab bar background: frosted material (.ultraThinMaterial)
// Corner radius: 24pt (pill shape)
// Floating with 8pt margin from edges
```

---

## Files to Rebuild
1. `Theme.swift` — Replace entire color/font system with above
2. `SearchView.swift` — Single search field, suggestion chips, recent searches
3. `VerdictDetailView.swift` — Complete rebuild per blueprint above
4. `VerdictBadge.swift` — New badge with glow + spring animation
5. `WatchlistView.swift` — Clean list with verdict dots
6. `ContentView.swift` — New tab bar (floating pill style)
7. `ShimmerView.swift` — Update colors for light mode

## Reference Images
Koval Bank Behance: https://www.behance.net/gallery/244142595/Koval-Bank-Finance-Mobile-app-UXUI
Key patterns: Clean white backgrounds, lime green (#C5FF00) accent, SF Pro typography, card-free layouts, generous whitespace, floating pill tab bar, one-task-per-screen philosophy.

# Savvit UX Redesign Spec — Apple Design Award Quality

## The Goal
Transform Savvit from "AI slop" to an Apple Design Award contender. The app should feel snappy, premium, and trustworthy.

---

## 1. What "AI Slop" Looks Like (And How to Avoid It)

**AI slop characteristics:**
- Generic rainbow gradients with no purpose
- Excessive blur/glassmorphism as decoration
- Smooth, physics-defying gradients that feel "uncanny"
- Generic card layouts copied from every other app
- Lack of human intention

**The Savvit anti-slop checklist:**
- [ ] Every gradient has a PURPOSE
- [ ] Every blur effect serves readability
- [ ] Every animation has MEANING
- [ ] Typography creates HIERARCHY

---

## 2. Color Palette — Navy + Blue (Not Purple)

| Token | Hex | Usage |
|-------|-----|-------|
| `bgPrimary` | `#0D1117` | Main background |
| `bgSecondary` | `#161B22` | Cards |
| `bgTertiary` | `#21262D` | Separators |
| `accentPrimary` | `#3B82F6` | Brand blue |
| `accentSuccess` | `#22C55E` | 🟢 BUY |
| `accentWarning` | `#EAB308` | 🟡 WAIT |
| `accentDanger` | `#EF4444` | 🔴 DON'T BUY |
| `textPrimary` | `#F0F6FC` | Headlines |
| `textSecondary` | `#8B949E` | Body |

Why navy + blue? Trust, finance, accessibility, differentiation from AI-purple apps.

---

## 3. Typography — SF Pro Only

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| Hero | 34pt | Bold | Verdict |
| Title1 | 28pt | Semibold | Product name |
| Title2 | 22pt | Semibold | Sections |
| Body | 17pt | Regular | Content |
| Caption | 15pt | Regular | Labels |

---

## 4. Verdict Screen — The Emotional Moment

### Animation Sequence
```swift
// 1. Badge appears with spring + haptic
withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
    showVerdict = true
}
// Haptic: .success/.warning/.error

// 2. Content staggers in
withAnimation(.easeOut.delay(0.2)) { showTitle = true }
withAnimation(.easeOut.delay(0.4)) { showPrices = true }
```

### Verdict Badge Spec
- 80pt circle
- Outer glow: color at 20% opacity, blur radius 24pt
- Main circle: gradient fill
- Icon: 32pt, white, bold weight
- Scale from 0.5 → 1.0 on appear

---

## 5. Micro-Interactions & Haptics

| Interaction | Haptic |
|-------------|--------|
| Button tap | `.light` |
| Primary CTA | `.medium` |
| Add to watchlist | `.success` |
| Verdict reveal | `.success`/`.warning`/`.error` |

### Animation Constants
```swift
static let snappy = .spring(response: 0.3, dampingFraction: 0.7)
static let bouncy = .spring(response: 0.4, dampingFraction: 0.6)
```

---

## 6. Cards & Layout

### Premium Card
```swift
.padding(16)
.background(
    RoundedRectangle(cornerRadius: 16)
        .fill(Color.bgSecondary)
        .stroke(Color.white.opacity(0.05), lineWidth: 1)
)
```

**Specs:**
- Corner radius: 16pt
- Padding: 16pt internal
- Gap between cards: 12pt
- Horizontal margins: 16pt

---

## 7. Pro Paywall — Progressive Disclosure

```
PRO INSIGHT

✅ Best time to buy: May 2026     ← Show teaser

🔒 Full analysis available in Pro  ← Lock indicator

[Unlock Pro — ₹79/mo]             ← CTA
```

---

## 8. Cursor Prompt for Full Redesign

```markdown
Redesign Savvit iOS app to Apple Design Award quality.

### Color System (REPLACE ALL PURPLE)
```swift
static let bgPrimary = Color(#"0D1117"")     // #0D1117
static let bgSecondary = Color(#"161B22"")   // #161B22  
static let bgTertiary = Color(#"21262D"")    // #21262D
static let accentPrimary = Color(#"3B82F6"") // #3B82F6 (brand blue)
static let accentSuccess = Color(#"22C55E"") // #22C55E (BUY)
static let accentWarning = Color(#"EAB308"") // #EAB308 (WAIT)
static let accentDanger = Color(#"EF4444"")  // #EF4444 (DONT BUY)
static let textPrimary = Color(#"F0F6FC"")   // #F0F6FC
static let textSecondary = Color(#"8B949E"") // #8B949E
```

### Typography (SF Pro ONLY)
- Hero/Verdict: 34pt Bold, SF Pro Display
- Product name: 28pt Semibold, SF Pro Display
- Sections: 22pt Semibold
- Body: 17pt Regular
- Captions: 15pt Regular

### Design Rules
1. NO generic gradients
2. NO glassmorphism blur
3. Solid color backgrounds
4. 1px white stroke on cards
5. Spring animations: dampingFraction 0.6-0.8
6. Haptic feedback on all interactions

### Verdict Screen Structure
1. Verdict badge (80pt, spring animation, haptic)
2. "BUY NOW/WAIT/DON'T BUY" (34pt Bold)
3. Confidence % (15pt, fade in after)
4. Short reason (22pt)
5. Best price CTA (full width, 56pt height, primary blue)
6. Other retailers (collapsible)
7. Wait section (if applicable)
8. Pro teaser (one unlocked insight + lock indicator + CTA)

### Animation Specs
- Badge: Scale 0.5→1.0, spring 0.4s
- Content: Stagger 0.1s between items
- Transitions: 0.3s easeOut

### Haptic Map
- Verdict reveal: `.success`/`.warning`/`.error`
- Button tap: `.light`
- Primary CTA: `.medium`
- Add watchlist: `.success`

Rebuild SearchView, VerdictDetailView, and WatchlistView with this system.
```

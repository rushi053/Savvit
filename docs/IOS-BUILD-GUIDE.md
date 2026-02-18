# Savvit iOS — Build Guide

---

## PART 1: Manual Setup (Rushi does this)

### Step 1: Create Xcode Project
1. Open **Xcode** (not Cursor yet)
2. File → New → Project
3. Select **iOS → App**
4. Settings:
   - Product Name: `Savvit`
   - Team: Your Apple Developer team
   - Organization Identifier: `app.savvit`
   - Bundle Identifier: `app.savvit.ios`
   - Interface: **SwiftUI**
   - Storage: **SwiftData**
   - Language: **Swift**
   - Testing: Include Tests ✅
5. Save to: `~/Desktop/savvit/ios/`
6. Build & Run once to make sure it compiles (blank app is fine)

### Step 2: Add to Git
```bash
cd ~/Desktop/savvit
git add ios/
git commit -m "Add Xcode project"
git push origin main
```

### Step 3: Open in Cursor
1. Open Cursor
2. File → Open Folder → `~/Desktop/savvit/ios/Savvit/`
3. You're ready to build with Claude

### Step 4: Add Dependencies (in Xcode first)
File → Add Package Dependencies:
- **RevenueCat**: `https://github.com/RevenueCat/purchases-ios` (add later when needed)
- **PostHog**: `https://github.com/PostHog/posthog-ios` (add later when needed)

No other external dependencies — we use all native frameworks.

---

## PART 2: Feed This to Cursor (The Entire iOS Spec)

Copy everything below this line and paste it as the initial prompt to Cursor/Claude when building.

---

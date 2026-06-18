# ReelFit

Capture workouts from Instagram reels and organize your whole fitness life:
reel-import → AI-structured workouts → categorized library → daily training log,
run planning, rep progress, nutrition/macros with AI meal suggestions, water,
supplements, body weight, and Apple Health steps.

This is a monorepo:

- **`ios/`** — SwiftUI iOS app (SwiftData) + a Share Extension.
- **`backend/`** — FastAPI service that reads the reel (yt-dlp) and uses Claude
  to turn it into a structured workout, plus food search & meal suggestions.

## Status

Built in phases. **Phase 0 (scaffold) + the Phase 1 reel-import flow are in.**
See the phase tracker / `ios` source for what's stubbed vs. live.

| Pillar | State |
|---|---|
| Reel import → AI workout → categorized library | ✅ working |
| Daily training log (pick a saved workout, edit sets) | ✅ working |
| Run planner, progress charts | ✅ working |
| Nutrition: macro rings, meal log, food search, AI meal ideas | ✅ working |
| Water, supplements, weight trend, steps | ✅ working |
| Today dashboard (rings, steps, water, supplements, weight) | ✅ working |
| iCloud sync | ⏳ Phase 5 (one-line toggle, needs paid Apple account) |

## 1. Run the backend

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env          # add your ANTHROPIC_API_KEY (optional but recommended)
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- Without an `ANTHROPIC_API_KEY` the backend still works using a simple
  caption parser (lower quality). Add the key for real AI extraction.
- Find your Mac's LAN IP (`ipconfig getifaddr en0`) — the phone uses
  `http://<that-ip>:8000`.
- Tests: `python -m pytest`

## 2. Build the iOS app

The project is defined with **XcodeGen** (no committed `.xcodeproj`).

```bash
brew install xcodegen
cd ios
xcodegen generate
open ReelFit.xcodeproj
```

In Xcode:
1. Select both targets → **Signing & Capabilities** → choose your Team.
2. Build & run on a real iPhone (the Share Extension and HealthKit need a
   device).
3. In the app, open the **Me** tab and set the **Backend** URL to
   `http://<your-mac-ip>:8000`.

> Requirements: Xcode 16+, iOS 17+. App Groups (share hand-off), HealthKit, and
> CloudKit need a paid Apple Developer account. On a free account you can still
> run the app and import reels via the **+** button (paste a link) — the
> share-from-Instagram hand-off needs the App Group entitlement.

## 3. Use it

- In Instagram, share a reel → **Save to ReelFit**. Open ReelFit → the reel
  appears under **Workouts → Shared from Instagram** → tap to import.
- Or tap **+** in Workouts and paste a reel link.
- If a reel can't be read automatically, the app asks you to paste the caption.

## Caveats

- Reel reading via yt-dlp is unofficial and can break when Instagram changes;
  the caption-paste fallback always works.
- USDA food data is US/generic; branded items may be approximate.

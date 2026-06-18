# ReelFit — Known Limitations & Caveats

Last updated: 2026-06-18. Keep this in mind when using or extending the app.

## Instagram reel extraction
- **Unofficial / fragile.** There is no public Instagram API for reading
  arbitrary reels. Extraction uses `yt-dlp` to read the public page, which
  **violates Instagram's ToS** and **breaks whenever Instagram changes** its
  site. Treat it as best-effort.
- **Caption first, audio transcription as fallback.** Most workout reels put
  the routine in the caption. For caption-less reels, the backend can download
  the audio and transcribe it (faster-whisper) before falling back to manual
  paste. Transcription is **optional/heavy** (`pip install -r
  requirements-transcription.txt`), runs on CPU, and is **not runtime-tested in
  this build** — quality depends on the Whisper model size and audio clarity.
- **Always-available fallback:** if auto-read fails, the app asks you to paste
  the caption manually, so you can always save a workout.
- **AI quality needs a key.** Good structuring (form cues, sets/reps,
  category) requires `ANTHROPIC_API_KEY` on the backend. Without it, a simple
  line-by-line heuristic parser runs (lower quality).

## Backend
- **Must be running and reachable.** The app talks to the FastAPI backend for
  reel extraction, food search, and meal ideas. Running it locally on your Mac
  means the phone only reaches it on the **same network** (or via Tailscale).
  For always-on use, deploy it (Fly.io/Render). Reel import and meal AI do
  nothing if the backend URL isn't set or is unreachable.

## Apple / signing
- **Paid Apple Developer Program ($99/yr) needed for:**
  - the **Share-from-Instagram** hand-off (App Group entitlement),
  - **iCloud (CloudKit) sync**.
- On a **free** account you can still run the app, import reels via the **+**
  button (paste a link), and use everything locally.
- **HealthKit/steps** require a **real iPhone** (the simulator has little/no
  health data) and the user granting permission.

## Data accuracy
- **Nutrition** comes from the **USDA** database — US/generic foods. Branded and
  restaurant items may be missing or approximate. Quantities default to 1
  serving (no portion editing yet).
- **AI meal suggestions** are estimates, not precise nutrition facts.

## Runs / wearables
- **Strava import is built.** Your Coros runs auto-export to Strava; ReelFit
  connects to Strava (OAuth) and imports runs into the Train tab alongside gym
  workouts. Caveats:
  - Requires a **Strava API app** (free) with **Authorization Callback Domain =
    `reelfit.app`**, and `STRAVA_CLIENT_ID`/`STRAVA_CLIENT_SECRET` in the backend
    `.env`.
  - Each sync pulls your **most recent 50 activities** and adds new runs (deduped
    by Strava activity id). Older history isn't back-filled yet; pagination can be
    added if you want full history.
  - Only activities Strava types as a **run** are imported.
  - Strava API has **rate limits** (200 requests/15 min, 2000/day) — fine for
    personal use.
- Manual run planning/logging still works without Strava.
- Apple Health is **not** used for runs (you chose Strava as the source).

## General
- Compilation is verified (Xcode 16.2, iOS 17); **runtime behavior on a device
  has not been exhaustively tested** — expect minor UI tweaks on first run.
- **No editing of imported workouts yet** (rename / recategorize / tweak
  sets/reps) — planned.
- **iCloud sync** requires manually adding the CloudKit capability in Xcode
  (see README) before the in-app toggle does anything.

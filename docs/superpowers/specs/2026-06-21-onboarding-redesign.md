# Onboarding Redesign

**Date:** 2026-06-21
**Status:** Approved

## Overview

Redesign onboarding to 4 pages (language → theme → running defaults → notifications + permissions). Extract the welcome/loading animation into a standalone `LaunchScreen` shown on every cold start. The existing onboarding page 1 (cat + tagline) becomes the permanent launch screen.

---

## Launch Screen (new — `LaunchScreenView`)

Shown on every app cold start, **before** `ContentView` decides whether to show onboarding or the main tab. Visible for ~0.8 s, then fades to `ContentView`.

- Full-screen `theme.bg`
- `LottieCharacterView(characterId: "loader_cat", bpm: 180, isAnimating: true)` centred, 120×88 pt
- App name `Niko Neko` in weight 200, 32 pt below cat
- Tagline `slow jog · smile pace` in 13 pt `textDim`
- After 0.8 s: `.opacity` transition out → `ContentView` loads

`JogApp.swift` shows `LaunchScreenView` first; on completion it switches to `ContentView`.

---

## Page Structure

| # | Page | Key interaction |
|---|------|----------------|
| 1 | Language | English / 繁體中文 (existing design, unchanged) |
| 2 | Theme | Half-carousel with colour-band cards, full-page live preview |
| 3 | Running defaults | BPM slider (cat speed feedback) + goal duration +/- + sound picker |
| 4 | Notifications + Permissions | Toggle → system prompt → time picker; HealthKit + Motion same page |

Progress bar spans all 4 pages (`page + 1 / 4`).

---

## Page 2 — Theme

### Layout
- Top: Lottie cat animation (`loader_cat`), rendered in `accentMid` of the currently selected theme, centred
- Below cat: half-carousel (5 visible cards)
- Bottom: 15-dot page indicator

### Carousel
- **5 slots**: far-left, left, centre, right, far-right
- Centre card: full size, white ring outline
- Adjacent cards: ~84% scale, 55% opacity
- Far cards: ~72% scale, 25% opacity
- Tap left/right cards to advance; swipe gesture also works
- Dot strip below: active dot is wider (14 pt) in `accent` colour; tapping any dot jumps directly

### Card design
- Background: theme `bg`
- Bottom strip: 5-colour bar (`bar[0..4]`), height 9 pt (centre) / 7 pt (side)
- Theme name: centred, 8 pt, theme `text` colour

### Live preview on selection
Every theme switch instantly updates:
- Page background → `bg`
- Progress bar fill → `accent`
- Progress bar track → `accentDim`
- All text (label, title, subtitle, hint) → `text`
- Cat Lottie colour → `accentMid`
- CTA button background → `accent`
- Saves `profile.activeThemeId` and calls `themeManager.apply(id)`

### Copy
- Title: `your vibe.` (weight 200)
- Subtitle: `pick a colour to run with`
- CTA: `next →`

---

## Page 3 — Running Defaults

### Layout (top to bottom)
1. BPM section
2. Daily goal section
3. Sound section
4. CTA button

### BPM Slider
- Range: 140–220, default: `profile.defaultBPM` (fallback 180)
- Full-width slider with custom thumb; current value displayed above in large ultralight numeral
- While dragging: Lottie cat animation speed = `bpm / 180.0` (updates in real time)
- On drag end: saves `profile.defaultBPM`
- Label: `beats per minute` (small, all-caps, `textDim`)

### Daily Goal
- `−` / large numeral / `+` buttons
- Step: 5 min, range: 5–120 min, default: `profile.dailyGoalMinutes` (fallback 20)
- Saves `profile.dailyGoalMinutes` and `profile.defaultDuration` on change
- Label: `daily goal` + `min` unit suffix

### Sound Picker
- Three segments: `Wood Lo` / `Wood` / `Wood Hi`
- Matches existing `SoundType` enum (`.woodLo` / `.wood` / `.woodHi`)
- Tapping a segment plays a single preview beat via `MetronomeService` (or a short `AVAudioPlayer` one-shot)
- Saves `profile.soundType`
- Label: `metronome sound` (small, all-caps, `textDim`)

### Copy
- Title: `set your pace.`
- CTA: `next →`

---

## Page 4 — Notifications + Permissions

### Notification section (top)
- Row: bell icon + `daily reminder` label + Toggle (`notifEnabled`)
- Toggle on → immediately call `NotificationService.requestPermission()`
  - Granted: show `DatePicker` (wheel, hour + minute) below the row with a divider; save hour/minute to profile on change
  - Denied: show inline note `enable in Settings` (small, `textDim`); toggle snaps back to off
- Toggle off: collapse time picker, mark notification as skipped

### Permissions section (below notification)
- Section label: `app permissions`
- Rows: HealthKit (`heart` icon) and Motion (`figure.walk` icon)
- Each row: icon + name + description + status badge (pending / ✓ granted / denied in orange)
- Single `Allow` button appears if any permission is still pending; taps `requestAllPermissions()`
- Notification row also appears here (same status badge logic) — reads from `notifStatus` already set above; if notification was skipped, shows `skipped` badge

### CTA
- Label: `start running` (replaces generic "next")
- Always enabled; taps `finish()`
- `finish()` sets `UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")` then calls `onDismiss()`

### Copy
- Title: `stay on track.`
- Subtitle: `we'll remind you` (only visible when notification toggle is on)

---

## Data Saved Across All Pages

| Field | Page | Default |
|-------|------|---------|
| `profile.language` | 1 | `.english` |
| `profile.activeThemeId` | 2 | `"moss"` |
| `profile.defaultBPM` | 3 | `180` |
| `profile.dailyGoalMinutes` | 3 | `20` |
| `profile.defaultDuration` | 3 | same as dailyGoalMinutes |
| `profile.soundType` | 3 | `.wood` |
| `profile.notificationsEnabled` | 4 | `false` |
| `profile.notificationHour` | 4 | `7` |
| `profile.notificationMinute` | 4 | `0` |

All saves via `try? ctx.save()` immediately on change (no deferred commit).

---

## Shared Components (unchanged)

- `progressBar` — updated to 4 pages
- `nextButton(label:enabled:action:)` — reused on all pages
- `permRow(icon:name:desc:status:)` — reused on page 4
- `requestAllPermissions()` — page 4 unchanged
- `LottieCharacterView` — used in LaunchScreenView and pages 2, 3

---

## Out of Scope

- Character picker (remains in Timer tab)
- iCloud sync toggle (remains in Settings)
- Height / weight (remains in Settings)
- HealthKit write permission (already handled at first run)

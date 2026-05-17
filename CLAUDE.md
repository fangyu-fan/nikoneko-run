# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**NIKO NEKO** (慢跑貓貓) — a slow jogging iOS app. Tagline: *slow jog · smile pace*.
App Store name: `Niko Neko`. In-app brand name not displayed — icon-only identity.

The app does one thing: help users slow jog every day. Nothing is added for the sake of it.

---

## Tech Stack

- **Platform:** iOS, Swift / SwiftUI / SwiftData
- **Architecture:** MVVM + Service Layer
- **Animation:** Lottie (character silhouettes)
- **Persistence:** SwiftData (CloudKit optional), App Group UserDefaults for widget data sharing
- **Audio:** AVAudioEngine (metronome, sub-millisecond scheduling)
- **Health:** HealthKit (HR read from Watch, workout write), CoreBluetooth (BLE HR fallback), CoreMotion (steps/distance)
- **Extensions:** WidgetKit (4 widget types), ActivityKit (Dynamic Island + Lock Screen Live Activity)

---

## Project Structure (planned)

```
nikoneko/
├── App/                    NikoNekoApp.swift, AppDelegate
├── Core/
│   ├── Theme/              ThemeManager.swift, ThemeTokens.swift
│   ├── Models/             RunSession, UserProfile, ThresholdConfig (SwiftData @Model)
│   └── Extensions/
├── Features/
│   ├── Timer/              TimerView + ViewModel, DrumPickerView, CharacterPickerView, BPMPanelView
│   ├── Report/             ReportView + ViewModel, BarChartView, SessionDetailView
│   ├── Summary/            SummaryView + ViewModel
│   └── Settings/           6 sub-pages: Appearance, Display, Defaults, Widget, Notifications, DataSync
├── Services/               MetronomeService, HeartRateService, MotionService, LiveActivityService, HealthKitService
├── Widgets/                NikoNekoWidgetBundle + 4 widget types + WidgetSharedData
├── LiveActivity/           NikoNekoLiveActivityAttributes, NikoNekoLiveActivityView
├── Characters/             CharacterDefinition + Lottie JSON files
└── Resources/              Localizable.strings (en + zh-Hant)
```

App Group: `group.com.fangyu.nikoneko` — shared between main app and widget extension.

---

## Architecture Decisions

### Theme System
All colors are resolved from `ThemeTokens` — **never hardcode hex values in components**. Tokens: `bg`, `surface`, `card`, `text`, `textDim`, `textMid`, `accent`, `accentMid`, `accentDim`, `bar[0..4]`, `cal[0..4]`. The character silhouette fill uses `accentMid`. The 5-stop bar/heatmap ramp (`bar[0]`=empty → `bar[4]`=peak) drives all charts and widgets. 14 themes defined in `ThemeLibrary`. Theme change is immediate — no cross-fade.

### Data Flow (Widgets)
Main app writes `[DaySessionSummary]` (last ~400 sessions) to App Group UserDefaults as JSON after every session save and on theme change. Widget providers read from App Group only — they never touch SwiftData directly. After any session save or theme change, call `WidgetCenter.shared.reloadAllTimelines()`.

### Timer State
`TimerViewModel.State`: `.idle` → `.running` ↔ `.paused` → `.idle`. Stop requires a 2-second long-press (arc fills as feedback; release early cancels). Double-tap toggles pause/resume during a run. Countdown vs stopwatch is a Settings preference, not a toggle on the timer screen.

### Heart Rate Priority
1. Apple Watch via `HKAnchoredObjectQuery` (live updates)
2. BLE monitor (CoreBluetooth, service `0x180D`, characteristic `0x2A37`)
3. Hidden — HR row not shown if no source detected

### Metronome
`AVAudioEngine` + `AVAudioPlayerNode` with `mach_absolute_time` scheduling. BPM range: 140–220. Character animation speed = `BPM / 180.0` (Lottie `animationSpeed`, normalized to 180 BPM baseline). Sound options: tap / bell / drum / wood (WAV files).

### iCloud Sync
Controlled by `UserProfile.iCloudEnabled`. When on: `ModelConfiguration(cloudKitDatabase: .automatic)`. When off: standard local config. Switched at app launch — requires container rebuild.

---

## Screens

| Screen | Tab | Notes |
|--------|-----|-------|
| Timer | 1 | Drum-roll picker when idle; large ultralight numeral when running |
| Report | 2 | Day/Week/Month/Year; hero = always duration; tappable metric cards switch chart |
| Settings | 3 | 6 push-navigation sub-pages |
| Summary | — | Full-screen overlay after run ends; auto-shown |
| Character Picker | — | Sheet from Timer tab |
| BPM Panel | — | Floating popover from `♩ BPM` row |

---

## Widgets

| Widget | Size | Key data |
|--------|------|----------|
| Streak | Small | Consecutive days |
| Total Time | Small | Cumulative hours |
| Year Heatmap | Medium | 18×7 grid, `bar[0..4]` color scale |
| Month Calendar | Large | 7×5-6 grid, per-cell: duration / HR / completion% |

Heatmap thresholds T1/T2/T3 are configurable per widget instance via `WidgetConfigurationIntent`. Widget timeline refreshes hourly.

---

## Design Rules (enforce in code)

- **Typography:** SF Pro only. Timer numeral: weight 200, 68–72 pt, letter-spacing −3 pt. All-caps labels: +0.04em. Tabular figures on all numerals.
- **Spacing base unit:** 4 pt. Content padding: 16 pt horizontal.
- **No decorative color.** Color encodes meaning only.
- **No bold below 11 pt.**
- **Transitions:** Standard iOS push/sheet — no custom transitions (accessibility). Report bars animate with `.easeInOut(duration: 0.25)`. Long-press arc: `.linear(duration: 2.0)`.
- **Icons:** SF Symbols (outline style) throughout. Fallback text glyphs for tight spaces: ♥ ⊙ △ ⊞ ♩ ♪ ♫.
- **Dynamic Island:** No heart rate shown (keep uncluttered). Character animation left; time right.

---

## Localization

Two locales: `en` and `zh-Hant`. Runtime switching without app restart via custom `Bundle` subclass overriding `Bundle.main`. Language stored in `UserProfile.language`. All string keys use dot-notation (e.g. `"report.metric.duration"`).

---

## Copy Voice

Short. Present tense. Direct. No exclamation marks. No emoji in UI copy. Numbers without decoration (`12 days`, `21 min`). Errors are direct, solution-focused (`"Couldn't save. Try again."` not `"Sorry, something went wrong"`).

---

## Characters

7 silhouettes. Free: `cat_a`, `cat_b`, `human`, `pushup`. Streak-locked: `situp` (7d), `jumprope` (14d), `parrot` (30d). All rendered as Lottie with runtime color override to `accentMid`. Never static in motion contexts.

---

## Testing Checklist (from spec)

**Unit:** `ThemeLibrary` all 14 themes have exactly 5 `bar` + 5 `cal` entries · `barColor` boundary conditions · calorie estimation · `ReportViewModel` duration aggregation · `DaySessionSummary` encode/decode round-trip.

**Integration:** Session save → App Group write → Widget reads updated data · Theme change → `WidgetCenter.reloadAllTimelines()` called.

**Manual QA:** Long-press arc timing · BPM panel ±1/±5 clamps to 140–220 · Drum picker ghost numerals · Dynamic Island compact + expanded · Lock Screen Live Activity · All 14 themes (no hardcoded colors) · Language switch without restart · Widget threshold slider enforces minimum gap between T1/T2/T3.

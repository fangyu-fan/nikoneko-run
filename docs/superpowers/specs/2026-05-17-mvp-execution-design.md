# NIKO NEKO — MVP Execution Design

**Date:** 2026-05-17  
**Status:** Approved  
**Author:** Project Lead (Claude Code)

---

## 1. Architecture Decisions

### 1.1 Backend
**Decision: No backend. Local-only + CloudKit.**

- All run data stored in SwiftData on-device
- Cross-device sync via CloudKit (user's existing Apple ID, no login required)
- Widget data shared via App Group UserDefaults
- No server, no auth system, no accounts

Rationale: No feature requires server-side logic. Adding a backend would contradict the brand philosophy (zero friction, open and run).

### 1.2 Assets Strategy — Placeholder First
**Decision: Programmatic placeholders, real assets slotted in later.**

**Animation:**
- Ship with SwiftUI `Canvas`-drawn geometric cat silhouette as placeholder
- `CharacterView` protocol wraps both placeholder and future `LottieView`
- Switching to real Lottie JSON requires only dropping files into `Characters/Lottie/` — no architecture change

**Sound:**
- `AVAudioEngine` synthesizes a simple sine-wave click burst as placeholder per `SoundType`
- Same `MetronomeService` interface loads WAV from Bundle when present, falls back to synthesis
- Real WAV files slot in by name: `tap.wav`, `bell.wav`, `drum.wav`, `wood.wav`

This ensures no sub-agent is blocked waiting for assets.

### 1.3 No Login System
App uses iCloud sync transparently via the user's Apple ID. No login, register, or session management in the app.

### 1.4 Automation
```
Local: make test   → xcodebuild test + SwiftLint
CI:    Fastlane    → build + sign + upload to TestFlight (on main branch)
Store: Manual trigger for App Store submission
```

---

## 2. Execution Strategy: Loose Parallel + Interface Contracts

Wave 0 runs sequentially and publishes Swift `protocol` / `struct` interfaces.  
All subsequent agents depend on these contracts — not the implementations — so Wave 1+ can start immediately.

**Interface contracts published by Wave 0:**
- `ThemeTokens` struct (all color tokens)
- `ThemeManager` observable class
- `RunSession`, `UserProfile`, `ThresholdConfig` SwiftData models
- `AppGroupDefaults` namespace
- `CharacterView` protocol

---

## 3. Wave Architecture

```
Wave 0 (Sequential)
└── F-01  Xcode project shell, App Group, Capabilities
└── F-02  ThemeTokens + ThemeLibrary (14 themes) + ThemeManager
└── F-03  SwiftData models + ModelContainer + AppGroupDefaults

    ↓ publishes interface contracts

Wave 1 (Fully parallel — all start simultaneously)
├── T-01  TimerView + TimerViewModel (state machine)
├── T-02  DrumPickerView (drum-roll gesture)
├── T-03  CharacterPickerView + BPMPanelView
├── M-01  MetronomeService (AVAudioEngine, placeholder synthesis)
├── M-02  CharacterView protocol + placeholder Canvas animation + BPM sync
├── H-01  HeartRateService (HealthKit HKAnchoredObjectQuery)
├── H-02  BLEHeartRateManager (CoreBluetooth fallback)
├── D-01  MotionService (CMPedometer)
├── S-01  SettingsView (6 sub-pages)
└── S-02  UserProfile persistence + App Group write bridge

    ↓ each Wave 2 task unlocks when its deps complete

Wave 2 (Parallel, dep-gated)
├── R-01  ReportView + ReportViewModel          ← needs S-02
├── R-02  BarChartView (5-stop ramp)            ← needs F-02, R-01
├── R-03  SessionDetailView + Log List          ← needs R-01
├── U-01  SummaryView + SummaryViewModel        ← needs T-01, M-01, H-01, D-01
├── U-02  ShareCardView (ImageRenderer)         ← needs U-01, F-02
├── W-01  StreakWidget + TotalTimeWidget         ← needs S-02
├── W-02  HeatmapWidget (Medium, 18×7)          ← needs S-02
├── W-03  CalendarWidget (Large, month grid)    ← needs S-02
├── W-04  WidgetConfigurationIntent + thresholds← needs W-01, W-02, W-03
├── L-01  LiveActivityService + Attributes      ← needs T-01
├── L-02  DynamicIslandView (compact+expanded)  ← needs L-01, M-02
└── L-03  LockScreenLiveActivityView            ← needs L-01

    ↓ Wave 3 unlocks when all screens exist

Wave 3 (Parallel, final layer)
├── I-01  Localizable.strings en + zh-Hant      ← needs all screens
├── I-02  LanguageManager (runtime switch)      ← needs I-01
├── K-01  HealthKitService write                ← needs H-01, S-02
├── K-02  iCloud sync (CloudKit config)         ← needs F-03, S-02
├── N-01  NotificationService (daily reminder)  ← needs S-01
├── Q-01  Unit Tests                            ← needs all
├── Q-02  Integration Tests                     ← needs W-01, W-02, W-03
└── Q-03  Manual QA sweep                       ← needs all
```

---

## 4. Full Task List (30 tasks)

### Wave 0 — Foundation

| ID | Task | Output Files |
|----|------|-------------|
| F-01 | Xcode project shell: folder structure, App Group `group.com.fangyu.nikoneko`, Capabilities (HealthKit, Background Modes, Push, App Groups), Makefile, Fastlane stub | `nikoneko.xcodeproj`, `Makefile`, `Fastfile` |
| F-02 | `ThemeTokens` struct, `ThemeLibrary` (all 14 themes with 5-stop bar/cal ramps), `ThemeManager` @Observable class, `Color(hex:)` extension | `Core/Theme/ThemeTokens.swift`, `Core/Theme/ThemeLibrary.swift`, `Core/Theme/ThemeManager.swift` |
| F-03 | SwiftData `@Model` classes (RunSession, UserProfile, ThresholdConfig), `ModelContainer` setup in `NikoNekoApp`, `AppGroupDefaults` write/read helpers, `DaySessionSummary` Codable struct | `Core/Models/*.swift`, `Core/AppGroupDefaults.swift` |

### Wave 1 — Core Services & Screens

| ID | Task | Dependencies | Output Files |
|----|------|-------------|-------------|
| T-01 | `TimerView` + `TimerViewModel` (idle/running/paused state machine, long-press 2s stop arc, double-tap pause, countdown auto-stop, session save call) | F-01, F-02, F-03 | `Features/Timer/TimerView.swift`, `TimerViewModel.swift` |
| T-02 | `DrumPickerView` (drag gesture, ghost numerals, plain-minutes + HH:MM modes, step=28pt) | F-02 | `Features/Timer/DrumPickerView.swift` |
| T-03 | `CharacterPickerView` (sheet, 7 slots, streak-lock UI), `BPMPanelView` (floating popover, ±1/±5 buttons, 140–220 clamp) | F-02 | `Features/Timer/CharacterPickerView.swift`, `BPMPanelView.swift` |
| M-01 | `MetronomeService` (AVAudioEngine, mach_absolute_time scheduling, 4 SoundTypes, placeholder sine synthesis, WAV fallback from Bundle, volume control) | F-01 | `Services/MetronomeService.swift`, `Resources/Sounds/` stub |
| M-02 | `CharacterView` protocol, `PlaceholderCharacterView` (SwiftUI Canvas geometric cat silhouette, 4-frame loop simulation), `LottieCharacterView` stub, BPM speed sync | F-02, M-01 | `Characters/CharacterView.swift`, `Characters/PlaceholderCharacterView.swift`, `Characters/LottieCharacterView.swift` |
| H-01 | `HeartRateService` (HKAnchoredObjectQuery live updates, sample averaging, maxHR tracking, source enum: watch/ble/none) | F-01, F-03 | `Services/HeartRateService.swift` |
| H-02 | `BLEHeartRateManager` (CBCentralManager, service 0x180D, characteristic 0x2A37, flag-byte parsing, integrates with HeartRateService) | H-01 | `Services/BLEHeartRateManager.swift` |
| D-01 | `MotionService` (CMPedometer updates, steps/distance/avgCadence, calorie estimation via MET formula, weight from UserProfile) | F-01, F-03 | `Services/MotionService.swift` |
| S-01 | `SettingsView` + all 6 sub-pages (Appearance/Display/Defaults/Widget/Notifications/DataSync), all bindings to UserProfile | F-02, F-03 | `Features/Settings/*.swift` |
| S-02 | `UserProfile` persistence helpers, App Group write on every relevant change (themeId, goalMinutes, sessionSummaries), `WidgetCenter.shared.reloadAllTimelines()` triggers | F-03 | extends `Core/AppGroupDefaults.swift` |

### Wave 2 — Secondary Screens & Extensions

| ID | Task | Dependencies | Output Files |
|----|------|-------------|-------------|
| R-01 | `ReportView` + `ReportViewModel` (Day/Week/Month/Year period tabs, date range navigation, hero duration, metric card tap switches chart, log list) | S-02 | `Features/Report/ReportView.swift`, `ReportViewModel.swift` |
| R-02 | `BarChartView` (equal-width bars, 5-stop theme color ramp, 2pt top radius, min-height 2pt, animated on data change `.easeInOut(0.25)`, axis labels) | F-02, R-01 | `Features/Report/BarChartView.swift` |
| R-03 | `SessionDetailView` (full metric breakdown, mini HR distribution bar chart bucketed by 10 bpm), `LogRow` component | R-01 | `Features/Report/SessionDetailView.swift` |
| U-01 | `SummaryView` + `SummaryViewModel` (streakDays calc, thisWeekDots, "Done" dismissal, session data display) | T-01, M-01, H-01, D-01 | `Features/Summary/SummaryView.swift`, `SummaryViewModel.swift` |
| U-02 | `ShareCardView` (theme-colored minimal card), `ImageRenderer` integration in SummaryViewModel, share sheet | U-01, F-02 | `Features/Summary/ShareCardView.swift` |
| W-01 | `StreakWidget` (Small, streak count), `TotalTimeWidget` (Small, cumulative hours), both using App Group data + theme colors | S-02 | `Widgets/StreakWidget.swift`, `TotalTimeWidget.swift` |
| W-02 | `HeatmapWidget` (Medium, 18×7 grid, 5-stop bar ramp, optional stats row chips) | S-02 | `Widgets/HeatmapWidget.swift` |
| W-03 | `CalendarWidget` (Large, 7×5-6 month grid, per-cell color + day number + metric value, today ring) | S-02 | `Widgets/CalendarWidget.swift` |
| W-04 | `NikoNekoWidgetConfigIntent` (WidgetConfigurationIntent with all @Parameters), `barColor(for:theme:t1:t2:t3:)` helper, enforce T1<T2<T3 minimum gap | W-01, W-02, W-03 | `Widgets/WidgetSharedData.swift`, `NikoNekoWidgetBundle.swift` |
| L-01 | `LiveActivityService` (start/update/end), `NikoNekoLiveActivityAttributes` + `ContentState` (elapsed, remaining, bpm, characterId, themeId, isCountdown) | T-01 | `LiveActivity/NikoNekoLiveActivityAttributes.swift`, `Services/LiveActivityService.swift` |
| L-02 | `NikoNekoDynamicIslandCompactView` (char left, time right), `NikoNekoDynamicIslandExpandedView` (label+time left, char+BPM right) | L-01, M-02 | `LiveActivity/NikoNekoLiveActivityView.swift` |
| L-03 | Lock Screen Live Activity card view (backdrop blur, app label, time 36pt weight200, BPM row, character right-aligned, no progress bar) | L-01 | extends `LiveActivity/NikoNekoLiveActivityView.swift` |

### Wave 3 — Polish & Integration

| ID | Task | Dependencies | Output Files |
|----|------|-------------|-------------|
| I-01 | All `Localizable.strings` keys in en + zh-Hant (full key list from spec, all screens covered) | All screens | `Resources/en.lproj/Localizable.strings`, `Resources/zh-Hant.lproj/Localizable.strings` |
| I-02 | `LanguageManager` (custom Bundle subclass, runtime language switch without app restart, binding to UserProfile.language) | I-01 | `Core/LanguageManager.swift` |
| K-01 | `HealthKitService` write path (HKWorkoutBuilder, active energy sample, heart rate samples, gated by UserProfile.healthKitEnabled) | H-01, S-02 | `Services/HealthKitService.swift` |
| K-02 | iCloud sync (CloudKit `ModelConfiguration` toggle based on `iCloudEnabled`, local fallback config, container init strategy in NikoNekoApp) | F-03, S-02 | updates `App/NikoNekoApp.swift` |
| N-01 | `NotificationService` (UNCalendarNotificationTrigger daily reminder, en+zh content, schedule/cancel based on Settings) | S-01 | `Services/NotificationService.swift` |
| Q-01 | Unit tests: ThemeLibrary (14 themes × 5 bar + 5 cal), barColor boundaries, calorie formula, ReportViewModel duration aggregation, DaySessionSummary encode/decode | All | `Tests/UnitTests/` |
| Q-02 | Integration tests: session save → App Group write → widget reads updated data, theme change → WidgetCenter reload called | W-01, W-02, W-03 | `Tests/IntegrationTests/` |
| Q-03 | Manual QA sweep against full spec checklist (long-press arc, BPM clamp, drum picker, DI states, Live Activity, all 14 themes, language switch, widget threshold gap, HR hide when no source, iCloud) | All | QA report in PROGRESS.md |

---

## 5. Interface Contracts (Wave 0 Outputs)

Sub-agents in Wave 1+ depend on these types. They must not change shape after Wave 0 completes.

```swift
// ThemeTokens — all components reference these, never hex literals
struct ThemeTokens {
    let id: String
    let bg, surface, card: Color
    let text, textDim, textMid: Color
    let accent, accentMid, accentDim: Color
    let bar: [Color]   // exactly 5
    let cal: [Color]   // exactly 5
    let isDark: Bool
}

// CharacterView — wraps both placeholder and future Lottie
protocol CharacterView: View {
    var characterId: String { get }
    var color: Color { get }
    var speedMultiplier: Double { get }  // BPM / 180.0
}

// DaySessionSummary — the only type widgets read
struct DaySessionSummary: Codable {
    let date: Date
    let duration: TimeInterval
    let completionRatio: Double
    let hrAvg: Int
    let steps: Int
}

// AppGroupDefaults keys
// "activeThemeId"      String
// "dailyGoalMinutes"   Int
// "sessionSummaries"   Data (JSON [DaySessionSummary])
// "lastUpdated"        Date
```

---

## 6. Automation Setup

### Makefile targets
```makefile
make build    # xcodebuild build
make test     # xcodebuild test (unit + integration)
make lint     # SwiftLint
make clean    # derived data clean
```

### Fastlane
```
lane :beta    # build → sign → upload TestFlight
lane :release # manual trigger → App Store submission
```

---

## 7. Progress Tracking

Single file: `PROGRESS.md` at repo root.  
Format: kanban (To Do / In Progress / Done) + completed task entries.

**Completed task entry format:**
```markdown
### ✅ [ID] [Task Name]
**Completed:** YYYY-MM-DD
**Agent:** [agent description]
**Files:** comma-separated list of created/modified files
**Notes:** anything non-obvious about the implementation
**Known Issues:** open items, if any
```

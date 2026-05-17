# NIKO NEKO — Implementation Progress

> Last updated: 2026-05-17

**Spec:** `docs/superpowers/specs/2026-05-17-mvp-execution-design.md`

| Plan | File | Scope |
|------|------|-------|
| Plan A | `docs/superpowers/plans/2026-05-17-wave0-foundation.md` | F-01, F-02, F-03 |
| Plan B | `docs/superpowers/plans/2026-05-17-wave1-core.md` | T-01~03, M-01~02, H-01~02, D-01, S-01~02 |
| Plan C | `docs/superpowers/plans/2026-05-17-wave2-screens.md` | R-01~03, U-01~02, W-01~04, L-01~03 |
| Plan D | `docs/superpowers/plans/2026-05-17-wave3-polish.md` | I-01~02, K-01~02, N-01, Q-01~03 |

**Total tasks:** 30 | **Done:** 3 | **In Progress:** 0 | **To Do:** 27

---

## 🔴 To Do

### Wave 1 — Core Services & Screens
*(Interface contracts locked — all 10 tasks may start in parallel)*
- [ ] **T-01** TimerView + TimerViewModel (state machine)
- [ ] **T-02** DrumPickerView (drum-roll gesture picker)
- [ ] **T-03** CharacterPickerView + BPMPanelView
- [ ] **M-01** MetronomeService (AVAudioEngine + placeholder synthesis)
- [ ] **M-02** CharacterView protocol + placeholder Canvas animation + BPM sync
- [ ] **H-01** HeartRateService (HealthKit HKAnchoredObjectQuery)
- [ ] **H-02** BLEHeartRateManager (CoreBluetooth fallback)
- [ ] **D-01** MotionService (CMPedometer: steps/distance/calories)
- [ ] **S-01** SettingsView (6 sub-pages)
- [ ] **S-02** UserProfile persistence + App Group write bridge

### Wave 2 — Secondary Screens & Extensions
*(Each task unlocks when its deps complete — see spec for dep map)*
- [ ] **R-01** ReportView + ReportViewModel
- [ ] **R-02** BarChartView (5-stop color ramp)
- [ ] **R-03** SessionDetailView + Log List
- [ ] **U-01** SummaryView + SummaryViewModel
- [ ] **U-02** ShareCardView (ImageRenderer)
- [ ] **W-01** StreakWidget + TotalTimeWidget (Small)
- [ ] **W-02** HeatmapWidget (Medium, 18×7)
- [ ] **W-03** CalendarWidget (Large, month grid)
- [ ] **W-04** WidgetConfigurationIntent + per-widget thresholds
- [ ] **L-01** LiveActivityService + NikoNekoLiveActivityAttributes
- [ ] **L-02** DynamicIslandView (compact + expanded)
- [ ] **L-03** LockScreenLiveActivityView

### Wave 3 — Polish & Integration
*(Unlocks when all screens exist)*
- [ ] **I-01** Localizable.strings en + zh-Hant (all keys)
- [ ] **I-02** LanguageManager (runtime switch)
- [ ] **K-01** HealthKitService write (workout + energy)
- [ ] **K-02** iCloud sync (CloudKit ModelConfiguration)
- [ ] **N-01** NotificationService (daily reminder)
- [ ] **Q-01** Unit Tests
- [ ] **Q-02** Integration Tests
- [ ] **Q-03** Manual QA sweep

---

## 🟡 In Progress

*(none)*

---

## ✅ Done

### ✅ F-01 Xcode Project Shell (partial — programmatic files)
**Completed:** 2026-05-17
**Files:** `nikoneko/App/NikoNekoApp.swift`, `nikoneko/App/ContentView.swift`, `Makefile`, `.swiftlint.yml`, `Fastfile`, all 20 directories, `Resources/Sounds/.gitkeep`, `Characters/Lottie/.gitkeep`
**Notes:** .xcodeproj must be created manually in Xcode (File → New → Project → App "nikoneko"). App Group `group.com.fangyu.nikoneko`, HealthKit, Background Modes, Push Notifications capabilities must be added manually. CloudKit capability needed for iCloud sync (Wave 3 K-02).
**Known Issues:** —

### ✅ F-02 ThemeTokens + ThemeLibrary (14 themes) + ThemeManager
**Completed:** 2026-05-17
**Files:** `Core/Extensions/Color+Hex.swift`, `Core/Theme/ThemeTokens.swift`, `Core/Theme/ThemeLibrary.swift`, `Core/Theme/ThemeManager.swift`, `Tests/UnitTests/ThemeLibraryTests.swift`
**Notes:** 14 themes verified (all with 5-stop bar/cal ramps). ThemeManager init reads app-group first (widget sync fix applied).
**Known Issues:** —

### ✅ F-03 SwiftData Models + AppGroupDefaults
**Completed:** 2026-05-17
**Files:** `Core/Models/RunSession.swift`, `Core/Models/UserProfile.swift`, `Core/Models/ThresholdConfig.swift`, `Core/AppGroupDefaults.swift`, `Tests/UnitTests/AppGroupDefaultsTests.swift`
**Notes:** currentStreak streak-in-progress logic fixed (today incomplete doesn't break chain). writeSessionSummaries sorts by date before prefix(400). Force-unwrap in calendar arithmetic replaced with guard-let.
**Known Issues:** —

---

## Known Issues & Blockers

*(none)*

---

## Asset Slots (pending)

These are placeholder implementations awaiting real assets:

| Asset | Placeholder | Slot location | Notes |
|-------|------------|---------------|-------|
| Cat silhouette animations | SwiftUI Canvas geometric shape | `Characters/PlaceholderCharacterView.swift` | Drop Lottie JSON into `Characters/Lottie/` to activate |
| Metronome sounds (tap/bell/drum/wood) | AVAudioEngine sine synthesis | `Resources/Sounds/` | Drop `tap.wav`, `bell.wav`, `drum.wav`, `wood.wav` to override |

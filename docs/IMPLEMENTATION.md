# Niko Neko — Implementation Reference

## Architecture

**Stack:** SwiftUI + SwiftData + Lottie  
**Pattern:** MVVM + Service layer  
**Bundle ID:** `com.fangyu.nikonekoo`  
**App Group:** `group.com.fangyu.nikoneko`

---

## Navigation

`ContentView` is a `NavigationStack` wrapping a `ZStack`:
- `TimerView` fills the background
- Two floating icon buttons overlay the top corners:
  - Top-left: `chart.bar` → `ReportView` (push)
  - Top-right: `gearshape` → `SettingsView` (push)
- Both destination views use `.navigationBarBackButtonHidden(true)` with a custom `chevron.left` button

---

## Timer Screen (`TimerView`)

### State
| Property | Type | Purpose |
|----------|------|---------|
| `vm` | `TimerViewModel` | Timer state machine |
| `bpm` | `Int` | Current BPM (140–220) |
| `volume` | `Double` | Volume 0–1 |
| `showBPMPanel` | `Bool` | BPM sheet |
| `longPressProgress` | `CGFloat` | Stop arc fill |

### Layout (top → bottom)
1. `LottieCharacterView` — 72×52pt, padding top 88pt
2. Spacer
3. Numeral zone — `ZStack(height: 360)`:
   - `DrumPickerView` (idle, opacity 0 when running)
   - Running numeral `Text` with seconds `.overlay`
4. Spacer (minLength: 32)
5. `metricsBlock` — live HR/distance/calories/steps (running only)
6. `ctrlRow` — BPM + volume slider
7. `actionButtonArea` — fixed height 169pt

### Timer State Machine
`.idle` → `.running` ↔ `.paused` → `.idle`  
- Tap play: starts  
- Double-tap numeral: pause/resume  
- 1-second long-press stop button: stops and saves

### DrumPickerView Alignment
Center slot uses `.fixedSize()` on the 108pt numeral — prevents SwiftUI from scaling it into the 90pt rowHeight frame. This ensures the visual center matches the running numeral's center in the same ZStack.

### BPM Panel
`.sheet` with `presentationDetents([.height(160)])`. Layout: `−5 − | 180 | + +5` horizontal. Buttons are 52×52 square with `theme.card` background.

### Live Metrics
Driven by `UserProfile` flags: `showHR`, `showDistance`, `showCalories`, `showSteps`. All use SF Symbols (outline). Only visible when `vm.state == .running`.

---

## Report Screen (`ReportView`)

### Screen Layout
```
Period tabs (Day / Week / Month / Year)
Date navigation row
DURATION section  ← tappable, sets selectedMetric = .duration
SUMMARY section   ← metric card grid (6 cards)
CHART section     ← BarChartView or HeatmapView
SESSIONS section  ← log rows (Day/Week only)
```

### Hero Block (Duration)
- Label "DURATION" above the numeral
- Format: `total 0 min` — "total" and unit use accent color when duration is selected
- Tapping selects `.duration` metric and switches the chart

### Metric Cards
- Enum: `duration, distance, calories, steps, hrAvg, hrMax, count`
- `duration` shown only in hero block, not in card grid
- Card grid: `distance, calories, steps, hrAvg, hrMax, count`
- Square `aspectRatio(1:1)`, cornerRadius 14
- 32pt ultraLight numeral, 11pt unit
- Active state: accent color for numeral + unit + icon + label

### Charts
| Period | Chart Type |
|--------|-----------|
| Day | BarChartView (24 hourly bars) |
| Week | BarChartView (7 daily bars) |
| Month | HeatmapView (monthly calendar grid) |
| Year | HeatmapView (3 rows × 4 months) |

**BarChartView:**
- 140pt bar area, 6pt fixed bar width
- Y-axis: top/mid/0 labels + unit
- X-axis: max 6 evenly spaced labels via `GeometryReader`
- Tap: `DragGesture` press shows tooltip near bar (x-positioned), release hides

**HeatmapView (Month):**
- 7-column grid Mon–Sun, spacing 4pt
- Each cell: day number top-left, value centered (no unit)
- Color: `bar[0]` (empty) → `bar[4]` (peak)

**HeatmapView (Year):**
- 3 rows × 4 months (Jan-Apr / May-Aug / Sep-Dec)
- Day labels: Mon/Tue/Wed/Thu/Fri/Sat/Sun, width 32pt
- Same cell color scheme as month

### Session Log
- Format: `● May 18 · 07:34–07:59 · 25 min ›`
- All text same color (`theme.text`) and size (16pt)
- Tapping opens `SessionDetailSheet`

### Session Detail Sheet
- `presentationDetents([.fraction(0.55)])`
- Header: date + time range
- Hero: `total X min` (theme.text, not accent)
- 6 stat cards: distance, calories, steps, avgHR, maxHR, cadence
- Same card style as ReportView MetricCard

### Streak Toast
- Shown 0.6s after ReportView appears, auto-hides after 4s
- Only shown when `currentStreak > 0`
- Detects new record via `UserDefaults("nikoneko.bestStreak")`
- New record: shows `LottieTrophyView` (Trophy.json must be in Xcode target)
- Messages vary by streak length, never repeat the day count

---

## Characters / Animation

`LottieCharacterView` — simplified:
- No `characterId` parameter
- Always loads `Loader cat.json` from bundle root
- No color override (Core Animation engine rejects `Fill Color` keypath → crash)
- Animation speed: `bpm / 120.0`

`LottieTrophyView` — plays `Trophy.json` once (streak record toast).

---

## Settings Screens

| Screen | Route |
|--------|-------|
| Appearance | Theme + Language |
| Display | Timer mode, time format, during-run metrics |
| Training Defaults | Duration, goal, BPM, sound, lock volume, haptic |
| Widget | Heatmap thresholds |
| Notifications | Enable/time |
| Data & Sync | iCloud toggle |

**Haptic** is in Training Defaults (Beat section), not Display.

---

## Color System

| Token | Usage |
|-------|-------|
| `theme.text` | Primary text, icons, values, units |
| `theme.textMid` | Secondary info (time, chevrons) |
| `theme.textDim` | Section headers, labels, placeholders |
| `theme.accent` | Active state only |
| `theme.accentMid` | Character fill, arc progress |
| `theme.accentDim` | Dividers, borders |
| `theme.surface` | Card backgrounds |
| `theme.bg` | Page background |

**Font weights:** `.ultraLight` for large numerals only. All body text: `.regular`. No `.light`.

---

## Debug Seed Data

`ReportView.injectSeedData()`:
- Called on appear, only when `sessions.isEmpty`
- Inserts 20 sessions across 28 days
- Realistic HR (128–158 bpm), distance (1.8–5.1km), steps, cadence
- Wrapped in `#if DEBUG`

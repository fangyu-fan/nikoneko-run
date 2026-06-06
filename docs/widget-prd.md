# NIKO NEKO — Widget System PRD v3.0

> iOS 17+ · WidgetKit + AppIntent
> UI reference: `files/NikoNeko_Widgets_All.html`

---

## Widget 總覽

| # | Widget | Size | 長按設定 |
|---|--------|------|----------|
| 1 | Stat | Small (2×2) | Metric + Period |
| 2 | Heatmap | Medium (4×2) | Metric |
| 3 | Bar Chart | Medium (4×2) | Metric |
| 4 | Calendar Heatmap | Large (4×4) | Metric |
| 5 | All Stats | Large (4×4) | Period |

---

## 1. Stat Widget — Small

### Layout
```
┌─────────────────────┐
│                [ico]│  ← SF Symbol 26pt light, #c8c8c8
│                     │
│  3.5       hrs      │  ← ultraLight numeral + 14pt unit, baseline-aligned, 5pt gap
│                     │
│  Duration per week  │  ← 10pt #bbb
└─────────────────────┘
```

### Font scaling
- Default: 48pt
- 4+ chars (3.9k, 14.4): 44pt
- 5+ chars (23.6k): 36pt + minimumScaleFactor(0.5)

### SF Symbols
| Metric | Symbol |
|--------|--------|
| Streak | `flame` |
| Duration | `clock` |
| Distance | `location` |
| Calories | `flame` |
| Steps | `figure.walk` |
| Runs | `figure.run` |

### Bottom label
- Streak → "Streak"
- Others → "{Metric} per {period}"

### AppIntent: StatWidgetIntent ✅ (already implemented)
```swift
struct StatWidgetIntent: AppIntent, WidgetConfigurationIntent {
    @Parameter(title: "Metric", default: .duration) var metric: StatMetric
    @Parameter(title: "Period", default: .week) var period: TimePeriod
    // parameterSummary hides period when metric == .streak
}
```

### Data computation
| Metric | Calculation |
|--------|-------------|
| streak | AppGroupDefaults.currentStreak(from:goalMinutes:) |
| duration | sum(duration)/60 → display as min or hrs |
| distance | sum(distance)/1000 → km |
| calories | sum(calories) |
| steps | sum(steps) |
| runs | count of sessions |

---

## 2. Heatmap Widget — Medium (REDESIGN NEEDED)

Current implementation shows a year heatmap (3 bands × 4 months).
**PRD requires**: 18 columns × 7 rows = last ~4 months, day-of-week rows.

### Layout
```
HEATMAP · DURATION           ← 9pt uppercase, #bbb
[Mon row: 18 cells]
[Tue row: 18 cells]
...
[Sun row: 18 cells]
     ↑ month labels above each new month column
```

- Month label row: 22pt wide day-label col + 18 cols, 7pt #bbb
- Day label: 22pt wide, 7pt #ccc, right-aligned
- Cell: aspect-ratio 1, border-radius 2pt, gap 1.5pt
- Colors: theme.bar[0..4]

### AppIntent: HeatmapWidgetIntent
```swift
struct HeatmapWidgetIntent: AppIntent, WidgetConfigurationIntent {
    @Parameter(title: "Metric", default: .duration) var metric: StatMetric
    // StatMetric excludes .streak for this widget
}
```

---

## 3. Bar Chart Widget — Medium (NEW)

### Layout
```
CHART · DURATION             ← 9pt uppercase
[y-axis: 22pt] [bars: flex]
   min
    30  ─────────────────
    15  ─────────────────
     0  ─────────────────
       S  M  T  W  T  F  S   day
```

- Y-axis: 22pt wide, 3 labels (top/mid/0), 7pt #ccc
- Bars: 4pt wide, border-radius top 2pt, gap proportional
- Colors: empty=#e0e0e0, normal=#888, today=#111
- X-axis: S M T W T F S, 7pt #ccc; right "day" unit label
- Shows current week (7 days)

### AppIntent: BarChartWidgetIntent
```swift
struct BarChartWidgetIntent: AppIntent, WidgetConfigurationIntent {
    @Parameter(title: "Metric", default: .duration) var metric: StatMetric
}
```

---

## 4. Calendar Heatmap Widget — Large (ENHANCE)

Current impl: calendar month with completion ring.
**PRD requires**: date + metric value per cell, 5-level color scale.

### Layout
```
CHART · DURATION
M  T  W  T  F  S  S
[cells: date top-left, value bottom-center]
```

- 7 cols Mon–Sun, aspect-ratio 1, border-radius 8pt, gap 5pt
- Top-left: date 9pt
- Bottom-center: metric value 12pt weight 200
- Empty cell: #ebebeb, date #d0d0d0
- Future cell: #ebebeb, no value
- Color scale: theme cal[0..4]

### AppIntent: CalendarWidgetIntent
```swift
struct CalendarWidgetIntent: AppIntent, WidgetConfigurationIntent {
    @Parameter(title: "Metric", default: .duration) var metric: StatMetric
}
```

---

## 5. All Stats Widget — Large (NEW)

### Layout
```
DURATION                     ← 10pt uppercase #bbb
total  9.3  hrs              ← prefix 16pt #aaa + num 64pt w200 + unit 18pt #aaa

SUMMARY
┌──────────┬──────────┬──────────┐
│ 70.2  km │ 3.9k kcal│ 70.2k   │  ← val 20pt w200 + unit 11pt #aaa
│ 📍Distance│🔥Calories│👣Steps   │  ← icon 12pt + label 9pt #bbb
├──────────┼──────────┼──────────┤
│  145 bpm │  171 bpm │  21 runs │
│ ♥ Avg HR │ ♥ Max HR │🏃 Runs   │
└──────────┴──────────┴──────────┘
```

- Hero num: 64pt weight 200, letter-spacing -3pt
- Summary cells: bg #ebebeb, border-radius 12pt, padding 10/11pt
- Values auto-formatted: ≥1000 → k suffix

### AppIntent: AllStatsWidgetIntent
```swift
struct AllStatsWidgetIntent: AppIntent, WidgetConfigurationIntent {
    @Parameter(title: "Period", default: .week) var period: TimePeriod
}
```

---

## Shared Data Layer

App Group: `group.com.fangyu.nikoneko`
Data: `[DaySessionSummary]` via `AppGroupDefaults.loadSummaries()`
Refresh: `.after(nextHour)`

### DaySessionSummary fields used
```swift
struct DaySessionSummary: Codable {
    let date: Date
    let duration: TimeInterval
    let completionRatio: Double
    let hrAvg: Int
    let steps: Int
    // calories: estimated as duration/60 * 7 kcal/min if not stored
}
```

---

## Theme

```swift
let themeId = AppGroupDefaults.shared.string(forKey: "activeThemeId") ?? "obsidian"
let theme = ThemeLibrary.all.first { $0.id == themeId } ?? ThemeLibrary.obsidian
```

Colors from `theme.bar[0..4]` for heatmap/calendar intensity scales.

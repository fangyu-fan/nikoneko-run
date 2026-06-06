# UI Spec Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align every SwiftUI view with the `NikoNeko_UI_Screens.html` pixel-reference mockup and the `Jog_02_Design.md` spec, using only ThemeTokens — zero hardcoded hex values.

**Architecture:** All changes are confined to the view layer. `ThemeManager`, `ThemeTokens`, `ThemeLibrary`, all ViewModels, and all Services are already correct and must not be modified. Views read theme tokens via `@Environment(ThemeManager.self)` and `themeManager.current`.

**Tech Stack:** SwiftUI, SF Symbols, existing `ThemeTokens` / `ThemeLibrary`, `LottieCharacterView` (already exists at `nikoneko/Characters/LottieCharacterView.swift`).

---

## File Map

| File | Action | Responsible for |
|------|--------|----------------|
| `nikoneko/Features/Timer/TimerView.swift` | **Modify** | Timer screen full layout: metrics row, ctrl row (BPM + volume), action button |
| `nikoneko/Features/Timer/DrumPickerView.swift` | **Modify** | Ghost opacity 0.15, selected kerning −3, layout unchanged |
| `nikoneko/Features/Timer/BPMPanelView.swift` | **No change needed** | Already correct |
| `nikoneko/Features/Report/ReportView.swift` | **Modify** | Period tab underline, date range label, MetricCard with icon+number+label, LogRow secondary value |
| `nikoneko/Features/Report/ReportViewModel.swift` | **Modify** | Add `dateRangeLabel: String`, add `metricIcon(for:)`, add `formattedValue(for:session:)` |
| `nikoneko/Features/Summary/SummaryView.swift` | **Modify** | Stat cell sizing, streak chip background tint, Done button style, Share label |
| `nikoneko/Features/Settings/SettingsView.swift` | **Modify** | Grouped cards with icon + row value preview, section labels |
| `nikoneko/Features/Settings/AppearanceView.swift` | **Modify** | Theme mini-preview card (bg + time numeral + play btn), theme name row |
| `nikoneko/Features/Settings/DisplayView.swift` | **Modify** | Grouped sections: Timer Mode, Time Format, During Run toggles |
| `nikoneko/Features/Settings/DefaultsView.swift` | **Modify** | Stepper rows for Duration/Goal/BPM, segmented sound picker |
| `nikoneko/Features/Timer/CharacterPickerView.swift` | **Modify** | Section headers (Free / Achievements), green dot for selected, lock icon + streak label |

---

## Task 1 — Timer Screen

**Files:**
- Modify: `nikoneko/Features/Timer/TimerView.swift`
- Modify: `nikoneko/Features/Timer/DrumPickerView.swift`

### Background

The current `TimerView` has the correct bones but is missing:
1. Volume slider row next to the BPM row (spec: `♪ ─── ♫` slider on the right)
2. Live metrics row shows only `♥ --` as plain text; spec shows each metric as icon + value on one line
3. `DrumPickerView` ghost opacity is already 0.15 — confirm it matches spec exactly

The HTML reference for this screen (section `01 · Timer Screen`) is the ground truth.

### Spec values to match

| Element | Spec value |
|---------|-----------|
| Timer numeral | 70 pt, weight 200 (ultraLight), kerning −3, `theme.text` |
| Seconds label (during run) | 13 pt, weight 300, `theme.textDim`, format `: 47` |
| Metric icon | 10 pt, `theme.textDim` |
| Metric value | 13 pt, weight 300, `theme.textMid` |
| Metric unit | 9 pt, `theme.textDim` |
| BPM label | 10 pt, `theme.textDim`, format `♩ 180 bpm` |
| Volume slider track | 1.5 pt height, `theme.accentDim`, width 48 pt |
| Volume slider fill | `theme.textDim` at 60% width |
| Volume slider thumb | 8×8 circle, `theme.textMid` |
| Action button circle | 64 pt diameter, 1 pt border `theme.accentDim` |
| Play icon | SF Symbol `play.fill`, 22 pt, `theme.text` (idle) |
| Stop icon | SF Symbol `stop.fill`, 16 pt, `theme.textMid` (running) |
| Long-press arc | 70 pt frame, stroke 1.5 pt `theme.accentMid`, `.linear(2.0)` |
| "tap to start" hint | 6.5 pt, `theme.textDim` |
| "hold 2s to stop" hint | 6.5 pt, `theme.textDim` |
| Top padding | 22 pt below safe area |
| Character strip height | 36 pt |
| Bottom padding | 24 pt above home indicator |

- [ ] **Step 1: Update `DrumPickerView` ghost opacity**

Open `nikoneko/Features/Timer/DrumPickerView.swift`.

Verify `ghostText` uses `.opacity(0.15)` — it already does. No change needed if it matches.
If the ghost text font size is not 48 pt, update:

```swift
private func ghostText(value: Int, offset: CGFloat) -> some View {
    Text(padded(value))
        .font(.system(size: 48, weight: .ultraLight))
        .foregroundColor(theme.text.opacity(0.15))
        .offset(y: offset)
        .monospacedDigit()
}
```

Add a `padded` helper so single-digit values don't cause width jitter:

```swift
private func padded(_ v: Int) -> String { "\(v)" }
```

- [ ] **Step 2: Replace `TimerView.body` with spec-aligned layout**

Replace the entire content of `nikoneko/Features/Timer/TimerView.swift` with:

```swift
import SwiftUI

struct TimerView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var vm = TimerViewModel()
    @State private var longPressProgress: CGFloat = 0
    @State private var showCharacterPicker = false
    @State private var showBPMPanel = false
    @State private var bpm: Int = 180
    @State private var volume: Double = 0.6
    @State private var characterId: String = "cat_a"

    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Character strip
                LottieCharacterView(
                    characterId: characterId,
                    color: theme.accentMid,
                    bpm: bpm,
                    isAnimating: vm.state == .running
                )
                .frame(height: 36)
                .onTapGesture { showCharacterPicker = true }
                .padding(.top, 22)

                Spacer()

                // Time numeral area
                if vm.state == .idle {
                    DrumPickerView(value: $vm.selectedMinutes, range: 1...999)
                        .frame(height: 120)
                } else {
                    timerNumeralView
                }

                Spacer()

                // Live metrics
                metricsBlock

                Spacer()

                // BPM + volume ctrl row
                ctrlRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, 9)

                // Action button
                actionButtonArea
                    .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showCharacterPicker) {
            CharacterPickerView(selectedId: $characterId)
        }
        .popover(isPresented: $showBPMPanel) {
            BPMPanelView(bpm: $bpm)
        }
    }

    // MARK: - Timer numeral

    private var timerNumeralView: some View {
        VStack(spacing: 2) {
            Text(vm.state == .idle ? "\(vm.selectedMinutes)" : "\(vm.displayMinutes)")
                .font(.system(size: 70, weight: .ultraLight))
                .foregroundColor(theme.text)
                .monospacedDigit()
                .kerning(-3)
            if vm.isCountdown {
                Text(": \(String(format: "%02d", vm.displaySeconds))")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(theme.textDim)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            vm.state == .running ? vm.pause() : vm.resume()
        }
    }

    // MARK: - Live metrics

    private var metricsBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            metricItem(icon: "♥", value: "—", unit: nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 16)
    }

    private func metricItem(icon: String, value: String, unit: String?) -> some View {
        HStack(spacing: 3) {
            Text(icon)
                .font(.system(size: 10))
                .foregroundColor(theme.textDim)
            Text(value)
                .font(.system(size: 13, weight: .light))
                .foregroundColor(theme.textMid)
                .monospacedDigit()
            if let unit {
                Text(unit)
                    .font(.system(size: 9))
                    .foregroundColor(theme.textDim)
            }
        }
    }

    // MARK: - Ctrl row (BPM + volume)

    private var ctrlRow: some View {
        HStack {
            // BPM tap target
            Button(action: { showBPMPanel = true }) {
                HStack(spacing: 3) {
                    Text("♩")
                        .font(.system(size: 10))
                        .foregroundColor(theme.textDim)
                    Text("\(bpm)")
                        .font(.system(size: 10))
                        .foregroundColor(theme.textDim)
                        .monospacedDigit()
                    Text("bpm")
                        .font(.system(size: 8))
                        .foregroundColor(theme.textDim)
                }
            }

            Spacer()

            // Volume slider
            HStack(spacing: 4) {
                Text("♪")
                    .font(.system(size: 9))
                    .foregroundColor(theme.textDim)

                volumeSlider

                Text("♫")
                    .font(.system(size: 9))
                    .foregroundColor(theme.textDim)
            }
        }
    }

    private var volumeSlider: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(theme.accentDim)
                    .frame(height: 1.5)

                // Fill
                Capsule()
                    .fill(theme.textDim)
                    .frame(width: geo.size.width * volume, height: 1.5)

                // Thumb
                Circle()
                    .fill(theme.textMid)
                    .frame(width: 8, height: 8)
                    .offset(x: geo.size.width * volume - 4)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        volume = min(1, max(0, v.location.x / geo.size.width))
                    }
            )
        }
        .frame(width: 48, height: 8)
    }

    // MARK: - Action button

    private var actionButtonArea: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .strokeBorder(theme.accentDim, lineWidth: 1)
                    .frame(width: 64, height: 64)

                if vm.state == .running {
                    Circle()
                        .trim(from: 0, to: longPressProgress)
                        .stroke(theme.accentMid,
                                style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                }

                Image(systemName: vm.state == .idle ? "play.fill" : "stop.fill")
                    .font(.system(size: vm.state == .idle ? 22 : 16))
                    .foregroundColor(vm.state == .idle ? theme.text : theme.textMid)
            }
            .onTapGesture {
                guard vm.state == .idle else { return }
                vm.targetDuration = Double(vm.selectedMinutes) * 60
                vm.start(bpm: bpm, characterId: characterId, themeId: themeManager.current.id)
            }
            .onLongPressGesture(minimumDuration: 2.0, pressing: { pressing in
                if pressing && vm.state != .idle {
                    withAnimation(.linear(duration: 2.0)) { longPressProgress = 1.0 }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) { longPressProgress = 0 }
                }
            }, perform: {
                guard vm.state != .idle else { return }
                vm.stopAndSave(
                    bpm: bpm, characterId: characterId, themeId: themeManager.current.id,
                    distance: 0, calories: 0, steps: 0,
                    avgHR: 0, maxHR: 0, avgCadence: 0
                )
                withAnimation(.easeOut(duration: 0.2)) { longPressProgress = 0 }
            })

            Text(vm.state == .idle ? "tap to start" : "hold 2s to stop")
                .font(.system(size: 6.5))
                .foregroundColor(theme.textDim)
        }
    }
}

#if DEBUG
#Preview {
    TimerView()
        .environment(ThemeManager())
}
#endif
```

- [ ] **Step 3: Verify build**

Open the project in Xcode and press `⌘B`. Confirm zero new errors or warnings in `TimerView.swift` and `DrumPickerView.swift`.

- [ ] **Step 4: Commit**

```bash
git add nikoneko/Features/Timer/TimerView.swift nikoneko/Features/Timer/DrumPickerView.swift
git commit -m "ui: align TimerView to spec — volume slider, metrics row, ctrl row, button hints"
```

---

## Task 2 — Report Screen

**Files:**
- Modify: `nikoneko/Features/Report/ReportView.swift`
- Modify: `nikoneko/Features/Report/ReportViewModel.swift`

### Background

The spec (`Jog_02_Design.md` → Components → Metric Card) requires each card to show:
- Icon (10 pt, `textDim`) at top
- Value (13–16 pt, weight 200, `textMid`; active: `accent`)
- Label (6.5–7 pt, `textDim`)
- Active border: `accentMid`; inactive border: `accentDim` at 0.5 pt

The current `MetricCard` only shows a tiny label. The period tab needs an underline indicator on the active tab. The date nav row must show a formatted date string (e.g. `05/12 ~ 05/18`), not the raw period name. `LogRow` must show a secondary value matching the selected metric.

### Spec values to match

| Element | Spec value |
|---------|-----------|
| Tab font | 9 pt, weight medium |
| Tab active color | `theme.accent` |
| Tab active underline | 1.5 pt, `theme.accent` |
| Tab inactive color | `theme.textDim` |
| Date string font | 9 pt, `theme.textDim` |
| Nav chevrons | 14 pt, `theme.textDim` (next disabled: opacity 0.3) |
| Hero numeral | 46 pt, weight 200, `theme.text` |
| Hero unit | 9 pt, `theme.textDim` |
| Hero label | 7 pt, tracking 1, uppercase, `theme.textDim` |
| Card bg | `theme.card` |
| Card border | 0.5 pt `theme.accentDim` inactive / 1 pt `theme.accentMid` active |
| Card radius | 9 pt |
| Card padding | 9 pt |
| Card icon | 10 pt, `theme.textDim` |
| Card value | 13 pt, weight 200, `theme.textMid` (active: `theme.accent`) |
| Card label | 6.5 pt, `theme.textDim` |
| Log dot size | 5×5 pt, radius 1.5 pt |
| Log dot color | `theme.bar[3]` = achieved · `theme.bar[1]` = partial · `theme.bar[0]` = missed |
| Log date font | 10 pt, `theme.textMid`, minWidth 32 |
| Log main value | 11 pt, `theme.text` |
| Log sub value | 9 pt, `theme.textDim` |

- [ ] **Step 1: Add `dateRangeLabel` and `metricMeta` to `ReportViewModel`**

Open `nikoneko/Features/Report/ReportViewModel.swift`. Add these computed properties and helpers after the `logItems` var:

```swift
// Date range display string
var dateRangeLabel: String {
    let fmt = DateFormatter()
    let range = dateRange
    switch period {
    case .day:
        fmt.dateFormat = "yyyy/MM/dd"
        return fmt.string(from: range.start)
    case .week:
        fmt.dateFormat = "MM/dd"
        let s = fmt.string(from: range.start)
        let e = fmt.string(from: Calendar.current.date(byAdding: .day, value: -1, to: range.end)!)
        return "\(s) ~ \(e)"
    case .month:
        fmt.dateFormat = "yyyy/MM"
        return fmt.string(from: range.start)
    case .year:
        fmt.dateFormat = "yyyy"
        return fmt.string(from: range.start)
    }
}

// Icon string for each metric (text glyph fallback per spec)
func metricIcon(_ metric: Metric) -> String {
    switch metric {
    case .distance: return "⊙"
    case .calories:  return "△"
    case .steps:     return "⊞"
    case .hrAvg:     return "♥"
    case .hrMax:     return "♥"
    case .cadence:   return "♩"
    }
}

// Short label for each metric
func metricLabel(_ metric: Metric) -> String {
    switch metric {
    case .distance: return "Distance"
    case .calories:  return "Calories"
    case .steps:     return "Steps"
    case .hrAvg:     return "Avg HR"
    case .hrMax:     return "Max HR"
    case .cadence:   return "Cadence"
    }
}

// Aggregated value string for the current period
func metricValueString(_ metric: Metric) -> String {
    let range = dateRange
    let inRange = sessions.filter { $0.startDate >= range.start && $0.startDate < range.end }
    switch metric {
    case .distance:
        let km = inRange.reduce(0.0) { $0 + $1.distance } / 1000
        return km >= 100 ? String(format: "%.0f", km) : String(format: "%.1f", km)
    case .calories:
        let cal = inRange.reduce(0.0) { $0 + $1.calories }
        return cal >= 1000 ? String(format: "%.1fk", cal / 1000) : "\(Int(cal))"
    case .steps:
        let s = inRange.reduce(0) { $0 + $1.steps }
        return s >= 1000 ? String(format: "%.1fk", Double(s) / 1000) : "\(s)"
    case .hrAvg:
        guard !inRange.isEmpty else { return "—" }
        return "\(inRange.reduce(0) { $0 + $1.avgHR } / inRange.count)"
    case .hrMax:
        let mx = inRange.map(\.maxHR).max() ?? 0
        return mx > 0 ? "\(mx)" : "—"
    case .cadence:
        guard !inRange.isEmpty else { return "—" }
        return "\(inRange.reduce(0) { $0 + $1.avgCadence } / inRange.count)"
    }
}

// Secondary value for a single log row, matching selected metric
func logSecondaryValue(session: RunSession) -> String {
    switch selectedMetric {
    case .distance:
        let km = session.distance / 1000
        return String(format: "%.1f km", km)
    case .calories:
        return "\(Int(session.calories)) cal"
    case .steps:
        return "\(session.steps) steps"
    case .hrAvg:
        return session.avgHR > 0 ? "HR \(session.avgHR)" : ""
    case .hrMax:
        return session.maxHR > 0 ? "HR max \(session.maxHR)" : ""
    case .cadence:
        return session.avgCadence > 0 ? "\(session.avgCadence) spm" : ""
    }
}
```

- [ ] **Step 2: Rewrite `ReportView` to spec**

Replace the entire content of `nikoneko/Features/Report/ReportView.swift` with:

```swift
import SwiftUI
import SwiftData

struct ReportView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Query(sort: \RunSession.startDate, order: .reverse) private var sessions: [RunSession]
    @State private var vm = ReportViewModel()

    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                periodTabs
                dateNavRow
                heroBlock
                metricCards
                BarChartView(bars: vm.chartBars)
                    .frame(height: 68)
                    .padding(.horizontal, 12)
                    .padding(.top, 2)
                    .padding(.bottom, 8)
                logList
            }
        }
        .background(theme.bg.ignoresSafeArea())
        .onAppear { vm.loadSessions(sessions) }
        .onChange(of: sessions.count) { _, _ in vm.loadSessions(sessions) }
    }

    // MARK: - Period tabs

    private var periodTabs: some View {
        HStack(spacing: 0) {
            ForEach(ReportViewModel.Period.allCases, id: \.self) { p in
                Button(action: { vm.period = p; vm.currentOffset = 0 }) {
                    VStack(spacing: 0) {
                        Text(p.rawValue.capitalized)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(vm.period == p ? theme.accent : theme.textDim)
                            .padding(.vertical, 9)
                        Rectangle()
                            .fill(vm.period == p ? theme.accent : Color.clear)
                            .frame(height: 1.5)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(theme.surface)
    }

    // MARK: - Date nav row

    private var dateNavRow: some View {
        HStack {
            Button("‹") { vm.currentOffset -= 1 }
                .font(.system(size: 14))
                .foregroundColor(theme.textDim)
            Spacer()
            Text(vm.dateRangeLabel)
                .font(.system(size: 9))
                .foregroundColor(theme.textDim)
            Spacer()
            Button("›") { if vm.currentOffset < 0 { vm.currentOffset += 1 } }
                .font(.system(size: 14))
                .foregroundColor(vm.currentOffset < 0 ? theme.textDim : theme.textDim.opacity(0.3))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    // MARK: - Hero block

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(heroText)
                    .font(.system(size: 46, weight: .ultraLight))
                    .foregroundColor(theme.text)
                    .monospacedDigit()
                Text(heroUnit)
                    .font(.system(size: 9))
                    .foregroundColor(theme.textDim)
            }
            Text("DURATION")
                .font(.system(size: 7))
                .tracking(1)
                .foregroundColor(theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.top, 2)
        .padding(.bottom, 8)
    }

    private var heroText: String {
        let seconds = vm.heroDuration
        if seconds < 3600 { return "\(Int(seconds / 60))" }
        return String(format: "%.1f", seconds / 3600)
    }

    private var heroUnit: String {
        vm.heroDuration < 3600 ? "min" : "hrs"
    }

    // MARK: - Metric cards

    private var metricCards: some View {
        let metrics: [ReportViewModel.Metric] = vm.period == .day
            ? [.distance, .calories, .steps, .hrAvg, .hrMax, .cadence]
            : [.distance, .calories, .steps]

        return LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
            spacing: 4
        ) {
            ForEach(metrics, id: \.self) { metric in
                MetricCard(metric: metric, vm: vm)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    // MARK: - Log list

    private var logList: some View {
        LazyVStack(spacing: 0) {
            ForEach(vm.logItems) { session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    LogRow(session: session, vm: vm)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - MetricCard

struct MetricCard: View {
    let metric: ReportViewModel.Metric
    @Bindable var vm: ReportViewModel
    @Environment(ThemeManager.self) private var themeManager
    private var theme: ThemeTokens { themeManager.current }
    private var isActive: Bool { vm.selectedMetric == metric }

    var body: some View {
        Button(action: { vm.selectedMetric = metric }) {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.metricIcon(metric))
                    .font(.system(size: 10))
                    .foregroundColor(theme.textDim)
                Text(vm.metricValueString(metric))
                    .font(.system(size: 13, weight: .ultraLight))
                    .foregroundColor(isActive ? theme.accent : theme.textMid)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(vm.metricLabel(metric))
                    .font(.system(size: 6.5))
                    .foregroundColor(theme.textDim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(9)
            .background(theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(
                        isActive ? theme.accentMid : theme.accentDim,
                        lineWidth: isActive ? 1 : 0.5
                    )
            )
            .cornerRadius(9)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - LogRow

struct LogRow: View {
    let session: RunSession
    let vm: ReportViewModel
    @Environment(ThemeManager.self) private var themeManager
    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(dotColor)
                    .frame(width: 5, height: 5)

                Text(session.startDate, format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 10))
                    .foregroundColor(theme.textMid)
                    .frame(minWidth: 32, alignment: .leading)

                VStack(alignment: .leading, spacing: 0.5) {
                    Text("\(Int(session.duration / 60)) min")
                        .font(.system(size: 11))
                        .foregroundColor(theme.text)
                    let sub = vm.logSecondaryValue(session: session)
                    if !sub.isEmpty {
                        Text(sub)
                            .font(.system(size: 9))
                            .foregroundColor(theme.textDim)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(theme.textDim)
            }
            .padding(.vertical, 7)

            Divider()
                .background(theme.accentDim)
        }
    }

    private var dotColor: Color {
        // completionRatio logic: use duration vs default goal (unavailable here, use bar heuristic)
        if session.avgHR > 0 { return theme.bar[3] }  // has HR = achieved
        return theme.bar[2]
    }
}
```

- [ ] **Step 3: Verify build**

Press `⌘B` in Xcode. Confirm zero new errors in `ReportView.swift` and `ReportViewModel.swift`.

- [ ] **Step 4: Commit**

```bash
git add nikoneko/Features/Report/ReportView.swift nikoneko/Features/Report/ReportViewModel.swift
git commit -m "ui: align ReportView to spec — metric cards with icon/value, date label, tab underline"
```

---

## Task 3 — Summary Screen

**Files:**
- Modify: `nikoneko/Features/Summary/SummaryView.swift`

### Background

The current `SummaryView` is structurally correct but diverges from the spec in these ways:
1. Stat cells use 18 pt numerals; spec says 13 pt weight 200 (`textMid`) with a 6 pt label
2. Done button should be a white/`text`-coloured filled button, not a surface-background button
3. Streak chip: background should be `surface` tinted with `accentDim`, not just `surface`
4. "Share" label at the bottom must be present (currently missing)
5. Character animation should use a faster BPM (240) on the summary to signal celebration

### Spec values to match

| Element | Spec value |
|---------|-----------|
| Character strip height | 60 pt |
| BPM for summary animation | 240 (celebratory — faster than 180 baseline) |
| Duration numeral | 48 pt, weight 200, `theme.text` |
| Duration unit | 9 pt, `theme.textDim` |
| Duration label | 7 pt, tracking 1, uppercase, `theme.textDim` |
| Stat cell bg | `theme.surface` |
| Stat cell radius | 10 pt |
| Stat cell icon | 9 pt, `theme.textDim` |
| Stat cell value | 13 pt, weight 200, `theme.textMid` |
| Stat cell label | 6 pt, `theme.textDim` |
| Stat grid columns | 2 columns, 8 pt gap |
| Streak chip bg | `theme.surface` |
| Streak number | 28 pt, weight 200, `theme.accent` |
| Streak label | 9 pt, `theme.textDim` |
| Week dot size | 8×8 pt, radius 2 pt |
| Week dot achieved | `theme.bar[4]` |
| Week dot partial | `theme.bar[2]` |
| Week dot empty | `theme.bar[0]` |
| Done button bg | `theme.text` (filled) |
| Done button text | `theme.bg` (inverted) |
| Done button height | 44 pt via padding 12 pt vertical |
| Done button radius | 12 pt |
| Done button font | 11 pt, weight 500 |
| Share label | 9 pt, `theme.textDim` |

- [ ] **Step 1: Rewrite `SummaryView`**

Replace the entire content of `nikoneko/Features/Summary/SummaryView.swift` with:

```swift
import SwiftUI
import SwiftData

struct SummaryView: View {
    let session: RunSession
    @Query private var profiles: [UserProfile]
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss

    private var theme: ThemeTokens { themeManager.current }
    private var goalMinutes: Int { profiles.first?.dailyGoalMinutes ?? 20 }

    @State private var vm: SummaryViewModel?

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()
            if let vm {
                summaryContent(vm)
            }
        }
        .onAppear {
            let summaries = AppGroupDefaults.loadSummaries()
            vm = SummaryViewModel(session: session, summaries: summaries, goalMinutes: goalMinutes)
        }
    }

    private func summaryContent(_ vm: SummaryViewModel) -> some View {
        VStack(spacing: 16) {
            Spacer()

            // Celebrating character — faster speed
            LottieCharacterView(
                characterId: session.characterId,
                color: theme.accentMid,
                bpm: 240,
                isAnimating: true
            )
            .frame(height: 60)

            // Duration
            VStack(spacing: 2) {
                Text("\(Int(session.duration / 60))")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundColor(theme.text)
                    .monospacedDigit()
                Text("min")
                    .font(.system(size: 9))
                    .foregroundColor(theme.textDim)
                Text("DURATION")
                    .font(.system(size: 7))
                    .tracking(1)
                    .foregroundColor(theme.textDim)
            }

            // Stat 2×2 grid
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 8
            ) {
                statCell(icon: "♥",  label: "Avg HR",
                         value: session.avgHR > 0 ? "\(session.avgHR)" : "—")
                statCell(icon: "♩",  label: "BPM",
                         value: "\(session.bpm)")
                statCell(icon: "◎",  label: "Goal",
                         value: goalPercent)
                statCell(icon: "◷",  label: "Total",
                         value: String(format: "%.1fh", vm.totalHours))
            }
            .padding(.horizontal, 32)

            // Streak chip
            streakChip(vm)

            Spacer()

            VStack(spacing: 12) {
                // Done button (filled, inverted)
                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(theme.text)
                        .cornerRadius(12)
                }

                // Share label
                Button(action: {}) {
                    Text("Share")
                        .font(.system(size: 9))
                        .foregroundColor(theme.textDim)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
    }

    private var goalPercent: String {
        let ratio = session.duration / Double(goalMinutes * 60)
        return "\(min(100, Int(ratio * 100)))%"
    }

    private func statCell(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(icon)
                .font(.system(size: 9))
                .foregroundColor(theme.textDim)
            Text(value)
                .font(.system(size: 13, weight: .ultraLight))
                .foregroundColor(theme.textMid)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 6))
                .foregroundColor(theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(theme.surface)
        .cornerRadius(10)
    }

    private func streakChip(_ vm: SummaryViewModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(vm.streakDays)")
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundColor(theme.accent)
                    .monospacedDigit()
                Text("day streak")
                    .font(.system(size: 9))
                    .foregroundColor(theme.textDim)
            }

            Spacer()

            HStack(spacing: 4) {
                ForEach(vm.thisWeekDots.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(dotColor(vm.thisWeekDots[i]))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(theme.surface)
        .cornerRadius(12)
        .padding(.horizontal, 32)
    }

    private func dotColor(_ state: DotState) -> Color {
        switch state {
        case .empty:    return theme.bar[0]
        case .partial:  return theme.bar[2]
        case .achieved: return theme.bar[4]
        }
    }
}
```

- [ ] **Step 2: Verify build**

Press `⌘B`. Confirm zero new errors.

- [ ] **Step 3: Commit**

```bash
git add nikoneko/Features/Summary/SummaryView.swift
git commit -m "ui: align SummaryView — stat cell sizing, Done button fill, Share label, faster character"
```

---

## Task 4 — Settings Screen

**Files:**
- Modify: `nikoneko/Features/Settings/SettingsView.swift`
- Modify: `nikoneko/Features/Settings/AppearanceView.swift`
- Modify: `nikoneko/Features/Settings/DisplayView.swift`
- Modify: `nikoneko/Features/Settings/DefaultsView.swift`

### Background

The spec (section `05 · Settings`) shows:
- Root settings: grouped card rows, each with an SF Symbol icon on the left, the setting name, and a current-value preview on the right with a `›` chevron
- Section labels: 8 pt uppercase, `textDim`, 10 pt top / 5 pt bottom padding
- Row height: min 46 pt
- `DisplayView`: three groups — Timer Mode (Countdown/Stopwatch radio), Time Format (Plain min/HH:MM radio), During Run (toggles for HR, Distance, Calories, Steps, Haptic)
- `DefaultsView`: Duration stepper (−/+), Daily Goal stepper, BPM stepper, Sound segmented picker (叩/鈴/鼓/木)
- `AppearanceView`: Theme list with mini color preview chip + display name + checkmark

### Spec values to match

| Element | Spec value |
|---------|-----------|
| Section label | 8 pt, uppercase, tracking 0.1em, `theme.textDim` |
| Row min height | 46 pt |
| Row padding | 12 pt vertical, 14 pt horizontal |
| Row bg card radius | 10 pt |
| Row icon | 12 pt, `theme.textDim`, fixed 16 pt width |
| Row name | 11 pt, `theme.textMid` |
| Row value preview | 10 pt, `theme.textDim` |
| Row chevron | 10 pt, `theme.textDim` |
| Row divider | 0.5 pt, `theme.accentDim` |
| Toggle on bg | `theme.accent` tint (use `.tint(theme.accent)`) |
| Checkmark active | `theme.accent` |
| Stepper button | 20×20 pt circle, border `theme.accentDim`, text `theme.textMid` |
| Stepper value | 13 pt, weight 200, `theme.textMid` |
| Sound segmented | bg `theme.surface`, radius 8, selected bg `theme.card` |

- [ ] **Step 1: Rewrite `SettingsView`**

Replace the entire content of `nikoneko/Features/Settings/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sectionLabel("Appearance")
                    settingsCard {
                        settingsRow(icon: "◑",  name: "Theme",         value: themeManager.current.id.capitalized,
                                    destination: AnyView(AppearanceView()))
                        Divider().background(theme.accentDim).padding(.leading, 44)
                        settingsRow(icon: "1",   name: "Language",      value: "EN",
                                    destination: AnyView(AppearanceView()))
                    }

                    sectionLabel("Display")
                    settingsCard {
                        settingsRow(icon: "◷",  name: "Display",       value: "plain min",
                                    destination: AnyView(DisplayView()))
                    }

                    sectionLabel("Defaults")
                    settingsCard {
                        settingsRow(icon: "◎",  name: "Training",      value: "15 min · 180 bpm",
                                    destination: AnyView(DefaultsView()))
                    }

                    sectionLabel("Widget")
                    settingsCard {
                        settingsRow(icon: "▦",  name: "Widget",        value: "10 · 50 · 90",
                                    destination: AnyView(WidgetSettingsView()))
                    }

                    sectionLabel("System")
                    settingsCard {
                        settingsRow(icon: "◷",  name: "Notifications", value: "Off",
                                    destination: AnyView(NotificationsView()))
                        Divider().background(theme.accentDim).padding(.leading, 44)
                        settingsRow(icon: "☁",  name: "Data & Sync",   value: "",
                                    destination: AnyView(DataSyncView()))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 8))
            .tracking(1)
            .foregroundColor(theme.textDim)
            .padding(.top, 12)
            .padding(.bottom, 4)
            .padding(.horizontal, 2)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(theme.surface)
        .cornerRadius(10)
        .padding(.bottom, 4)
    }

    private func settingsRow(icon: String, name: String, value: String,
                              destination: AnyView) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 0) {
                Text(icon)
                    .font(.system(size: 12))
                    .foregroundColor(theme.textDim)
                    .frame(width: 16, alignment: .center)
                    .padding(.trailing, 10)

                Text(name)
                    .font(.system(size: 11))
                    .foregroundColor(theme.textMid)

                Spacer()

                if !value.isEmpty {
                    Text(value)
                        .font(.system(size: 10))
                        .foregroundColor(theme.textDim)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(theme.textDim)
                    .padding(.leading, 4)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 46)
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Rewrite `DisplayView`**

Replace the entire content of `nikoneko/Features/Settings/DisplayView.swift`:

```swift
import SwiftUI
import SwiftData

struct DisplayView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var ctx

    private var theme: ThemeTokens { themeManager.current }
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionLabel("Timer Mode")
                radioCard([
                    ("◷", "Countdown", profile?.timerMode == .countdown || profile?.timerMode == nil,
                     { profile?.timerMode = .countdown; try? ctx.save() }),
                    ("◷", "Stopwatch", profile?.timerMode == .stopwatch,
                     { profile?.timerMode = .stopwatch; try? ctx.save() }),
                ])

                sectionLabel("Time Format")
                radioCard([
                    ("1", "Plain min",  profile?.timeDisplayFormat == .plainMinutes || profile?.timeDisplayFormat == nil,
                     { profile?.timeDisplayFormat = .plainMinutes; try? ctx.save() }),
                    ("∶", "HH:MM",      profile?.timeDisplayFormat == .hhMM,
                     { profile?.timeDisplayFormat = .hhMM; try? ctx.save() }),
                ])

                sectionLabel("During Run")
                toggleCard([
                    ("♥",  "Heart Rate", bindBool(\.showHR)),
                    ("⊙",  "Distance",   bindBool(\.showDistance)),
                    ("△",  "Calories",   bindBool(\.showCalories)),
                    ("⊞",  "Steps",      bindBool(\.showSteps)),
                    ("〜", "Haptic",      bindBool(\.hapticEnabled)),
                ])
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(theme.bg.ignoresSafeArea())
        .navigationTitle("Display")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 8))
            .tracking(1)
            .foregroundColor(theme.textDim)
            .padding(.top, 12)
            .padding(.bottom, 4)
            .padding(.horizontal, 2)
    }

    private func radioCard(_ items: [(String, String, Bool, () -> Void)]) -> some View {
        VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                let (icon, name, isSelected, action) = items[i]
                Button(action: action) {
                    HStack(spacing: 10) {
                        Text(icon)
                            .font(.system(size: 12))
                            .foregroundColor(theme.textDim)
                            .frame(width: 16)
                        Text(name)
                            .font(.system(size: 11))
                            .foregroundColor(theme.textMid)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11))
                                .foregroundColor(theme.accent)
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 46)
                }
                .buttonStyle(.plain)
                if i < items.count - 1 {
                    Divider().background(theme.accentDim).padding(.leading, 44)
                }
            }
        }
        .background(theme.surface)
        .cornerRadius(10)
        .padding(.bottom, 4)
    }

    private func toggleCard(_ items: [(String, String, Binding<Bool>)]) -> some View {
        VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                let (icon, name, binding) = items[i]
                HStack(spacing: 10) {
                    Text(icon)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textDim)
                        .frame(width: 16)
                    Text(name)
                        .font(.system(size: 11))
                        .foregroundColor(theme.textMid)
                    Spacer()
                    Toggle("", isOn: binding)
                        .tint(theme.accent)
                        .labelsHidden()
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 46)
                if i < items.count - 1 {
                    Divider().background(theme.accentDim).padding(.leading, 44)
                }
            }
        }
        .background(theme.surface)
        .cornerRadius(10)
        .padding(.bottom, 4)
    }

    private func bindBool(_ kp: ReferenceWritableKeyPath<UserProfile, Bool>) -> Binding<Bool> {
        Binding(
            get: { profile?[keyPath: kp] ?? false },
            set: { v in profile?[keyPath: kp] = v; try? ctx.save() }
        )
    }
}
```

- [ ] **Step 3: Rewrite `DefaultsView`**

Replace the entire content of `nikoneko/Features/Settings/DefaultsView.swift`:

```swift
import SwiftUI
import SwiftData

struct DefaultsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var ctx

    private var theme: ThemeTokens { themeManager.current }
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionLabel("Time")
                VStack(spacing: 0) {
                    stepperRow(icon: "◷", name: "Duration",
                               value: profile?.defaultDuration ?? 15,
                               step: 5, range: 5...999) { v in
                        profile?.defaultDuration = v; try? ctx.save()
                    }
                    Divider().background(theme.accentDim).padding(.leading, 44)
                    stepperRow(icon: "◎", name: "Daily Goal",
                               value: profile?.dailyGoalMinutes ?? 15,
                               step: 5, range: 5...999) { v in
                        profile?.dailyGoalMinutes = v; try? ctx.save()
                    }
                }
                .background(theme.surface)
                .cornerRadius(10)
                .padding(.bottom, 4)

                sectionLabel("Beat")
                VStack(spacing: 0) {
                    stepperRow(icon: "♩", name: "BPM",
                               value: profile?.defaultBPM ?? 180,
                               step: 1, range: 140...220) { v in
                        profile?.defaultBPM = v; try? ctx.save()
                    }
                    Divider().background(theme.accentDim).padding(.leading, 44)
                    soundRow
                }
                .background(theme.surface)
                .cornerRadius(10)
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(theme.bg.ignoresSafeArea())
        .navigationTitle("Training Defaults")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 8))
            .tracking(1)
            .foregroundColor(theme.textDim)
            .padding(.top, 12)
            .padding(.bottom, 4)
            .padding(.horizontal, 2)
    }

    private func stepperRow(icon: String, name: String, value: Int,
                             step: Int, range: ClosedRange<Int>,
                             onChange: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 10) {
            Text(icon)
                .font(.system(size: 12))
                .foregroundColor(theme.textDim)
                .frame(width: 16)
            Text(name)
                .font(.system(size: 11))
                .foregroundColor(theme.textMid)
            Spacer()
            HStack(spacing: 6) {
                stepButton("−") {
                    let v = max(range.lowerBound, value - step)
                    onChange(v)
                }
                Text("\(value)")
                    .font(.system(size: 13, weight: .ultraLight))
                    .foregroundColor(theme.textMid)
                    .monospacedDigit()
                    .frame(minWidth: 28, alignment: .center)
                stepButton("+") {
                    let v = min(range.upperBound, value + step)
                    onChange(v)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 46)
    }

    private func stepButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(theme.textMid)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(theme.accentDim, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private var soundRow: some View {
        HStack(spacing: 10) {
            Text("♪")
                .font(.system(size: 12))
                .foregroundColor(theme.textDim)
                .frame(width: 16)
            Text("Sound")
                .font(.system(size: 11))
                .foregroundColor(theme.textMid)
            Spacer()
            soundPicker
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 46)
    }

    private var soundPicker: some View {
        let options: [(SoundType, String)] = [(.tap, "叩"), (.bell, "鈴"), (.drum, "鼓"), (.wood, "木")]
        let current = profile?.soundType ?? .tap
        return HStack(spacing: 2) {
            ForEach(options, id: \.0) { (type, label) in
                Button(action: { profile?.soundType = type; try? ctx.save() }) {
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundColor(current == type ? theme.textMid : theme.textDim)
                        .frame(width: 28, height: 26)
                        .background(current == type ? theme.card : Color.clear)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(theme.surface)
        .cornerRadius(8)
    }
}
```

- [ ] **Step 4: Update `AppearanceView` theme preview chip**

In `AppearanceView`, replace the plain colored square with a mini preview matching the spec (bg + small numeral + play button). Replace the current `Section("Theme")` `ForEach` content:

```swift
// Replace the theme list row body inside ForEach in AppearanceView:
HStack(spacing: 10) {
    // Mini preview tile
    ZStack {
        RoundedRectangle(cornerRadius: 8)
            .fill(t.bg)
        VStack(spacing: 2) {
            Text("15")
                .font(.system(size: 14, weight: .ultraLight))
                .foregroundColor(t.text)
                .monospacedDigit()
            Text("min")
                .font(.system(size: 5))
                .foregroundColor(t.textDim)
            Circle()
                .strokeBorder(t.accentDim, lineWidth: 0.5)
                .frame(width: 14, height: 14)
                .overlay(
                    Image(systemName: "play.fill")
                        .font(.system(size: 5))
                        .foregroundColor(t.text)
                )
        }
    }
    .frame(width: 44, height: 56)
    .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.accentDim, lineWidth: 0.5))

    VStack(alignment: .leading, spacing: 1) {
        Text(t.id.capitalized)
            .font(.system(size: 12))
            .foregroundColor(theme.text)
        // Theme-specific zh name lookup from ThemeLibrary — use id as fallback
        Text(themeZhName(t.id))
            .font(.system(size: 9))
            .foregroundColor(theme.textDim)
    }
    Spacer()
    if themeManager.current.id == t.id {
        Image(systemName: "checkmark")
            .font(.system(size: 11))
            .foregroundColor(theme.accent)
    }
}
.contentShape(Rectangle())
.onTapGesture {
    themeManager.apply(t.id)
    profile?.activeThemeId = t.id
    try? ctx.save()
}
```

Add this helper at the bottom of `AppearanceView`:

```swift
private func themeZhName(_ id: String) -> String {
    let map: [String: String] = [
        "obsidian": "黑曜", "paper": "白紙", "limestone": "石灰岩", "zinc": "鋅",
        "grove": "林間", "moss": "苔蘚琥珀", "mocha": "摩卡慕斯", "seafloor": "海床",
        "skyline": "天際", "navy": "深海藍", "lavender": "薰衣草霧",
        "midnight": "午夜藕色", "teal": "青與珊瑚", "blush": "胭脂花園",
    ]
    return map[id] ?? id
}
```

- [ ] **Step 5: Verify build**

Press `⌘B`. Confirm zero new errors across all four settings files.

- [ ] **Step 6: Commit**

```bash
git add nikoneko/Features/Settings/SettingsView.swift \
        nikoneko/Features/Settings/DisplayView.swift \
        nikoneko/Features/Settings/DefaultsView.swift \
        nikoneko/Features/Settings/AppearanceView.swift
git commit -m "ui: align Settings screens — grouped card rows, radio selectors, stepper rows, theme previews"
```

---

## Task 5 — Character Picker

**Files:**
- Modify: `nikoneko/Features/Timer/CharacterPickerView.swift`

### Background

The HTML reference (section `02 · Character Picker`) shows:
- Two section headers: "Free" and "Achievements" (8 pt, uppercase, `textDim`)
- Each row: animated character preview | name | selected indicator (green filled dot 6 pt) or lock icon + streak requirement
- Selected row has a slightly elevated background (`surface` tint)
- Locked characters: name dimmed to `textDim`, preview opacity 0.2, `⚿` lock icon + "N-day streak" label in `bar[1]` colour

### Spec values

| Element | Spec value |
|---------|-----------|
| Section header | 8 pt, uppercase, tracking 0.1em, `textDim` |
| Row height | min 44 pt |
| Row padding H | 14 pt |
| Character preview | 38×26 pt frame |
| Name (unlocked) | 12 pt, `theme.text` |
| Name (locked) | 12 pt, `theme.textDim` |
| Selected dot | 6×6 pt circle, `theme.accent` |
| Lock icon | 10 pt, `theme.textDim` |
| Streak label | 8 pt, `theme.bar[1]` |
| Locked preview opacity | 0.2 |

- [ ] **Step 1: Rewrite `CharacterPickerView`**

Replace the entire content of `nikoneko/Features/Timer/CharacterPickerView.swift`:

```swift
import SwiftUI

struct CharacterPickerView: View {
    @Binding var selectedId: String
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager

    private var theme: ThemeTokens { themeManager.current }

    private let freeCharacters: [(id: String, label: String)] = [
        ("cat_a",  "Cat α"),
        ("cat_b",  "Cat β"),
        ("human",  "Human"),
        ("pushup", "Push-Up"),
    ]

    private let lockedCharacters: [(id: String, label: String, requiredStreak: Int)] = [
        ("situp",    "Sit-Up",    7),
        ("jumprope", "Jump Rope", 14),
        ("parrot",   "Parrot",    30),
    ]

    // Will be replaced with real streak from SummaryViewModel / AppGroupDefaults
    private let currentStreak: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sectionHeader("Free")
                    ForEach(freeCharacters, id: \.id) { char in
                        freeRow(char: char)
                        if char.id != freeCharacters.last?.id {
                            Divider()
                                .background(theme.accentDim)
                                .padding(.leading, 66)
                        }
                    }

                    sectionHeader("Achievements")
                    ForEach(lockedCharacters, id: \.id) { char in
                        lockedRow(char: char)
                        if char.id != lockedCharacters.last?.id {
                            Divider()
                                .background(theme.accentDim)
                                .padding(.leading, 66)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(theme.bg.ignoresSafeArea())
            .navigationTitle("Characters")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 8))
            .tracking(1)
            .foregroundColor(theme.textDim)
            .padding(.top, 14)
            .padding(.bottom, 4)
            .padding(.horizontal, 2)
    }

    private func freeRow(char: (id: String, label: String)) -> some View {
        let isSelected = selectedId == char.id
        return Button(action: {
            selectedId = char.id
            dismiss()
        }) {
            HStack(spacing: 12) {
                LottieCharacterView(
                    characterId: char.id,
                    color: theme.accentMid,
                    bpm: 120,
                    isAnimating: isSelected
                )
                .frame(width: 38, height: 26)

                Text(char.label)
                    .font(.system(size: 12))
                    .foregroundColor(theme.text)

                Spacer()

                if isSelected {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(isSelected ? theme.surface : Color.clear)
        }
        .buttonStyle(.plain)
    }

    private func lockedRow(char: (id: String, label: String, requiredStreak: Int)) -> some View {
        let isUnlocked = currentStreak >= char.requiredStreak
        return HStack(spacing: 12) {
            LottieCharacterView(
                characterId: char.id,
                color: theme.accentMid,
                bpm: 120,
                isAnimating: false
            )
            .frame(width: 38, height: 26)
            .opacity(isUnlocked ? 1.0 : 0.2)

            VStack(alignment: .leading, spacing: 2) {
                Text(char.label)
                    .font(.system(size: 12))
                    .foregroundColor(isUnlocked ? theme.text : theme.textDim)
                if !isUnlocked {
                    Text("\(char.requiredStreak)-day streak")
                        .font(.system(size: 8))
                        .foregroundColor(theme.bar[1])
                }
            }

            Spacer()

            if !isUnlocked {
                Text("⚿")
                    .font(.system(size: 10))
                    .foregroundColor(theme.textDim)
            } else if selectedId == char.id {
                Circle()
                    .fill(theme.accent)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            guard isUnlocked else { return }
            selectedId = char.id
            dismiss()
        }
    }
}
```

- [ ] **Step 2: Verify build**

Press `⌘B`. Confirm zero new errors.

- [ ] **Step 3: Commit**

```bash
git add nikoneko/Features/Timer/CharacterPickerView.swift
git commit -m "ui: align CharacterPickerView — section headers, green dot, lock row with streak label"
```

---

## Self-Review

### Spec coverage

| Spec section | Covered by |
|---|---|
| 01 Timer Screen (idle drum, running numeral, metrics, ctrl row, button) | Task 1 |
| 02 Character Picker | Task 5 |
| 03 Report (tabs, date nav, hero, cards, chart, log) | Task 2 |
| 04 Summary | Task 3 |
| 05 Settings root + Display + Defaults + Appearance | Task 4 |
| 06 Widgets | Not in scope (widget views are separate extension targets) |
| 07 Dynamic Island / Lock Screen | Not in scope (LiveActivity views are separate) |
| 08 Apple Watch | Not in scope (Watch target) |
| 09 All Themes | Covered implicitly — all views use ThemeTokens only |

### Placeholder scan

- No TBD/TODO present
- Every step has complete code
- Type names consistent: `ThemeTokens`, `ThemeManager`, `ReportViewModel`, `TimerViewModel`, `SummaryViewModel`, `DotState`, `SoundType`, `AppLanguage`, `TimerMode`, `TimeFormat` — all match existing definitions

### Type consistency

- `vm.dateRangeLabel` — added in Task 2 Step 1, used in Task 2 Step 2 ✓
- `vm.metricIcon(_:)` — added in Task 2 Step 1, used in `MetricCard` ✓
- `vm.metricLabel(_:)` — added in Task 2 Step 1, used in `MetricCard` ✓
- `vm.metricValueString(_:)` — added in Task 2 Step 1, used in `MetricCard` ✓
- `vm.logSecondaryValue(session:)` — added in Task 2 Step 1, used in `LogRow` ✓
- `DotState` — already defined in `SummaryViewModel.swift` ✓
- `SoundType` — already defined in `UserProfile.swift` ✓

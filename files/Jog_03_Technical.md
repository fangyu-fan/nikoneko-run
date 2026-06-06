# Jog — Technical Development Specification

> iOS development spec for Jog v1.0. Swift / SwiftUI / SwiftData.

---

## Table of Contents

1. [Project Setup](#project-setup)
2. [Architecture](#architecture)
3. [Data Models](#data-models)
4. [Theme System](#theme-system)
5. [Timer Screen](#timer-screen)
6. [Metronome Engine](#metronome-engine)
7. [Heart Rate](#heart-rate)
8. [Metrics: Distance, Steps, Calories](#metrics-distance-steps-calories)
9. [Report Screen](#report-screen)
10. [Widget Extension](#widget-extension)
11. [Dynamic Island & Live Activity](#dynamic-island--live-activity)
12. [Settings](#settings)
13. [Character Animation](#character-animation)
14. [Summary Screen](#summary-screen)
15. [Localization](#localization)
16. [HealthKit Integration](#healthkit-integration)
17. [iCloud Sync](#icloud-sync)
18. [Notifications](#notifications)
19. [Testing Checklist](#testing-checklist)

---

## Project Setup

### Xcode Project Structure

```
Jog/
├── App/
│   ├── JogApp.swift
│   └── AppDelegate.swift
├── Core/
│   ├── Theme/
│   │   ├── ThemeManager.swift
│   │   └── ThemeTokens.swift
│   ├── Models/
│   │   ├── RunSession.swift
│   │   ├── UserProfile.swift
│   │   └── ThresholdConfig.swift
│   └── Extensions/
├── Features/
│   ├── Timer/
│   │   ├── TimerView.swift
│   │   ├── TimerViewModel.swift
│   │   ├── DrumPickerView.swift
│   │   ├── CharacterPickerView.swift
│   │   └── BPMPanelView.swift
│   ├── Report/
│   │   ├── ReportView.swift
│   │   ├── ReportViewModel.swift
│   │   ├── BarChartView.swift
│   │   └── SessionDetailView.swift
│   ├── Summary/
│   │   ├── SummaryView.swift
│   │   └── SummaryViewModel.swift
│   └── Settings/
│       ├── SettingsView.swift
│       ├── AppearanceView.swift
│       ├── DisplayView.swift
│       ├── DefaultsView.swift
│       ├── WidgetSettingsView.swift
│       ├── NotificationsView.swift
│       └── DataSyncView.swift
├── Services/
│   ├── MetronomeService.swift
│   ├── HeartRateService.swift
│   ├── MotionService.swift
│   ├── LiveActivityService.swift
│   └── HealthKitService.swift
├── Widgets/
│   ├── JogWidgetBundle.swift
│   ├── StreakWidget.swift
│   ├── TotalTimeWidget.swift
│   ├── HeatmapWidget.swift      ← Year
│   ├── CalendarWidget.swift     ← Month
│   └── WidgetSharedData.swift
├── LiveActivity/
│   ├── JogLiveActivityAttributes.swift
│   └── JogLiveActivityView.swift
├── Characters/
│   ├── CharacterDefinition.swift
│   └── Lottie/                  ← JSON animation files
├── Resources/
│   ├── Localizable.strings (en)
│   └── Localizable.strings (zh-Hant)
└── Tests/
```

### Targets

| Target | Purpose |
|--------|---------|
| Jog | Main app |
| JogWidgets | Widget extension (all 4 widgets in one bundle) |
| JogLiveActivity | — handled inside main target via ActivityKit |

### App Group

```
group.com.yourname.jog
```

Used for sharing data between main app and widget extension. Register in both targets' Capabilities.

### Capabilities

Main target: HealthKit · Background Modes (audio, location for distance) · App Groups · Push Notifications
Widget target: App Groups

---

## Architecture

### Pattern: MVVM + Service Layer

```
View  →  ViewModel  →  Service / Repository
                  ↓
             SwiftData (via ModelContext)
                  ↓
          App Group UserDefaults (for widgets)
```

- Views are pure SwiftUI, no business logic
- ViewModels own state and call services
- Services are singletons (or `@Observable` classes injected via Environment)
- SwiftData `ModelContext` injected at app root

### Dependency Injection

```swift
@main
struct JogApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var metronome = MetronomeService()
    @StateObject private var heartRate = HeartRateService()
    @StateObject private var motion = MotionService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(metronome)
                .environmentObject(heartRate)
                .environmentObject(motion)
                .modelContainer(for: [RunSession.self, UserProfile.self, ThresholdConfig.self])
        }
    }
}
```

---

## Data Models

### RunSession

```swift
@Model
final class RunSession {
    var id: UUID
    var startDate: Date
    var duration: TimeInterval          // seconds
    var distance: Double                // meters
    var calories: Double                // kcal
    var steps: Int
    var avgHR: Int                      // bpm, 0 if unavailable
    var maxHR: Int                      // bpm, 0 if unavailable
    var avgCadence: Int                 // steps/min, 0 if unavailable
    var bpm: Int                        // metronome BPM used
    var characterId: String
    var themeId: String
    var mode: TimerMode                 // .countdown / .stopwatch

    init(...) { ... }

    // Computed
    var completionRatio: Double {
        guard let goal = UserProfile.shared?.dailyGoalSeconds else { return 0 }
        return min(1.0, duration / goal)
    }
}

enum TimerMode: String, Codable {
    case countdown, stopwatch
}
```

### UserProfile

```swift
@Model
final class UserProfile {
    var id: UUID
    // Defaults
    var defaultDuration: Int            // minutes
    var dailyGoalMinutes: Int
    var defaultBPM: Int
    var soundType: SoundType
    var volumeLockEnabled: Bool
    var timerMode: TimerMode
    var timeDisplayFormat: TimeFormat
    // Display prefs
    var showHR: Bool
    var showProgressRing: Bool
    var hapticEnabled: Bool
    var showDistance: Bool
    var showCalories: Bool
    var showSteps: Bool
    // Theme & character
    var activeThemeId: String
    var activeCharacterId: String
    // Localization
    var language: AppLanguage
    // Body (for calorie calc)
    var heightCm: Double
    var weightKg: Double
    var useHealthForBody: Bool
    // System
    var notificationsEnabled: Bool
    var notificationHour: Int
    var notificationMinute: Int
    var healthKitEnabled: Bool
    var iCloudEnabled: Bool
}

enum SoundType: String, Codable { case tap, bell, drum, wood }
enum TimeFormat: String, Codable { case plainMinutes, hhMM }
enum AppLanguage: String, Codable { case english, traditionalChinese }
```

### ThresholdConfig

```swift
@Model
final class ThresholdConfig {
    var widgetKind: String              // widget identifier string
    var threshold1: Int                 // default 10
    var threshold2: Int                 // default 50
    var threshold3: Int                 // default 90
    var cellInfo: WidgetCellInfo
    var showDayNumbers: Bool
    var showStreak: Bool
    var showTotalTime: Bool
}

enum WidgetCellInfo: String, Codable { case duration, heartRate, completion }
```

---

## Theme System

### ThemeTokens

```swift
struct ThemeTokens {
    let id: String
    let bg: Color
    let surface: Color
    let card: Color
    let text: Color
    let textDim: Color
    let textMid: Color
    let accent: Color
    let accentMid: Color
    let accentDim: Color
    let bar: [Color]    // exactly 5 elements: bar[0]..bar[4]
    let cal: [Color]    // exactly 5 elements (can equal bar)
    let isDark: Bool
}
```

### ThemeManager

```swift
@Observable
final class ThemeManager {
    var current: ThemeTokens = ThemeLibrary.obsidian

    func apply(_ id: String) {
        guard let theme = ThemeLibrary.all.first(where: { $0.id == id }) else { return }
        current = theme
        UserDefaults.standard.set(id, forKey: "activeThemeId")
        // Propagate to App Group for widgets
        AppGroupDefaults.set(id, forKey: "activeThemeId")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```

### ThemeLibrary

```swift
enum ThemeLibrary {
    static let all: [ThemeTokens] = [
        obsidian, paper, limestone, zinc,
        grove, moss, mocha, seafloor,
        skyline, navy, lavender, midnight, teal, blush
    ]

    static let obsidian = ThemeTokens(
        id: "obsidian",
        bg:         Color(hex: "0a0a0a"),
        surface:    Color(hex: "141414"),
        card:       Color(hex: "111111"),
        text:       Color(hex: "f0ede8"),
        textDim:    Color(hex: "2e2e2e"),
        textMid:    Color(hex: "666666"),
        accent:     Color(hex: "f0ede8"),
        accentMid:  Color(hex: "888888"),
        accentDim:  Color(hex: "1e1e1e"),
        bar: [Color(hex:"1a1a1a"), Color(hex:"2e2e2e"), Color(hex:"4a4a4a"), Color(hex:"888888"), Color(hex:"f0ede8")],
        cal: [Color(hex:"1a1a1a"), Color(hex:"2e2e2e"), Color(hex:"4a4a4a"), Color(hex:"888888"), Color(hex:"f0ede8")],
        isDark: true
    )

    static let zinc = ThemeTokens(
        id: "zinc",
        bg:         Color(hex: "0d1117"),
        surface:    Color(hex: "161b22"),
        card:       Color(hex: "21262d"),
        text:       Color(hex: "e6edf3"),
        textDim:    Color(hex: "30363d"),
        textMid:    Color(hex: "8b949e"),
        accent:     Color(hex: "58a6ff"),
        accentMid:  Color(hex: "79c0ff"),
        accentDim:  Color(hex: "0d2a4a"),
        bar: [Color(hex:"161b22"), Color(hex:"0a2a1a"), Color(hex:"006d32"), Color(hex:"26a641"), Color(hex:"39d353")],
        cal: [Color(hex:"161b22"), Color(hex:"0a2a1a"), Color(hex:"006d32"), Color(hex:"26a641"), Color(hex:"39d353")],
        isDark: true
    )
    // ... all 14 themes
}
```

### Using Theme in Views

```swift
struct TimerView: View {
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack {
            theme.current.bg.ignoresSafeArea()
            Text("14:32")
                .foregroundColor(theme.current.text)
        }
    }
}
```

---

## Timer Screen

### TimerViewModel

```swift
@Observable
final class TimerViewModel {
    enum State { case idle, running, paused }

    var state: State = .idle
    var elapsed: TimeInterval = 0
    var targetDuration: TimeInterval = 15 * 60   // seconds
    var displayFormat: TimeFormat = .plainMinutes

    // Drum picker
    var selectedMinutes: Int = 15       // plain minutes mode
    var selectedHours: Int = 0          // HH:MM mode
    var selectedMMMinutes: Int = 15     // HH:MM mode

    private var timer: AnyCancellable?
    private var startDate: Date?

    // Computed
    var remaining: TimeInterval { max(0, targetDuration - elapsed) }
    var isCountdown: Bool { mode == .countdown }

    func start() {
        state = .running
        startDate = Date()
        metronome.start()
        heartRate.startMonitoring()
        motion.startTracking()
        startTimer()
        startLiveActivity()
    }

    func pause() {
        state = .paused
        timer?.cancel()
        metronome.pause()
    }

    func resume() {
        state = .running
        startTimer()
        metronome.resume()
    }

    func stop() {
        state = .idle
        timer?.cancel()
        metronome.stop()
        heartRate.stopMonitoring()
        motion.stopTracking()
        endLiveActivity()
        saveSession()
    }

    private func startTimer() {
        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let start = self.startDate else { return }
                self.elapsed = Date().timeIntervalSince(start)
                if self.isCountdown && self.elapsed >= self.targetDuration {
                    self.stop()
                }
            }
    }

    private func saveSession() {
        let session = RunSession(
            id: UUID(),
            startDate: startDate ?? Date(),
            duration: elapsed,
            distance: motion.distance,
            calories: motion.calories,
            steps: motion.steps,
            avgHR: heartRate.avgHR,
            maxHR: heartRate.maxHR,
            avgCadence: motion.avgCadence,
            bpm: metronome.bpm,
            characterId: profile.activeCharacterId,
            themeId: theme.current.id,
            mode: mode
        )
        modelContext.insert(session)
        try? modelContext.save()
        AppGroupDefaults.writeSessionSummaries(from: modelContext)
        WidgetCenter.shared.reloadAllTimelines()
        HealthKitService.shared.writeSession(session)
    }
}
```

### Drum Picker Gesture

```swift
struct DrumPickerView: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let stepHeight: CGFloat = 28

    @State private var dragOffset: CGFloat = 0
    @State private var startValue: Int = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Ghost above
                Text(displayString(value + 1))
                    .opacity(0.15)
                    .offset(y: -stepHeight)
                // Selected
                Text(displayString(value))
                    .scaleEffect(1.05)
                // Ghost below
                Text(displayString(value - 1))
                    .opacity(0.15)
                    .offset(y: stepHeight)
            }
            .gesture(
                DragGesture()
                    .onChanged { g in
                        let steps = Int(-g.translation.height / stepHeight)
                        let newVal = (startValue + steps).clamped(to: range)
                        value = newVal
                    }
                    .onEnded { _ in
                        startValue = value
                    }
            )
        }
    }
}
```

---

## Metronome Engine

### MetronomeService

Use `AVAudioEngine` for sub-millisecond scheduling accuracy.

```swift
@Observable
final class MetronomeService {
    var bpm: Int = 180
    var soundType: SoundType = .tap
    var volume: Float = 0.7
    var isPlaying: Bool = false

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var nextBeatTime: AVAudioTime?
    private var buffer: AVAudioPCMBuffer?

    init() {
        setupEngine()
        loadBuffer()
    }

    private func setupEngine() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        try? engine.start()
        // Keep audio session active during run / lock screen
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func loadBuffer() {
        // Load sound file matching soundType
        guard let url = Bundle.main.url(forResource: soundType.rawValue, withExtension: "wav"),
              let file = try? AVAudioFile(forReading: url) else { return }
        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)
        buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        try? file.read(into: buffer!)
    }

    func start() {
        isPlaying = true
        nextBeatTime = AVAudioTime(hostTime: mach_absolute_time())
        scheduleBeat()
    }

    private func scheduleBeat() {
        guard isPlaying, let buf = buffer, let beatTime = nextBeatTime else { return }
        player.scheduleBuffer(buf, at: beatTime, options: []) { [weak self] in
            self?.scheduleBeat()
        }
        player.play(at: beatTime)

        let beatInterval = 60.0 / Double(bpm)
        let hostTicksPerSecond = Double(mach_timebase_info_data_t().denom) /
                                 Double(mach_timebase_info_data_t().numer) * 1_000_000_000
        let ticksPerBeat = AVAudioFramePosition(beatInterval * hostTicksPerSecond)
        nextBeatTime = AVAudioTime(hostTime: beatTime.hostTime + UInt64(ticksPerBeat))
    }

    func stop() {
        isPlaying = false
        player.stop()
    }

    func pause() { player.pause() }
    func resume() { player.play() }

    func updateBPM(_ newBPM: Int) {
        bpm = newBPM
        // Next scheduled beat will use new interval automatically
    }
}
```

---

## Heart Rate

### Source Priority

```
1. Apple Watch (HealthKit HKAnchoredObjectQuery)
2. BLE heart rate monitor (CoreBluetooth)
3. None — hide HR row
```

### HeartRateService

```swift
@Observable
final class HeartRateService {
    var currentHR: Int = 0
    var avgHR: Int = 0
    var maxHR: Int = 0
    var source: HRSource = .none

    enum HRSource { case watch, ble, none }

    private var samples: [Int] = []
    private var anchoredQuery: HKAnchoredObjectQuery?
    private var bleManager: BLEHeartRateManager?

    func startMonitoring() {
        if HKHealthStore.isHealthDataAvailable() {
            startHealthKitQuery()
        } else {
            startBLEScan()
        }
    }

    private func startHealthKitQuery() {
        let type = HKQuantityType(.heartRate)
        var anchor: HKQueryAnchor?

        anchoredQuery = HKAnchoredObjectQuery(
            type: type,
            predicate: HKQuery.predicateForSamples(withStart: Date(), end: nil),
            anchor: anchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, newAnchor, _ in
            anchor = newAnchor
            self?.processSamples(samples as? [HKQuantitySample])
        }
        anchoredQuery!.updateHandler = { [weak self] _, samples, _, newAnchor, _ in
            anchor = newAnchor
            self?.processSamples(samples as? [HKQuantitySample])
        }
        HKHealthStore().execute(anchoredQuery!)
        source = .watch
    }

    private func processSamples(_ samples: [HKQuantitySample]?) {
        guard let samples else { return }
        let unit = HKUnit.count().unitDivided(by: .minute())
        for s in samples {
            let hr = Int(s.quantity.doubleValue(for: unit))
            currentHR = hr
            self.samples.append(hr)
            maxHR = max(maxHR, hr)
            avgHR = self.samples.reduce(0, +) / self.samples.count
        }
    }

    func stopMonitoring() {
        if let q = anchoredQuery { HKHealthStore().stop(q) }
        bleManager?.stop()
    }
}
```

### BLE Heart Rate (CoreBluetooth)

```swift
// Service UUID: 0x180D  Heart Rate Service
// Characteristic UUID: 0x2A37  Heart Rate Measurement
// Parse first byte flags, then byte 1 (uint8) or bytes 1-2 (uint16) for BPM
```

---

## Metrics: Distance, Steps, Calories

### MotionService

```swift
@Observable
final class MotionService {
    var steps: Int = 0
    var distance: Double = 0      // meters
    var calories: Double = 0      // kcal
    var avgCadence: Int = 0

    private let pedometer = CMPedometer()
    private var startDate: Date?

    func startTracking() {
        startDate = Date()
        guard CMPedometer.isStepCountingAvailable() else { return }
        pedometer.startUpdates(from: startDate!) { [weak self] data, _ in
            guard let self, let data else { return }
            DispatchQueue.main.async {
                self.steps = data.numberOfSteps.intValue
                self.distance = data.distance?.doubleValue ?? 0
                self.calories = self.estimateCalories(steps: self.steps)
                if let duration = data.endDate.flatMap({ $0.timeIntervalSince(self.startDate ?? $0) }),
                   duration > 0 {
                    self.avgCadence = Int(Double(self.steps) / (duration / 60))
                }
            }
        }
    }

    private func estimateCalories(steps: Int) -> Double {
        // MET for slow jog ≈ 4.5
        // Calories = MET × weight(kg) × duration(hours)
        // Approximation via steps: ~0.04 kcal/step for 65kg person
        let profile = UserProfile.shared
        let weightKg = profile?.weightKg ?? 65
        let strideM = (profile?.heightCm ?? 170) * 0.415 / 100
        let distKm = Double(steps) * strideM / 1000
        return distKm * weightKg * 1.036  // standard formula
    }

    func stopTracking() {
        pedometer.stopUpdates()
    }
}
```

---

## Report Screen

### ReportViewModel

```swift
@Observable
final class ReportViewModel {
    var period: ReportPeriod = .week
    var selectedMetric: ReportMetric = .distance
    var currentOffset: Int = 0   // 0 = current period, -1 = previous, etc.

    enum ReportPeriod { case day, week, month, year }
    enum ReportMetric { case distance, calories, steps, hrAvg, hrMax, cadence }

    private var sessions: [RunSession] = []

    // Date range for current offset
    var dateRange: (start: Date, end: Date) { ... }
    var dateRangeLabel: String { ... }

    // Hero value (always duration)
    var heroDuration: TimeInterval {
        sessions.filter { dateRange.start...dateRange.end ~= $0.startDate }
                .reduce(0) { $0 + $1.duration }
    }

    // Metric cards
    var cardValues: ReportCardValues { ... }

    // Chart data
    var chartBars: [ChartBar] { ... }

    // Log items
    var logItems: [LogItem] { ... }

    func fetchSessions(context: ModelContext) {
        let descriptor = FetchDescriptor<RunSession>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        sessions = (try? context.fetch(descriptor)) ?? []
    }
}

struct ChartBar {
    let label: String
    let value: Double
    let isToday: Bool
}
```

---

## Widget Extension

### App Group Data Write (main app)

```swift
struct AppGroupDefaults {
    static let suiteName = "group.com.yourname.jog"
    static var shared = UserDefaults(suiteName: suiteName)!

    static func writeSessionSummaries(from context: ModelContext) {
        let descriptor = FetchDescriptor<RunSession>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)],
            fetchLimit: 400   // ~13 months of daily sessions
        )
        guard let sessions = try? context.fetch(descriptor) else { return }
        let summaries = sessions.map { DaySessionSummary(from: $0) }
        let data = try? JSONEncoder().encode(summaries)
        shared.set(data, forKey: "sessionSummaries")
        shared.set(Date(), forKey: "lastUpdated")
    }
}

struct DaySessionSummary: Codable {
    let date: Date
    let duration: TimeInterval
    let completionRatio: Double  // 0.0–1.0
    let hrAvg: Int
    let steps: Int
}
```

### Widget Timeline Provider

```swift
struct HeatmapProvider: IntentTimelineProvider {
    typealias Intent = JogWidgetConfigIntent
    typealias Entry = HeatmapEntry

    func getTimeline(for configuration: JogWidgetConfigIntent,
                     in context: Context,
                     completion: @escaping (Timeline<HeatmapEntry>) -> Void) {

        let summaries = AppGroupDefaults.loadSummaries()
        let themeId = AppGroupDefaults.shared.string(forKey: "activeThemeId") ?? "obsidian"
        let theme = ThemeLibrary.all.first { $0.id == themeId } ?? ThemeLibrary.obsidian

        let entry = HeatmapEntry(
            date: Date(),
            summaries: summaries,
            configuration: configuration,
            theme: theme
        )

        // Refresh hourly
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}
```

### Widget Configuration Intent

```swift
struct JogWidgetConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Jog Widget"

    @Parameter(title: "Colour Theme", default: "app")
    var colorTheme: String      // "app" = inherit from main app

    @Parameter(title: "Threshold 1 (%)", default: 10)
    var threshold1: Int

    @Parameter(title: "Threshold 2 (%)", default: 50)
    var threshold2: Int

    @Parameter(title: "Threshold 3 (%)", default: 90)
    var threshold3: Int

    @Parameter(title: "Cell Info", default: .duration)
    var cellInfo: WidgetCellInfo

    @Parameter(title: "Show Day Numbers", default: true)
    var showDayNumbers: Bool

    @Parameter(title: "Show Streak", default: true)
    var showStreak: Bool

    @Parameter(title: "Show Total Time", default: true)
    var showTotalTime: Bool
}
```

### Colour Scale Helper

```swift
func barColor(for ratio: Double, theme: ThemeTokens, t1: Int, t2: Int, t3: Int) -> Color {
    let pct = Int(ratio * 100)
    switch pct {
    case 0:       return theme.cal[0]
    case 1..<t2:  return theme.cal[1]
    case t2..<t3: return theme.cal[2]
    case t3..<100: return theme.cal[3]
    default:      return theme.cal[4]
    }
}
```

---

## Dynamic Island & Live Activity

### Attributes

```swift
struct JogLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var elapsed: TimeInterval
        var remaining: TimeInterval    // 0 if stopwatch mode
        var bpm: Int
        var characterId: String
        var themeId: String
        var isCountdown: Bool
    }
}
```

### Start / Update / End

```swift
final class LiveActivityService {
    private var activity: Activity<JogLiveActivityAttributes>?

    func start(bpm: Int, target: TimeInterval, characterId: String, themeId: String) {
        let attrs = JogLiveActivityAttributes()
        let state = JogLiveActivityAttributes.ContentState(
            elapsed: 0,
            remaining: target,
            bpm: bpm,
            characterId: characterId,
            themeId: themeId,
            isCountdown: true
        )
        activity = try? Activity.request(attributes: attrs, contentState: state,
                                          pushType: nil)
    }

    func update(elapsed: TimeInterval, remaining: TimeInterval) {
        guard let activity else { return }
        Task {
            let state = JogLiveActivityAttributes.ContentState(
                elapsed: elapsed,
                remaining: remaining,
                bpm: activity.contentState.bpm,
                characterId: activity.contentState.characterId,
                themeId: activity.contentState.themeId,
                isCountdown: activity.contentState.isCountdown
            )
            await activity.update(using: state)
        }
    }

    func end() {
        Task { await activity?.end(dismissalPolicy: .immediate) }
        activity = nil
    }
}
```

### Dynamic Island View

```swift
struct JogDynamicIslandCompactView: View {
    let state: JogLiveActivityAttributes.ContentState
    let theme: ThemeTokens

    var body: some View {
        HStack {
            // Character (left)
            LottieView(name: state.characterId, color: theme.accentMid)
                .frame(width: 22, height: 22)
            Spacer()
            // Time (right)
            Text(formattedTime)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(theme.text)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
    }
}
```

---

## Settings

Settings are stored in `UserProfile` (SwiftData) and mirrored to `UserDefaults` for quick access. Widget-relevant keys are also written to App Group UserDefaults.

### Keys written to App Group

```
activeThemeId        String
dailyGoalMinutes     Int
sessionSummaries     Data (JSON-encoded [DaySessionSummary])
lastUpdated          Date
```

---

## Character Animation

### Lottie Integration

```swift
import Lottie

struct LottieView: UIViewRepresentable {
    let name: String
    let color: Color
    var speed: Double = 1.0   // adjust based on BPM

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: name)
        view.loopMode = .loop
        view.contentMode = .scaleAspectFit
        return view
    }

    func updateUIView(_ view: LottieAnimationView, context: Context) {
        view.animationSpeed = speed
        // Override fill color using value provider
        let provider = ColorValueProvider(color.lottieColor)
        view.setValueProvider(provider, keypath: AnimationKeypath(keypath: "**.Fill 1.Color"))
        if !view.isAnimationPlaying { view.play() }
    }
}
```

### Speed Calculation

```swift
// Normalize to 180 BPM baseline (animations authored at 180 BPM)
var lottieSpeed: Double {
    Double(metronome.bpm) / 180.0
}
```

---

## Summary Screen

```swift
@Observable
final class SummaryViewModel {
    let session: RunSession

    var streakDays: Int {
        // Count consecutive days ending today with duration >= dailyGoal
        ...
    }

    var thisWeekDots: [DotState] {
        // Last 7 days, each: .empty / .partial / .achieved
        ...
    }

    func generateShareImage() -> UIImage {
        // Render a SwiftUI view to UIImage using ImageRenderer
        let renderer = ImageRenderer(content: ShareCardView(session: session, theme: theme))
        return renderer.uiImage ?? UIImage()
    }
}

enum DotState { case empty, partial, achieved }
```

---

## Localization

### String Keys

```swift
// en
"timer.mode.countdown"    = "Countdown"
"timer.mode.stopwatch"    = "Stopwatch"
"report.tab.day"          = "Day"
"report.tab.week"         = "Week"
"report.metric.duration"  = "Duration"
"report.metric.distance"  = "Distance"
"report.metric.calories"  = "Calories"
"report.metric.steps"     = "Steps"
"report.metric.avgHR"     = "Avg HR"
"report.metric.maxHR"     = "Max HR"
"report.metric.cadence"   = "Avg Cadence"
"settings.appearance"     = "Appearance"
"settings.language"       = "Language"
"summary.done"            = "Done"
"summary.share"           = "Share"
// ... (full key list in Localizable.strings)
```

```swift
// zh-Hant
"timer.mode.countdown"    = "倒數"
"timer.mode.stopwatch"    = "計時"
"report.tab.day"          = "日"
"report.tab.week"         = "週"
"report.metric.duration"  = "時長"
"report.metric.distance"  = "距離"
"report.metric.calories"  = "熱量"
"report.metric.steps"     = "步數"
"report.metric.avgHR"     = "平均心率"
"report.metric.maxHR"     = "最高心率"
"report.metric.cadence"   = "平均步頻"
"settings.appearance"     = "外觀"
"settings.language"       = "語言"
"summary.done"            = "完成"
"summary.share"           = "分享"
```

### Language Switching (Runtime)

App language switch without killing the app — override `Bundle.main` via a custom bundle subclass:

```swift
final class LanguageManager: ObservableObject {
    @Published var language: AppLanguage = .english {
        didSet { Bundle.setLanguage(language.code) }
    }
}
```

---

## HealthKit Integration

### Permissions Request

```swift
func requestPermissions() async throws {
    let store = HKHealthStore()
    let read: Set<HKObjectType> = [
        HKQuantityType(.heartRate),
        HKQuantityType(.bodyMass),
        HKQuantityType(.height)
    ]
    let write: Set<HKSampleType> = [
        HKWorkoutType.workoutType(),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.heartRate)
    ]
    try await store.requestAuthorization(toShare: write, read: read)
}
```

### Write Session

```swift
func writeSession(_ session: RunSession) {
    guard UserProfile.shared?.healthKitEnabled == true else { return }
    let store = HKHealthStore()
    let builder = HKWorkoutBuilder(healthStore: store,
                                   configuration: HKWorkoutConfiguration(),
                                   device: nil)
    Task {
        try await builder.beginCollection(at: session.startDate)
        // Add calorie sample
        let energySample = HKQuantitySample(
            type: HKQuantityType(.activeEnergyBurned),
            quantity: HKQuantity(unit: .kilocalorie(), doubleValue: session.calories),
            start: session.startDate,
            end: session.startDate.addingTimeInterval(session.duration)
        )
        try await builder.addSamples([energySample])
        try await builder.endCollection(at: session.startDate.addingTimeInterval(session.duration))
        try await builder.finishWorkout()
    }
}
```

---

## iCloud Sync

SwiftData with CloudKit is enabled by passing a `ModelConfiguration` with `cloudKitDatabase`:

```swift
let config = ModelConfiguration(
    schema: Schema([RunSession.self, UserProfile.self, ThresholdConfig.self]),
    cloudKitDatabase: .automatic
)
let container = try ModelContainer(for: config)
```

Sync is automatic when iCloud is signed in. If `iCloudEnabled` is false in UserProfile, use a local-only config instead:

```swift
let config = ModelConfiguration(isStoredInMemoryOnly: false)
```

---

## Notifications

```swift
func scheduleDaily(hour: Int, minute: Int) {
    let center = UNUserNotificationCenter.current()
    let content = UNMutableNotificationContent()
    content.title = NSLocalizedString("notif.title", comment: "")
    content.body  = NSLocalizedString("notif.body", comment: "")
    content.sound = .default

    var components = DateComponents()
    components.hour = hour
    components.minute = minute

    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    let request = UNNotificationRequest(identifier: "daily-reminder",
                                         content: content,
                                         trigger: trigger)
    center.removePendingNotificationRequests(withIdentifiers: ["daily-reminder"])
    center.add(request)
}
```

---

## Testing Checklist

### Unit Tests
- [ ] `ThemeLibrary` — all 14 themes have exactly 5 `bar` and 5 `cal` entries
- [ ] `barColor(for:theme:t1:t2:t3:)` — boundary conditions (0%, T1, T2, T3, 100%)
- [ ] `MotionService.estimateCalories` — sample inputs vs expected range
- [ ] `ReportViewModel` — hero duration aggregation per period
- [ ] `DaySessionSummary` encode/decode round-trip

### Integration Tests
- [ ] Session save → App Group write → Widget reads updated data
- [ ] Theme change → WidgetCenter reloadAllTimelines called
- [ ] HealthKit write — verify sample appears in Health app (on device)

### Manual QA
- [ ] Long-press stop: arc fills in ~2 s, release early cancels
- [ ] BPM panel: ±1 / ±5 buttons stay within 140–220 range
- [ ] Drum picker: ghost numerals update during drag, snap on release
- [ ] Dynamic Island: compact shows char + time; expanded shows label + time + char + BPM
- [ ] Lock Screen Live Activity: appears on lock screen during run, dismisses on stop
- [ ] All 14 themes: no hardcoded color visible (check Report bars, Widget heatmap, Summary dots)
- [ ] Language switch: all strings update without app restart
- [ ] Widget long-press edit: threshold slider thumbs enforce minimum gap
- [ ] Heart rate: hidden when no Watch / BLE source detected
- [ ] iCloud: session created on device A appears on device B after sync

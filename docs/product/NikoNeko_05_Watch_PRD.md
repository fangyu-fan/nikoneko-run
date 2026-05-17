# NIKO NEKO — Apple Watch PRD

> Watch companion spec for NIKO NEKO v1.0  
> Primary device: iPhone · Watch role: companion + independent start

---

## Table of Contents

1. [Overview](#overview)
2. [Design Principles](#design-principles)
3. [Feature List](#feature-list)
4. [Watch App Screens](#watch-app-screens)
5. [Haptic Metronome](#haptic-metronome)
6. [Heart Rate Integration](#heart-rate-integration)
7. [Complications](#complications)
8. [iPhone ↔ Watch Sync](#iphone--watch-sync)
9. [Independent Mode](#independent-mode)
10. [Workout Session](#workout-session)
11. [Tech Stack](#tech-stack)
12. [Out of Scope](#out-of-scope)

---

## Overview

### Role

The Watch app is a **companion** to the iPhone app. The iPhone is the primary experience — settings, report, themes, characters are all managed there. The Watch extends the experience to the wrist:

- Start a run directly from Watch without touching iPhone
- Feel the metronome beat via Taptic Engine (silent running)
- Glance at time + heart rate without raising iPhone
- Show streak and stats on watch face via Complications

### Summary Table

| Capability | Watch | iPhone |
|------------|-------|--------|
| Start / stop run | ✓ | ✓ |
| Set duration | ✓ (limited) | ✓ (full drum picker) |
| Adjust BPM | ✓ (±1 / ±5) | ✓ |
| Haptic metronome | ✓ | — |
| Audio metronome | — | ✓ |
| Live heart rate | ✓ (source) | ✓ (display) |
| Live metrics | ✓ (minimal) | ✓ (full) |
| Report / charts | — | ✓ |
| Settings | — | ✓ |
| Themes | Inherits from iPhone | ✓ |
| Character animation | ✓ (complication) | ✓ |
| Complications | ✓ | — |

---

## Design Principles

**Watch = wrist glance, not wrist screen.**
Every Watch screen should be readable in under 2 seconds with one eye. No scrolling during a run.

**Haptic replaces audio.**
The Watch's Taptic Engine is the metronome when running with Watch. No sound needed — pure wrist rhythm.

**Inherit the iPhone's theme.**
Watch UI uses the same active theme colors from the iPhone. No separate theme picker on Watch.

**Minimal input on Watch.**
Only the most essential controls — start, stop, BPM adjust. Everything complex stays on iPhone.

**The cat runs on your wrist.**
The character animation on the complication is the Watch's signature delight — tiny, looping, always running.

---

## Feature List

### v1.0 Scope

| # | Feature | Priority |
|---|---------|----------|
| 1 | Watch timer screen (countdown + stopwatch) | Must |
| 2 | Start / stop run from Watch | Must |
| 3 | Haptic metronome (every beat) | Must |
| 4 | Live heart rate display | Must |
| 5 | Quick duration picker (preset options) | Must |
| 6 | BPM adjust on Watch | Must |
| 7 | Session auto-syncs to iPhone on end | Must |
| 8 | Complication: Streak count | Must |
| 9 | Complication: Running cat animation | Must |
| 10 | Complication: Today's duration | Must |
| 11 | Independent mode (no iPhone nearby) | Should |
| 12 | Complication: Heatmap mini | Nice |

---

## Watch App Screens

### Screen 1 — Idle / Setup

```
┌─────────────────────┐
│                     │
│   [cat animation]   │
│                     │
│        15           │  ← duration (tap to change)
│       min           │
│                     │
│    ♩ 180            │  ← BPM (tap to adjust)
│                     │
│      [ ▶ ]          │  ← start button
│                     │
└─────────────────────┘
```

- Cat animation runs at idle speed (slower than BPM)
- Duration tap → simple picker (preset options: 10 / 15 / 20 / 25 / 30 min)
- BPM tap → ±1 / ±5 buttons inline
- Uses iPhone's last-used duration and BPM as defaults
- Theme colors inherited from iPhone

### Screen 2 — Running

```
┌─────────────────────┐
│                     │
│   [cat animation]   │  ← speed synced to BPM
│                     │
│       12:47         │  ← time remaining (countdown)
│                     │
│   ♥ 124   ♩ 180    │  ← heart rate + BPM
│                     │
│      [ ■ ]          │  ← long-press 2s to stop
│                     │
└─────────────────────┘
```

- Cat animation speed = BPM / 180 (normalized)
- Time display matches iPhone format preference (plain min or HH:MM)
- Heart rate updates live from Watch sensor
- Double-tap Digital Crown = pause / resume
- Long-press ■ = stop (same 2-second mechanic as iPhone)

### Screen 3 — Summary (Watch)

```
┌─────────────────────┐
│                     │
│   [cat animation]   │  ← celebratory, faster
│                     │
│        21           │
│       min           │
│                     │
│  ♥ 122   ⊞ 3,780   │
│                     │
│      [ Done ]       │
│                     │
└─────────────────────┘
```

- Shown immediately after run ends on Watch
- Minimal — duration, avg HR, steps
- "Done" dismisses to idle screen
- Full summary visible on iPhone

### Screen 4 — BPM Adjust (inline panel)

Appears as a sheet when BPM row is tapped on idle screen:

```
┌─────────────────────┐
│     Step Pace       │
│                     │
│       180           │  ← large numeral
│                     │
│  [−5] [−1] [+1] [+5]│
│                     │
│      [ OK ]         │
└─────────────────────┘
```

### Screen 5 — Duration Picker

Appears as a list when duration is tapped:

```
┌─────────────────────┐
│   Duration          │
│ ─────────────────── │
│    10 min           │
│  ▶ 15 min           │  ← current selection
│    20 min           │
│    25 min           │
│    30 min           │
│    45 min           │
│    60 min           │
└─────────────────────┘
```

Digital Crown scroll to navigate. Tap to select and return.

---

## Haptic Metronome

### Concept

Every metronome beat triggers a Taptic Engine pulse on the Watch. The user feels the 180 BPM rhythm on their wrist — no sound required. Ideal for:

- Indoor running without disturbing others
- Running with music (no metronome audio overlay)
- Users who prefer silent environments

### Implementation

```swift
final class WatchHapticMetronome {
    private let device = WKInterfaceDevice.current()
    private var timer: Timer?
    var bpm: Int = 180

    func start() {
        let interval = 60.0 / Double(bpm)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.device.play(.click)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func updateBPM(_ newBPM: Int) {
        bpm = newBPM
        stop()
        start()
    }
}
```

### Haptic Type

`WKHapticType.click` — short, crisp tap. Matches the "叩" sound type in spirit.

Do not use `.notification` or `.success` — those are too heavy for a repeating rhythm.

### Haptic + Audio Relationship

| Scenario | Haptic | Audio |
|----------|--------|-------|
| Run started from Watch | ✓ On | ✗ Off |
| Run started from iPhone, Watch connected | ✓ On | ✓ On (iPhone speaker) |
| Run started from iPhone, Watch not worn | ✗ Off | ✓ On |

User can override haptic on/off in iPhone Settings → Display.

### Battery Consideration

Continuous haptic at 180 BPM for 30 minutes = ~5,400 pulses. In testing, this adds approximately 3–5% battery per 30 min session. Acceptable for typical session lengths.

---

## Heart Rate Integration

### Watch as HR Source

When Apple Watch is worn and connected:

1. watchOS `HKWorkoutSession` automatically measures HR continuously
2. HR samples sent to iPhone via `WCSession` (Watch Connectivity) every ~5 s
3. iPhone `HeartRateService` receives updates and displays on timer screen
4. No need for separate HealthKit query on iPhone side during active session

### Data Flow

```
Watch sensor
    → HKWorkoutSession (watchOS)
        → WCSession.transferUserInfo (every 5s)
            → iPhone HeartRateService
                → TimerViewModel.currentHR
                    → Timer screen display
```

### Fallback

If Watch is not connected or not worn:
1. Try CoreBluetooth BLE heart rate monitor
2. If none available → hide HR row entirely (no "—" placeholder)

---

## Complications

### Overview

Four complication slots defined. User chooses which to place on their watch face.

### Complication 1 — Running Cat (Graphic Corner / Modular Small)

```
┌──────┐
│ /\/\ │  ← animated cat silhouette
│ running │
└──────┘
```

- Size: Graphic Corner, Graphic Circular, Modular Small
- Content: Looping cat animation (2-frame, same as in-app character)
- Animation speed: matches last-used BPM when a run is active; idle speed otherwise
- Color: `accentMid` from active theme
- Tap: launches Watch app

**This is the signature complication.** A tiny running cat on your watch face.

### Complication 2 — Streak Count (Circular Small / Modular Small)

```
┌──────┐
│  12  │
│ days │
└──────┘
```

- Size: Circular Small, Modular Small, Graphic Circular
- Content: Current streak day count + "days" label
- Color: `accent` from active theme
- Updates: After each session save
- Tap: launches Watch app

### Complication 3 — Today's Duration (Modular Small / Graphic Corner)

```
┌──────┐
│  21  │
│  min │
└──────┘
```

- Content: Today's total jogging duration in minutes
- If no run today: shows "0 min" or "—"
- Updates: After each session save
- Tap: launches Watch app

### Complication 4 — Mini Heatmap (Graphic Rectangular)

```
┌────────────────────────┐
│ NIKO NEKO   ▪▪▪▪▪▫▫   │
│ 12 day streak   21min  │
└────────────────────────┘
```

- Size: Graphic Rectangular only
- Content: Last 7-day heatmap dots + streak + today's duration
- Dot colors: `cal[n]` from active theme
- Tap: launches Watch app

### Complication Data Source

```swift
struct NikoNekoComplicationProvider: TimelineProvider {

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<ComplicationEntry>) -> Void) {

        let data = AppGroupDefaults.loadSummaries()
        let streak = calculateStreak(from: data)
        let todayDuration = todayTotalMinutes(from: data)
        let themeId = AppGroupDefaults.shared.string(forKey: "activeThemeId") ?? "obsidian"

        let entry = ComplicationEntry(
            date: Date(),
            streakDays: streak,
            todayMinutes: todayDuration,
            recentDays: Array(data.prefix(7)),
            themeId: themeId
        )

        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}
```

---

## iPhone ↔ Watch Sync

### WatchConnectivity Session

```swift
// iPhone side
final class PhoneSessionDelegate: NSObject, WCSessionDelegate {
    func session(_ session: WCSession,
                 didReceiveUserInfo userInfo: [String: Any]) {
        // Receive completed session data from Watch
        if let sessionData = userInfo["completedSession"] as? Data,
           let session = try? JSONDecoder().decode(RunSession.self, from: sessionData) {
            modelContext.insert(session)
            try? modelContext.save()
            AppGroupDefaults.writeSessionSummaries(from: modelContext)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        // Receive live HR updates during run
        if let hr = message["heartRate"] as? Int {
            heartRateService.currentHR = hr
        }
    }
}
```

```swift
// Watch side
final class WatchSessionDelegate: NSObject, WCSessionDelegate {

    func sendHeartRate(_ hr: Int) {
        WCSession.default.sendMessage(
            ["heartRate": hr],
            replyHandler: nil,
            errorHandler: nil
        )
    }

    func sendCompletedSession(_ session: RunSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        WCSession.default.transferUserInfo(["completedSession": data])
    }
}
```

### Sync Rules

| Event | Direction | Method |
|-------|-----------|--------|
| Run started on Watch | Watch → iPhone | `sendMessage` (real-time) |
| HR update (every 5 s) | Watch → iPhone | `sendMessage` |
| Session ended on Watch | Watch → iPhone | `transferUserInfo` (reliable) |
| Settings changed on iPhone | iPhone → Watch | `updateApplicationContext` |
| Theme changed | iPhone → Watch | `updateApplicationContext` |
| Active character changed | iPhone → Watch | `updateApplicationContext` |

### Settings Sync (iPhone → Watch)

When user changes settings on iPhone, push to Watch:

```swift
let context: [String: Any] = [
    "themeId": profile.activeThemeId,
    "characterId": profile.activeCharacterId,
    "defaultBPM": profile.defaultBPM,
    "defaultDuration": profile.defaultDuration,
    "hapticEnabled": profile.hapticEnabled,
    "timeFormat": profile.timeDisplayFormat.rawValue
]
try? WCSession.default.updateApplicationContext(context)
```

---

## Independent Mode

### When iPhone is not nearby

The Watch app can start and complete a run without iPhone present:

1. Watch uses last-synced settings (theme, BPM, duration)
2. HR measured locally by Watch sensor
3. Steps and distance via Watch's own CMPedometer
4. Session stored locally on Watch (WKExtension UserDefaults or Core Data)
5. When iPhone reconnects → session transferred via `transferUserInfo`

### Limitations in Independent Mode

| Feature | Available |
|---------|-----------|
| Haptic metronome | ✓ |
| Heart rate | ✓ (Watch sensor) |
| Steps / distance | ✓ |
| Session save | ✓ (local, syncs later) |
| Theme colors | ✓ (last synced) |
| Character animation | ✓ (last synced) |
| Audio metronome | ✗ |
| Full settings | ✗ |
| Report view | ✗ |

---

## Workout Session

### HKWorkoutSession

To enable continuous HR measurement and proper HealthKit workout recording on Watch:

```swift
func startWorkoutSession() {
    let config = HKWorkoutConfiguration()
    config.activityType = .running
    config.locationType = .indoor   // slow jog is often indoor

    do {
        workoutSession = try HKWorkoutSession(
            healthStore: healthStore,
            configuration: config
        )
        workoutBuilder = workoutSession.associatedWorkoutBuilder()
        workoutBuilder.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: config
        )
        workoutSession.delegate = self
        workoutBuilder.delegate = self

        workoutSession.startActivity(with: Date())
        workoutBuilder.beginCollection(withStart: Date()) { _, _ in }
    } catch {
        // Fall back to timer-only mode
    }
}

func endWorkoutSession() {
    workoutSession.end()
    workoutBuilder.endCollection(withEnd: Date()) { [weak self] _, _ in
        self?.workoutBuilder.finishWorkout { workout, _ in
            // workout written to HealthKit automatically
        }
    }
}
```

### Why HKWorkoutSession

- Keeps Watch app active in foreground during run (no suspension)
- Enables continuous HR measurement (not just spot checks)
- Writes a proper Workout record to HealthKit (appears in Fitness app)
- Enables "workout" detection — Watch won't prompt "it looks like you started a workout"

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Watch UI | SwiftUI (watchOS 10+) |
| Workout tracking | HealthKit HKWorkoutSession |
| Haptic | WKInterfaceDevice.play(.click) |
| iPhone ↔ Watch | WatchConnectivity (WCSession) |
| Complications | ClockKit + WidgetKit (watchOS 9+) |
| Independent storage | UserDefaults (Watch) + transferUserInfo queue |
| Animation | Lottie (watchOS support via SPM) |
| Shared data | App Group (same group.com.yourname.nikoneko) |

### Minimum OS

| Platform | Version |
|----------|---------|
| watchOS | 10.0 |
| iOS (paired) | 17.0 |

---

## Out of Scope (v1.0)

| Feature | Reason |
|---------|--------|
| Standalone Watch app (no iPhone ever needed) | Settings and report must live on iPhone |
| GPS route tracking | Slow jog is typically indoor / track — GPS adds battery drain without value |
| Watch report / charts | Screen too small; iPhone handles this |
| Watch settings UI | Complexity not worth it; use iPhone |
| Audio on Watch speaker | Tinny quality; haptic is superior on Watch |
| Cellular Watch support | Adds complexity; paired iPhone covers the use case |
| Watch App Clips | N/A |

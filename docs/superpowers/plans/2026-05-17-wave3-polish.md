# Wave 3 — Polish & Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add localization, HealthKit write, iCloud sync, notifications, and a complete test suite. All tasks run in parallel — each is independent.

**Architecture:** All tasks are fully parallel. None depend on each other within Wave 3. Each sub-agent should receive only its own task section.

**Tech Stack:** Swift, Foundation, HealthKit, CloudKit, UserNotifications, XCTest

**Prerequisites:** All Wave 0, 1, and 2 tasks merged and passing `make test`.

---

## Task I-01 + I-02: Localization

**Files:**
- Create: `Resources/en.lproj/Localizable.strings`
- Create: `Resources/zh-Hant.lproj/Localizable.strings`
- Create: `Core/LanguageManager.swift`

- [ ] **Step 1: Create en strings**

  `Resources/en.lproj/Localizable.strings`:
  ```
  /* Timer */
  "timer.mode.countdown"    = "Countdown";
  "timer.mode.stopwatch"    = "Stopwatch";
  "timer.action.start"      = "Start";
  "timer.action.stop"       = "Hold to stop";
  "timer.action.pause"      = "Paused";

  /* Report tabs */
  "report.tab.day"          = "Day";
  "report.tab.week"         = "Week";
  "report.tab.month"        = "Month";
  "report.tab.year"         = "Year";

  /* Metrics */
  "report.metric.duration"  = "Duration";
  "report.metric.distance"  = "Distance";
  "report.metric.calories"  = "Calories";
  "report.metric.steps"     = "Steps";
  "report.metric.avgHR"     = "Avg HR";
  "report.metric.maxHR"     = "Max HR";
  "report.metric.cadence"   = "Avg Cadence";

  /* Summary */
  "summary.done"            = "Done";
  "summary.share"           = "Share";
  "summary.streak"          = "day streak";
  "summary.goalReached"     = "Goal reached";
  "summary.noRuns"          = "No runs yet";

  /* Settings */
  "settings.appearance"     = "Appearance";
  "settings.display"        = "Display";
  "settings.defaults"       = "Defaults";
  "settings.widget"         = "Widget";
  "settings.notifications"  = "Notifications";
  "settings.dataSync"       = "Data & Sync";
  "settings.language"       = "Language";
  "settings.theme"          = "Theme";

  /* Notifications */
  "notif.title"             = "Time to run.";
  "notif.body"              = "Your slow jog is waiting.";

  /* Errors */
  "error.saveFailed"        = "Couldn't save. Try again.";
  "error.healthkit"         = "Health access unavailable.";
  ```

- [ ] **Step 2: Create zh-Hant strings**

  `Resources/zh-Hant.lproj/Localizable.strings`:
  ```
  /* Timer */
  "timer.mode.countdown"    = "倒數";
  "timer.mode.stopwatch"    = "計時";
  "timer.action.start"      = "開始";
  "timer.action.stop"       = "長按結束";
  "timer.action.pause"      = "已暫停";

  /* Report tabs */
  "report.tab.day"          = "日";
  "report.tab.week"         = "週";
  "report.tab.month"        = "月";
  "report.tab.year"         = "年";

  /* Metrics */
  "report.metric.duration"  = "時長";
  "report.metric.distance"  = "距離";
  "report.metric.calories"  = "熱量";
  "report.metric.steps"     = "步數";
  "report.metric.avgHR"     = "平均心率";
  "report.metric.maxHR"     = "最高心率";
  "report.metric.cadence"   = "平均步頻";

  /* Summary */
  "summary.done"            = "完成";
  "summary.share"           = "分享";
  "summary.streak"          = "天連跑";
  "summary.goalReached"     = "達標";
  "summary.noRuns"          = "還沒有紀錄";

  /* Settings */
  "settings.appearance"     = "外觀";
  "settings.display"        = "顯示";
  "settings.defaults"       = "預設值";
  "settings.widget"         = "小工具";
  "settings.notifications"  = "通知";
  "settings.dataSync"       = "資料與同步";
  "settings.language"       = "語言";
  "settings.theme"          = "主題";

  /* Notifications */
  "notif.title"             = "該去跑步了";
  "notif.body"              = "今天的慢跑等著你。";

  /* Errors */
  "error.saveFailed"        = "儲存失敗，請再試一次。";
  "error.healthkit"         = "無法存取健康資料。";
  ```

- [ ] **Step 3: Implement LanguageManager**

  `Core/LanguageManager.swift`:
  ```swift
  import Foundation

  final class LanguageBundle: Bundle, @unchecked Sendable {
      static var languageCode: String = "en"

      override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
          guard let path = Bundle.main.path(forResource: Self.languageCode, ofType: "lproj"),
                let bundle = Bundle(path: path) else {
              return super.localizedString(forKey: key, value: value, table: tableName)
          }
          return bundle.localizedString(forKey: key, value: value, table: tableName)
      }
  }

  @Observable
  final class LanguageManager {
      var language: AppLanguage = .english {
          didSet {
              LanguageBundle.languageCode = language.code
              // Swap Bundle.main via method swizzling
              object_setClass(Bundle.main, LanguageBundle.self)
          }
      }

      init() {
          object_setClass(Bundle.main, LanguageBundle.self)
      }

      func apply(_ lang: AppLanguage) {
          language = lang
          LanguageBundle.languageCode = lang.code
      }
  }
  ```

- [ ] **Step 4: Wire LanguageManager into NikoNekoApp**

  In `App/NikoNekoApp.swift`, add `@State private var languageManager = LanguageManager()` and inject via `.environment(languageManager)`.

- [ ] **Step 5: Build check**

  ```bash
  make build 2>&1 | tail -5
  ```

- [ ] **Step 6: Commit**

  ```bash
  git add Resources/ Core/LanguageManager.swift App/NikoNekoApp.swift
  git commit -m "feat(I-01,I-02): Localizable.strings en+zh-Hant (all keys), LanguageManager runtime switch"
  ```

---

## Task K-01: HealthKitService Write

**Files:**
- Create: `Services/HealthKitService.swift`

- [ ] **Step 1: Implement HealthKitService**

  `Services/HealthKitService.swift`:
  ```swift
  import HealthKit

  @Observable
  final class HealthKitService {
      static let shared = HealthKitService()
      private let store = HKHealthStore()

      func requestPermissions() async {
          guard HKHealthStore.isHealthDataAvailable() else { return }
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
          try? await store.requestAuthorization(toShare: write, read: read)
      }

      func writeSession(_ session: RunSession) {
          guard session.duration > 0 else { return }
          Task {
              let config = HKWorkoutConfiguration()
              config.activityType = .running

              let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: nil)
              let start = session.startDate
              let end = start.addingTimeInterval(session.duration)

              try? await builder.beginCollection(at: start)

              if session.calories > 0 {
                  let energySample = HKQuantitySample(
                      type: HKQuantityType(.activeEnergyBurned),
                      quantity: HKQuantity(unit: .kilocalorie(), doubleValue: session.calories),
                      start: start, end: end
                  )
                  try? await builder.addSamples([energySample])
              }

              if session.distance > 0 {
                  let distSample = HKQuantitySample(
                      type: HKQuantityType(.distanceWalkingRunning),
                      quantity: HKQuantity(unit: .meter(), doubleValue: session.distance),
                      start: start, end: end
                  )
                  try? await builder.addSamples([distSample])
              }

              try? await builder.endCollection(at: end)
              try? await builder.finishWorkout()
          }
      }

      func exportCSV(sessions: [RunSession]) -> URL? {
          var csv = "Date,Duration(min),Distance(km),Calories,Steps,AvgHR,MaxHR,BPM\n"
          let df = ISO8601DateFormatter()
          for s in sessions {
              csv += "\(df.string(from: s.startDate)),"
              csv += "\(Int(s.duration / 60)),"
              csv += String(format: "%.2f", s.distance / 1000) + ","
              csv += "\(Int(s.calories)),"
              csv += "\(s.steps),"
              csv += "\(s.avgHR),"
              csv += "\(s.maxHR),"
              csv += "\(s.bpm)\n"
          }
          let url = FileManager.default.temporaryDirectory.appendingPathComponent("jog_export.csv")
          try? csv.write(to: url, atomically: true, encoding: .utf8)
          return url
      }
  }
  ```

- [ ] **Step 2: Wire into TimerViewModel.stopAndSave**

  In `Features/Timer/TimerViewModel.swift`, after `onSessionSaved?(session)`:
  ```swift
  Task { await HealthKitService.shared.writeSession(session) }
  ```

- [ ] **Step 3: Build check**

  ```bash
  make build 2>&1 | tail -5
  ```

- [ ] **Step 4: Commit**

  ```bash
  git add Services/HealthKitService.swift Features/Timer/TimerViewModel.swift
  git commit -m "feat(K-01): HealthKitService write (workout, energy, distance), CSV export"
  ```

---

## Task K-02: iCloud Sync

**Files:**
- Modify: `App/NikoNekoApp.swift`

- [ ] **Step 1: Add conditional CloudKit container in NikoNekoApp**

  Replace the `.modelContainer` modifier in `App/NikoNekoApp.swift`:
  ```swift
  import SwiftUI
  import SwiftData

  @main
  struct NikoNekoApp: App {
      @State private var themeManager = ThemeManager()
      @State private var languageManager = LanguageManager()

      var body: some Scene {
          WindowGroup {
              ContentView()
                  .environment(themeManager)
                  .environment(languageManager)
          }
          .modelContainer(makeContainer())
      }

      private func makeContainer() -> ModelContainer {
          let schema = Schema([RunSession.self, UserProfile.self, ThresholdConfig.self])
          // Read iCloud preference from UserDefaults (written by UserProfile on change)
          let iCloudEnabled = UserDefaults.standard.bool(forKey: "iCloudEnabled")
          let config: ModelConfiguration
          if iCloudEnabled {
              config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
          } else {
              config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
          }
          return try! ModelContainer(for: schema, configurations: [config])
      }
  }
  ```

- [ ] **Step 2: Mirror iCloudEnabled to UserDefaults when UserProfile changes**

  In `Features/Settings/DataSyncView.swift`, the existing toggle already writes to UserProfile via `ctx.save()`. Add a side-effect:
  ```swift
  set: { v in
      profile?.iCloudEnabled = v
      UserDefaults.standard.set(v, forKey: "iCloudEnabled")
      try? ctx.save()
  }
  ```

- [ ] **Step 3: Build check**

  ```bash
  make build 2>&1 | tail -5
  ```

- [ ] **Step 4: Commit**

  ```bash
  git add App/NikoNekoApp.swift Features/Settings/DataSyncView.swift
  git commit -m "feat(K-02): iCloud sync via CloudKit ModelConfiguration, toggled from Settings"
  ```

---

## Task N-01: NotificationService

**Files:**
- Create: `Services/NotificationService.swift`

- [ ] **Step 1: Implement NotificationService**

  `Services/NotificationService.swift`:
  ```swift
  import UserNotifications

  enum NotificationService {
      static func requestPermission() async -> Bool {
          let center = UNUserNotificationCenter.current()
          let granted = try? await center.requestAuthorization(options: [.alert, .sound])
          return granted ?? false
      }

      static func scheduleDaily(hour: Int, minute: Int) {
          let center = UNUserNotificationCenter.current()
          center.removePendingNotificationRequests(withIdentifiers: ["daily-reminder"])

          let content = UNMutableNotificationContent()
          content.title = NSLocalizedString("notif.title", comment: "")
          content.body  = NSLocalizedString("notif.body", comment: "")
          content.sound = .default

          var components = DateComponents()
          components.hour = hour
          components.minute = minute

          let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
          let request = UNNotificationRequest(
              identifier: "daily-reminder",
              content: content,
              trigger: trigger
          )
          center.add(request)
      }

      static func cancel() {
          UNUserNotificationCenter.current()
              .removePendingNotificationRequests(withIdentifiers: ["daily-reminder"])
      }
  }
  ```

- [ ] **Step 2: Wire into NotificationsView**

  In `Features/Settings/NotificationsView.swift`, add `.onChange` to the notifications toggle:
  ```swift
  .onChange(of: profile?.notificationsEnabled) { _, enabled in
      if enabled == true {
          Task {
              let granted = await NotificationService.requestPermission()
              if granted {
                  NotificationService.scheduleDaily(
                      hour: profile?.notificationHour ?? 7,
                      minute: profile?.notificationMinute ?? 0
                  )
              }
          }
      } else {
          NotificationService.cancel()
      }
  }
  ```

- [ ] **Step 3: Build check**

  ```bash
  make build 2>&1 | tail -5
  ```

- [ ] **Step 4: Commit**

  ```bash
  git add Services/NotificationService.swift Features/Settings/NotificationsView.swift
  git commit -m "feat(N-01): NotificationService (UNCalendarNotificationTrigger daily reminder, en+zh)"
  ```

---

## Task Q-01: Unit Tests

**Files:**
- Verify: `Tests/UnitTests/ThemeLibraryTests.swift` (already created in F-02)
- Verify: `Tests/UnitTests/AppGroupDefaultsTests.swift` (already created in F-03)
- Verify: `Tests/UnitTests/MetronomeServiceTests.swift` (already created in M-01)
- Verify: `Tests/UnitTests/HeartRateServiceTests.swift` (already created in H-01)
- Verify: `Tests/UnitTests/MotionServiceTests.swift` (already created in D-01)
- Verify: `Tests/UnitTests/TimerViewModelTests.swift` (already created in T-01)
- Verify: `Tests/UnitTests/DrumPickerTests.swift` (already created in T-02)
- Verify: `Tests/UnitTests/ReportViewModelTests.swift` (already created in R-01)
- Verify: `Tests/UnitTests/BarColorTests.swift` (already created in R-02)
- Verify: `Tests/UnitTests/SummaryViewModelTests.swift` (already created in U-01)

- [ ] **Step 1: Run full unit test suite**

  ```bash
  make test 2>&1 | grep -E "(Test Suite|PASS|FAIL|error)"
  ```
  Expected: All tests PASS. Zero failures.

- [ ] **Step 2: Check test count matches spec**

  The spec mandates these specific tests:
  - `ThemeLibraryTests`: 14 themes × 5 bar + 5 cal ✓
  - `barColor` boundary conditions ✓ (`BarColorTests`)
  - Calorie estimation ✓ (`MotionServiceTests`)
  - `ReportViewModel` duration aggregation ✓ (`ReportViewModelTests`)
  - `DaySessionSummary` encode/decode round-trip ✓ (`AppGroupDefaultsTests`)

  ```bash
  make test 2>&1 | grep "Test Case" | wc -l
  ```
  Expected: ≥ 40 test cases.

- [ ] **Step 3: Commit test results summary to PROGRESS.md**

  Update `PROGRESS.md` Q-01 entry with actual test count and any failures found.

---

## Task Q-02: Integration Tests

**Files:**
- Verify: `Tests/IntegrationTests/AppGroupBridgeTests.swift` (already created in S-02)
- Verify: `Tests/IntegrationTests/WidgetDataTests.swift` (already created in W-01)

- [ ] **Step 1: Run integration tests**

  ```bash
  make test 2>&1 | grep -E "(AppGroupBridge|WidgetData|PASS|FAIL)"
  ```
  Expected: All PASS.

- [ ] **Step 2: Add theme→widget reload integration test**

  Append to `Tests/IntegrationTests/WidgetDataTests.swift`:
  ```swift
  func test_themeWrittenToAppGroup() {
      AppGroupDefaults.shared.set("zinc", forKey: "activeThemeId")
      let theme = WidgetSharedData.loadTheme()
      XCTAssertEqual(theme.id, "zinc")
      // Reset
      AppGroupDefaults.shared.removeObject(forKey: "activeThemeId")
  }
  ```

- [ ] **Step 3: Run again**

  ```bash
  make test 2>&1 | grep -E "(WidgetData|PASS|FAIL)"
  ```
  Expected: 3 tests PASS.

- [ ] **Step 4: Commit**

  ```bash
  git add Tests/IntegrationTests/WidgetDataTests.swift
  git commit -m "test(Q-02): Integration test — theme written to App Group, widget reads it"
  ```

---

## Task Q-03: Manual QA Sweep

This task is human-executed on a physical device. Each item maps directly to the spec's testing checklist.

- [ ] **Long-press stop arc:** Hold stop button — arc fills in ~2 s. Release early — arc resets without stopping run.
- [ ] **BPM panel clamp:** Tap ±5 past limits → value clamps at 140 (min) and 220 (max).
- [ ] **Drum picker ghost numerals:** Drag picker — ghost values above/below update during drag, snap on release.
- [ ] **Dynamic Island compact:** Start run — compact shows character (left) + time (right).
- [ ] **Dynamic Island expanded:** Long-press DI — expanded shows app label + time (left), character + BPM (right).
- [ ] **Lock Screen Live Activity:** During run, lock device — card appears above notifications with time + character.
- [ ] **Live Activity dismissal:** Stop run — Live Activity card disappears immediately.
- [ ] **All 14 themes:** Switch each theme — verify no hardcoded colors visible in Report bars, Widget heatmap, Summary dots.
- [ ] **Language switch:** Settings → Appearance → Language → 繁體中文 — all UI strings update without restart.
- [ ] **Widget threshold slider:** Long-press Year Heatmap widget → Edit → drag T1 past T2 → T1 cannot exceed T2 (min gap enforced).
- [ ] **Heart rate hidden:** Run without Apple Watch and no BLE device — HR row not shown on Timer screen.
- [ ] **iCloud sync:** Enable iCloud in Settings on Device A → complete run → check data appears on Device B after sync.
- [ ] **Streak unlock:** Accumulate 7 consecutive days → Sit-Up character unlocked in Character Picker.

- [ ] **Step: Record QA results**

  Update `PROGRESS.md` Q-03 entry:
  ```markdown
  ### ✅ Q-03 Manual QA Sweep
  **Completed:** YYYY-MM-DD
  **Pass:** [list passing items]
  **Fail:** [list any failures with repro steps]
  **Known Issues:** [any open items]
  ```

---

## Wave 3 Complete ✓

Update `PROGRESS.md`:
- Move all Wave 3 tasks to ✅ Done
- Update header: **Done: 30 | In Progress: 0 | To Do: 0**
- Fill Asset Slots table with real asset status

**MVP is complete. Next steps:**
1. Drop real Lottie JSON files into `Characters/Lottie/` to replace placeholder
2. Drop `tap.wav`, `bell.wav`, `drum.wav`, `wood.wav` into `Resources/Sounds/` to replace synthesis
3. Run `fastlane beta` to upload to TestFlight

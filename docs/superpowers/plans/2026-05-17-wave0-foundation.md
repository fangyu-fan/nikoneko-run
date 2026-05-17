# Wave 0 — Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete foundation layer that all other waves depend on — Xcode project shell, 14-theme token system, and SwiftData models with App Group bridge.

**Architecture:** Three sequential tasks (F-01 → F-02 → F-03). Each task's output is an interface contract that Wave 1 sub-agents depend on. No task may be skipped or reordered. After F-03 completes, Wave 1 tasks may begin in parallel.

**Tech Stack:** Swift 5.9+, SwiftUI, SwiftData, Xcode 15+, SwiftLint, Fastlane

---

## File Map

```
nikoneko/
├── nikoneko.xcodeproj/
├── Makefile
├── Fastfile
├── .swiftlint.yml
├── App/
│   ├── NikoNekoApp.swift
│   └── ContentView.swift
├── Core/
│   ├── Theme/
│   │   ├── ThemeTokens.swift
│   │   ├── ThemeLibrary.swift
│   │   └── ThemeManager.swift
│   ├── Models/
│   │   ├── RunSession.swift
│   │   ├── UserProfile.swift
│   │   └── ThresholdConfig.swift
│   ├── AppGroupDefaults.swift
│   └── Extensions/
│       └── Color+Hex.swift
└── Tests/
    └── UnitTests/
        ├── ThemeLibraryTests.swift
        └── AppGroupDefaultsTests.swift
```

---

## Task 1 (F-01): Xcode Project Shell

**Files:**
- Create: `nikoneko.xcodeproj` (via Xcode)
- Create: `App/NikoNekoApp.swift`
- Create: `App/ContentView.swift`
- Create: `Makefile`
- Create: `.swiftlint.yml`
- Create: `Fastfile`

- [ ] **Step 1: Create Xcode project**

  In Xcode: File → New → Project → App
  - Product Name: `nikoneko`
  - Bundle ID: `com.fangyu.nikoneko`
  - Interface: SwiftUI
  - Language: Swift
  - Storage: SwiftData ✓
  - Include Tests ✓

  Add second target: File → New → Target → Widget Extension
  - Product Name: `NikoNekoWidgets`
  - Include Configuration Intent ✓

- [ ] **Step 2: Configure App Group capability**

  Select `nikoneko` target → Signing & Capabilities → + Capability → App Groups
  Add: `group.com.fangyu.nikoneko`

  Repeat for `NikoNekoWidgets` target — same App Group identifier.

- [ ] **Step 3: Add remaining Capabilities to main target**

  `nikoneko` target → Signing & Capabilities:
  - HealthKit ✓
  - Background Modes ✓ → check "Audio, AirPlay, and Picture in Picture" + "Location updates"
  - Push Notifications ✓

- [ ] **Step 4: Write App entry point**

  `App/NikoNekoApp.swift`:
  ```swift
  import SwiftUI
  import SwiftData

  @main
  struct NikoNekoApp: App {
      var body: some Scene {
          WindowGroup {
              ContentView()
          }
      }
  }
  ```

  `App/ContentView.swift`:
  ```swift
  import SwiftUI

  struct ContentView: View {
      var body: some View {
          TabView {
              Text("Timer")
                  .tabItem { Label("Timer", systemImage: "figure.run") }
              Text("Report")
                  .tabItem { Label("Report", systemImage: "chart.bar") }
              Text("Settings")
                  .tabItem { Label("Settings", systemImage: "gearshape") }
          }
      }
  }
  ```

- [ ] **Step 5: Create Makefile**

  `Makefile`:
  ```makefile
  SCHEME = nikoneko
  DESTINATION = platform=iOS Simulator,name=iPhone 15 Pro

  build:
  	xcodebuild build -scheme $(SCHEME) -destination "$(DESTINATION)" | xcpretty

  test:
  	xcodebuild test -scheme $(SCHEME) -destination "$(DESTINATION)" | xcpretty

  lint:
  	swiftlint lint --strict

  clean:
  	xcodebuild clean -scheme $(SCHEME)
  	rm -rf ~/Library/Developer/Xcode/DerivedData

  .PHONY: build test lint clean
  ```

- [ ] **Step 6: Create SwiftLint config**

  `.swiftlint.yml`:
  ```yaml
  disabled_rules:
    - trailing_whitespace
  opt_in_rules:
    - empty_count
    - missing_docs
  excluded:
    - Pods
    - Fastlane
  line_length: 120
  ```

- [ ] **Step 7: Create Fastfile**

  `Fastfile`:
  ```ruby
  default_platform(:ios)

  platform :ios do
    desc "Run tests"
    lane :test do
      run_tests(
        scheme: "nikoneko",
        device: "iPhone 15 Pro"
      )
    end

    desc "Build and upload to TestFlight"
    lane :beta do
      build_app(scheme: "nikoneko")
      upload_to_testflight(skip_waiting_for_build_processing: true)
    end

    desc "Submit to App Store"
    lane :release do
      build_app(scheme: "nikoneko")
      upload_to_app_store
    end
  end
  ```

- [ ] **Step 8: Verify build succeeds**

  ```bash
  make build
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 9: Commit**

  ```bash
  git init
  git add .
  git commit -m "feat(F-01): Xcode project shell, App Group, Capabilities, Makefile, Fastlane"
  ```

---

## Task 2 (F-02): Theme System

**Files:**
- Create: `Core/Extensions/Color+Hex.swift`
- Create: `Core/Theme/ThemeTokens.swift`
- Create: `Core/Theme/ThemeLibrary.swift`
- Create: `Core/Theme/ThemeManager.swift`
- Create: `Tests/UnitTests/ThemeLibraryTests.swift`

- [ ] **Step 1: Write failing tests first**

  `Tests/UnitTests/ThemeLibraryTests.swift`:
  ```swift
  import XCTest
  @testable import nikoneko

  final class ThemeLibraryTests: XCTestCase {

      func test_allThemesExist() {
          XCTAssertEqual(ThemeLibrary.all.count, 14)
      }

      func test_allThemesHaveFiveBarStops() {
          for theme in ThemeLibrary.all {
              XCTAssertEqual(theme.bar.count, 5,
                  "\(theme.id) has \(theme.bar.count) bar stops, expected 5")
          }
      }

      func test_allThemesHaveFiveCalStops() {
          for theme in ThemeLibrary.all {
              XCTAssertEqual(theme.cal.count, 5,
                  "\(theme.id) has \(theme.cal.count) cal stops, expected 5")
          }
      }

      func test_allThemeIdsAreUnique() {
          let ids = ThemeLibrary.all.map(\.id)
          XCTAssertEqual(ids.count, Set(ids).count)
      }

      func test_themeManagerDefaultIsObsidian() {
          let manager = ThemeManager()
          XCTAssertEqual(manager.current.id, "obsidian")
      }

      func test_themeManagerApplyChangesCurrentTheme() {
          let manager = ThemeManager()
          manager.apply("paper")
          XCTAssertEqual(manager.current.id, "paper")
      }

      func test_themeManagerIgnoresUnknownId() {
          let manager = ThemeManager()
          manager.apply("nonexistent")
          XCTAssertEqual(manager.current.id, "obsidian")
      }

      func test_colorHexInitializer() {
          let white = Color(hex: "ffffff")
          // Confirm it doesn't crash and produces a Color
          XCTAssertNotNil(white)
      }
  }
  ```

- [ ] **Step 2: Run tests to confirm they fail**

  ```bash
  make test
  ```
  Expected: FAIL — `ThemeLibrary`, `ThemeTokens`, `ThemeManager` not found.

- [ ] **Step 3: Implement Color+Hex extension**

  `Core/Extensions/Color+Hex.swift`:
  ```swift
  import SwiftUI

  extension Color {
      init(hex: String) {
          let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
          var int: UInt64 = 0
          Scanner(string: hex).scanHexInt64(&int)
          let r, g, b: UInt64
          switch hex.count {
          case 6:
              (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
          default:
              (r, g, b) = (0, 0, 0)
          }
          self.init(
              .sRGB,
              red: Double(r) / 255,
              green: Double(g) / 255,
              blue: Double(b) / 255,
              opacity: 1
          )
      }
  }
  ```

- [ ] **Step 4: Implement ThemeTokens**

  `Core/Theme/ThemeTokens.swift`:
  ```swift
  import SwiftUI

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
      let bar: [Color]   // exactly 5: [0]=empty [1]=low [2]=mid [3]=high [4]=peak
      let cal: [Color]   // exactly 5, same semantics
      let isDark: Bool
  }
  ```

- [ ] **Step 5: Implement ThemeLibrary with all 14 themes**

  `Core/Theme/ThemeLibrary.swift`:
  ```swift
  import SwiftUI

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

      static let paper = ThemeTokens(
          id: "paper",
          bg:         Color(hex: "ffffff"),
          surface:    Color(hex: "f5f5f5"),
          card:       Color(hex: "ebebeb"),
          text:       Color(hex: "111111"),
          textDim:    Color(hex: "aaaaaa"),
          textMid:    Color(hex: "555555"),
          accent:     Color(hex: "111111"),
          accentMid:  Color(hex: "555555"),
          accentDim:  Color(hex: "dddddd"),
          bar: [Color(hex:"e8e8e8"), Color(hex:"cccccc"), Color(hex:"aaaaaa"), Color(hex:"555555"), Color(hex:"111111")],
          cal: [Color(hex:"e8e8e8"), Color(hex:"cccccc"), Color(hex:"aaaaaa"), Color(hex:"555555"), Color(hex:"111111")],
          isDark: false
      )

      static let limestone = ThemeTokens(
          id: "limestone",
          bg:         Color(hex: "f4f0ea"),
          surface:    Color(hex: "ece8e0"),
          card:       Color(hex: "e4dfd6"),
          text:       Color(hex: "1c1a16"),
          textDim:    Color(hex: "b8b0a0"),
          textMid:    Color(hex: "888070"),
          accent:     Color(hex: "3c3830"),
          accentMid:  Color(hex: "908070"),
          accentDim:  Color(hex: "d0c8b8"),
          bar: [Color(hex:"e4dfd6"), Color(hex:"ccc4b4"), Color(hex:"a89880"), Color(hex:"806850"), Color(hex:"3c3830")],
          cal: [Color(hex:"e4dfd6"), Color(hex:"ccc4b4"), Color(hex:"a89880"), Color(hex:"806850"), Color(hex:"3c3830")],
          isDark: false
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

      static let grove = ThemeTokens(
          id: "grove",
          bg:         Color(hex: "F5ECD7"),
          surface:    Color(hex: "ebe2cd"),
          card:       Color(hex: "ddd4bc"),
          text:       Color(hex: "353535"),
          textDim:    Color(hex: "5f5f5f"),
          textMid:    Color(hex: "68a67d"),
          accent:     Color(hex: "8FBF9F"),
          accentMid:  Color(hex: "24613b"),
          accentDim:  Color(hex: "c8ddd0"),
          bar: [Color(hex:"c8ddd0"), Color(hex:"98c8a8"), Color(hex:"68a67d"), Color(hex:"24613b"), Color(hex:"F18F01")],
          cal: [Color(hex:"c8ddd0"), Color(hex:"98c8a8"), Color(hex:"68a67d"), Color(hex:"24613b"), Color(hex:"F18F01")],
          isDark: false
      )

      static let moss = ThemeTokens(
          id: "moss",
          bg:         Color(hex: "DDDDDD"),
          surface:    Color(hex: "EEEEEE"),
          card:       Color(hex: "e4e4e4"),
          text:       Color(hex: "292524"),
          textDim:    Color(hex: "78716c"),
          textMid:    Color(hex: "658864"),
          accent:     Color(hex: "658864"),
          accentMid:  Color(hex: "4a6848"),
          accentDim:  Color(hex: "B7B78A"),
          bar: [Color(hex:"B7B78A"), Color(hex:"9aaa70"), Color(hex:"658864"), Color(hex:"4a6848"), Color(hex:"bc6c25")],
          cal: [Color(hex:"B7B78A"), Color(hex:"9aaa70"), Color(hex:"658864"), Color(hex:"4a6848"), Color(hex:"bc6c25")],
          isDark: false
      )

      static let mocha = ThemeTokens(
          id: "mocha",
          bg:         Color(hex: "1a1210"),
          surface:    Color(hex: "241a14"),
          card:       Color(hex: "1e1510"),
          text:       Color(hex: "e8d5c0"),
          textDim:    Color(hex: "4a3020"),
          textMid:    Color(hex: "b08060"),
          accent:     Color(hex: "c8956a"),
          accentMid:  Color(hex: "a07048"),
          accentDim:  Color(hex: "301e10"),
          bar: [Color(hex:"241a14"), Color(hex:"4a2c18"), Color(hex:"7a4828"), Color(hex:"b07040"), Color(hex:"c8956a")],
          cal: [Color(hex:"241a14"), Color(hex:"4a2c18"), Color(hex:"7a4828"), Color(hex:"b07040"), Color(hex:"c8956a")],
          isDark: true
      )

      static let seafloor = ThemeTokens(
          id: "seafloor",
          bg:         Color(hex: "567189"),
          surface:    Color(hex: "7B8FA1"),
          card:       Color(hex: "6a8098"),
          text:       Color(hex: "F9F9F9"),
          textDim:    Color(hex: "DCDCDC"),
          textMid:    Color(hex: "CFB997"),
          accent:     Color(hex: "f7bf7a"),
          accentMid:  Color(hex: "e8a050"),
          accentDim:  Color(hex: "3E5975"),
          bar: [Color(hex:"3E5975"), Color(hex:"5a7898"), Color(hex:"7B8FA1"), Color(hex:"f7bf7a"), Color(hex:"CFB997")],
          cal: [Color(hex:"3E5975"), Color(hex:"5a7898"), Color(hex:"7B8FA1"), Color(hex:"f7bf7a"), Color(hex:"CFB997")],
          isDark: true
      )

      static let skyline = ThemeTokens(
          id: "skyline",
          bg:         Color(hex: "fffefb"),
          surface:    Color(hex: "f5f4f1"),
          card:       Color(hex: "e8e6e2"),
          text:       Color(hex: "1d1c1c"),
          textDim:    Color(hex: "313d44"),
          textMid:    Color(hex: "3b3c3d"),
          accent:     Color(hex: "71c4ef"),
          accentMid:  Color(hex: "00668c"),
          accentDim:  Color(hex: "d4eaf7"),
          bar: [Color(hex:"d4eaf7"), Color(hex:"b6ccd8"), Color(hex:"71c4ef"), Color(hex:"00668c"), Color(hex:"1d1c1c")],
          cal: [Color(hex:"d4eaf7"), Color(hex:"b6ccd8"), Color(hex:"71c4ef"), Color(hex:"00668c"), Color(hex:"1d1c1c")],
          isDark: false
      )

      static let navy = ThemeTokens(
          id: "navy",
          bg:         Color(hex: "0F1C2E"),
          surface:    Color(hex: "1f2b3e"),
          card:       Color(hex: "2a3650"),
          text:       Color(hex: "FFFFFF"),
          textDim:    Color(hex: "e0e0e0"),
          textMid:    Color(hex: "4d648d"),
          accent:     Color(hex: "acc2ef"),
          accentMid:  Color(hex: "3D5A80"),
          accentDim:  Color(hex: "1F3A5F"),
          bar: [Color(hex:"1F3A5F"), Color(hex:"2e5080"), Color(hex:"4d648d"), Color(hex:"acc2ef"), Color(hex:"cee8ff")],
          cal: [Color(hex:"1F3A5F"), Color(hex:"2e5080"), Color(hex:"4d648d"), Color(hex:"acc2ef"), Color(hex:"cee8ff")],
          isDark: true
      )

      static let lavender = ThemeTokens(
          id: "lavender",
          bg:         Color(hex: "F5F3F7"),
          surface:    Color(hex: "E9E4ED"),
          card:       Color(hex: "ddd6e4"),
          text:       Color(hex: "4A4A4A"),
          textDim:    Color(hex: "878787"),
          textMid:    Color(hex: "9A73B5"),
          accent:     Color(hex: "8B5FBF"),
          accentMid:  Color(hex: "61398F"),
          accentDim:  Color(hex: "D6C6E1"),
          bar: [Color(hex:"D6C6E1"), Color(hex:"c4a8d8"), Color(hex:"9A73B5"), Color(hex:"8B5FBF"), Color(hex:"61398F")],
          cal: [Color(hex:"D6C6E1"), Color(hex:"c4a8d8"), Color(hex:"9A73B5"), Color(hex:"8B5FBF"), Color(hex:"61398F")],
          isDark: false
      )

      static let midnight = ThemeTokens(
          id: "midnight",
          bg:         Color(hex: "151931"),
          surface:    Color(hex: "252841"),
          card:       Color(hex: "2e3150"),
          text:       Color(hex: "E7D1BB"),
          textDim:    Color(hex: "847a86"),
          textMid:    Color(hex: "A096A5"),
          accent:     Color(hex: "A096A5"),
          accentMid:  Color(hex: "c8b4c0"),
          accentDim:  Color(hex: "463e4b"),
          bar: [Color(hex:"2e3150"), Color(hex:"463e4b"), Color(hex:"706070"), Color(hex:"A096A2"), Color(hex:"E7D1BB")],
          cal: [Color(hex:"2e3150"), Color(hex:"463e4b"), Color(hex:"706070"), Color(hex:"A096A2"), Color(hex:"E7D1BB")],
          isDark: true
      )

      static let teal = ThemeTokens(
          id: "teal",
          bg:         Color(hex: "F2EFE9"),
          surface:    Color(hex: "e8e5df"),
          card:       Color(hex: "dddad4"),
          text:       Color(hex: "333333"),
          textDim:    Color(hex: "5c5c5c"),
          textMid:    Color(hex: "008b7a"),
          accent:     Color(hex: "00A896"),
          accentMid:  Color(hex: "006b60"),
          accentDim:  Color(hex: "a0d8d0"),
          bar: [Color(hex:"a0d8d0"), Color(hex:"50c0b0"), Color(hex:"00A896"), Color(hex:"006b60"), Color(hex:"FF6B6B")],
          cal: [Color(hex:"a0d8d0"), Color(hex:"50c0b0"), Color(hex:"00A896"), Color(hex:"006b60"), Color(hex:"FF6B6B")],
          isDark: false
      )

      static let blush = ThemeTokens(
          id: "blush",
          bg:         Color(hex: "FCEEF5"),
          surface:    Color(hex: "ffffff"),
          card:       Color(hex: "FAD9E6"),
          text:       Color(hex: "292524"),
          textDim:    Color(hex: "78716c"),
          textMid:    Color(hex: "61C0BF"),
          accent:     Color(hex: "61C0BF"),
          accentMid:  Color(hex: "3a9898"),
          accentDim:  Color(hex: "BBDED6"),
          bar: [Color(hex:"FAD9E6"), Color(hex:"FFB6B9"), Color(hex:"e89090"), Color(hex:"61C0BF"), Color(hex:"3a9898")],
          cal: [Color(hex:"FAD9E6"), Color(hex:"FFB6B9"), Color(hex:"e89090"), Color(hex:"61C0BF"), Color(hex:"3a9898")],
          isDark: false
      )
  }
  ```

- [ ] **Step 6: Implement ThemeManager**

  `Core/Theme/ThemeManager.swift`:
  ```swift
  import SwiftUI
  import WidgetKit

  @Observable
  final class ThemeManager {
      private(set) var current: ThemeTokens = ThemeLibrary.obsidian

      init() {
          let savedId = UserDefaults.standard.string(forKey: "activeThemeId") ?? "obsidian"
          if let saved = ThemeLibrary.all.first(where: { $0.id == savedId }) {
              current = saved
          }
      }

      func apply(_ id: String) {
          guard let theme = ThemeLibrary.all.first(where: { $0.id == id }) else { return }
          current = theme
          UserDefaults.standard.set(id, forKey: "activeThemeId")
          if let appGroup = UserDefaults(suiteName: AppGroupDefaults.suiteName) {
              appGroup.set(id, forKey: "activeThemeId")
          }
          WidgetCenter.shared.reloadAllTimelines()
      }
  }
  ```

- [ ] **Step 7: Run tests to confirm they pass**

  ```bash
  make test
  ```
  Expected: All 8 tests in `ThemeLibraryTests` PASS.

- [ ] **Step 8: Commit**

  ```bash
  git add Core/Extensions/Color+Hex.swift Core/Theme/ Tests/UnitTests/ThemeLibraryTests.swift
  git commit -m "feat(F-02): ThemeTokens, ThemeLibrary (14 themes), ThemeManager"
  ```

---

## Task 3 (F-03): SwiftData Models + AppGroupDefaults

**Files:**
- Create: `Core/Models/RunSession.swift`
- Create: `Core/Models/UserProfile.swift`
- Create: `Core/Models/ThresholdConfig.swift`
- Create: `Core/AppGroupDefaults.swift`
- Modify: `App/NikoNekoApp.swift`
- Create: `Tests/UnitTests/AppGroupDefaultsTests.swift`

- [ ] **Step 1: Write failing tests**

  `Tests/UnitTests/AppGroupDefaultsTests.swift`:
  ```swift
  import XCTest
  @testable import nikoneko

  final class AppGroupDefaultsTests: XCTestCase {

      func test_daySessionSummaryEncodesAndDecodes() throws {
          let original = DaySessionSummary(
              date: Date(timeIntervalSince1970: 1_000_000),
              duration: 1260,
              completionRatio: 0.75,
              hrAvg: 118,
              steps: 2400
          )
          let data = try JSONEncoder().encode(original)
          let decoded = try JSONDecoder().decode(DaySessionSummary.self, from: data)

          XCTAssertEqual(decoded.duration, original.duration)
          XCTAssertEqual(decoded.completionRatio, original.completionRatio, accuracy: 0.001)
          XCTAssertEqual(decoded.hrAvg, original.hrAvg)
          XCTAssertEqual(decoded.steps, original.steps)
      }

      func test_daySessionSummaryArrayEncodesAndDecodes() throws {
          let summaries = (0..<5).map { i in
              DaySessionSummary(
                  date: Date(timeIntervalSince1970: Double(i) * 86400),
                  duration: Double(i) * 600,
                  completionRatio: Double(i) / 4.0,
                  hrAvg: 110 + i,
                  steps: 1000 * i
              )
          }
          let data = try JSONEncoder().encode(summaries)
          let decoded = try JSONDecoder().decode([DaySessionSummary].self, from: data)
          XCTAssertEqual(decoded.count, 5)
          XCTAssertEqual(decoded[2].hrAvg, 112)
      }

      func test_timerModeRawValues() {
          XCTAssertEqual(TimerMode.countdown.rawValue, "countdown")
          XCTAssertEqual(TimerMode.stopwatch.rawValue, "stopwatch")
      }

      func test_soundTypeRawValues() {
          XCTAssertEqual(SoundType.tap.rawValue, "tap")
          XCTAssertEqual(SoundType.bell.rawValue, "bell")
          XCTAssertEqual(SoundType.drum.rawValue, "drum")
          XCTAssertEqual(SoundType.wood.rawValue, "wood")
      }

      func test_widgetCellInfoRawValues() {
          XCTAssertEqual(WidgetCellInfo.duration.rawValue, "duration")
          XCTAssertEqual(WidgetCellInfo.heartRate.rawValue, "heartRate")
          XCTAssertEqual(WidgetCellInfo.completion.rawValue, "completion")
      }
  }
  ```

- [ ] **Step 2: Run tests to confirm they fail**

  ```bash
  make test
  ```
  Expected: FAIL — `DaySessionSummary`, `TimerMode`, `SoundType`, `WidgetCellInfo` not found.

- [ ] **Step 3: Implement shared enums**

  Add to `Core/Models/RunSession.swift` top (these are used across models):
  ```swift
  import Foundation

  enum TimerMode: String, Codable {
      case countdown, stopwatch
  }

  enum SoundType: String, Codable {
      case tap, bell, drum, wood
  }

  enum TimeFormat: String, Codable {
      case plainMinutes, hhMM
  }

  enum AppLanguage: String, Codable {
      case english, traditionalChinese

      var code: String {
          switch self {
          case .english: return "en"
          case .traditionalChinese: return "zh-Hant"
          }
      }
  }

  enum WidgetCellInfo: String, Codable {
      case duration, heartRate, completion
  }
  ```

- [ ] **Step 4: Implement RunSession model**

  Continue in `Core/Models/RunSession.swift`:
  ```swift
  import SwiftData

  @Model
  final class RunSession {
      var id: UUID
      var startDate: Date
      var duration: TimeInterval
      var distance: Double
      var calories: Double
      var steps: Int
      var avgHR: Int
      var maxHR: Int
      var avgCadence: Int
      var bpm: Int
      var characterId: String
      var themeId: String
      var mode: TimerMode

      init(
          id: UUID = UUID(),
          startDate: Date,
          duration: TimeInterval,
          distance: Double = 0,
          calories: Double = 0,
          steps: Int = 0,
          avgHR: Int = 0,
          maxHR: Int = 0,
          avgCadence: Int = 0,
          bpm: Int = 180,
          characterId: String = "cat_a",
          themeId: String = "obsidian",
          mode: TimerMode = .countdown
      ) {
          self.id = id
          self.startDate = startDate
          self.duration = duration
          self.distance = distance
          self.calories = calories
          self.steps = steps
          self.avgHR = avgHR
          self.maxHR = maxHR
          self.avgCadence = avgCadence
          self.bpm = bpm
          self.characterId = characterId
          self.themeId = themeId
          self.mode = mode
      }
  }
  ```

- [ ] **Step 5: Implement UserProfile model**

  `Core/Models/UserProfile.swift`:
  ```swift
  import SwiftData

  @Model
  final class UserProfile {
      var id: UUID
      var defaultDuration: Int        // minutes
      var dailyGoalMinutes: Int
      var defaultBPM: Int
      var soundType: SoundType
      var volumeLockEnabled: Bool
      var timerMode: TimerMode
      var timeDisplayFormat: TimeFormat
      var showHR: Bool
      var showProgressRing: Bool
      var hapticEnabled: Bool
      var showDistance: Bool
      var showCalories: Bool
      var showSteps: Bool
      var activeThemeId: String
      var activeCharacterId: String
      var language: AppLanguage
      var heightCm: Double
      var weightKg: Double
      var useHealthForBody: Bool
      var notificationsEnabled: Bool
      var notificationHour: Int
      var notificationMinute: Int
      var healthKitEnabled: Bool
      var iCloudEnabled: Bool

      init() {
          self.id = UUID()
          self.defaultDuration = 20
          self.dailyGoalMinutes = 20
          self.defaultBPM = 180
          self.soundType = .tap
          self.volumeLockEnabled = false
          self.timerMode = .countdown
          self.timeDisplayFormat = .plainMinutes
          self.showHR = true
          self.showProgressRing = true
          self.hapticEnabled = true
          self.showDistance = true
          self.showCalories = true
          self.showSteps = true
          self.activeThemeId = "obsidian"
          self.activeCharacterId = "cat_a"
          self.language = .english
          self.heightCm = 170
          self.weightKg = 65
          self.useHealthForBody = false
          self.notificationsEnabled = false
          self.notificationHour = 7
          self.notificationMinute = 0
          self.healthKitEnabled = false
          self.iCloudEnabled = false
      }
  }
  ```

- [ ] **Step 6: Implement ThresholdConfig model**

  `Core/Models/ThresholdConfig.swift`:
  ```swift
  import SwiftData

  @Model
  final class ThresholdConfig {
      var widgetKind: String
      var threshold1: Int
      var threshold2: Int
      var threshold3: Int
      var cellInfo: WidgetCellInfo
      var showDayNumbers: Bool
      var showStreak: Bool
      var showTotalTime: Bool

      init(widgetKind: String) {
          self.widgetKind = widgetKind
          self.threshold1 = 10
          self.threshold2 = 50
          self.threshold3 = 90
          self.cellInfo = .duration
          self.showDayNumbers = true
          self.showStreak = true
          self.showTotalTime = true
      }
  }
  ```

- [ ] **Step 7: Implement DaySessionSummary and AppGroupDefaults**

  `Core/AppGroupDefaults.swift`:
  ```swift
  import Foundation
  import SwiftData

  struct DaySessionSummary: Codable {
      let date: Date
      let duration: TimeInterval
      let completionRatio: Double
      let hrAvg: Int
      let steps: Int
  }

  enum AppGroupDefaults {
      static let suiteName = "group.com.fangyu.nikoneko"

      static var shared: UserDefaults {
          UserDefaults(suiteName: suiteName) ?? .standard
      }

      static func writeSummaries(_ summaries: [DaySessionSummary]) {
          guard let data = try? JSONEncoder().encode(summaries) else { return }
          shared.set(data, forKey: "sessionSummaries")
          shared.set(Date(), forKey: "lastUpdated")
      }

      static func loadSummaries() -> [DaySessionSummary] {
          guard let data = shared.data(forKey: "sessionSummaries"),
                let summaries = try? JSONDecoder().decode([DaySessionSummary].self, from: data)
          else { return [] }
          return summaries
      }

      static func writeSessionSummaries(from sessions: [RunSession], dailyGoalMinutes: Int) {
          let summaries = sessions.prefix(400).map { session in
              DaySessionSummary(
                  date: session.startDate,
                  duration: session.duration,
                  completionRatio: min(1.0, session.duration / (Double(dailyGoalMinutes) * 60)),
                  hrAvg: session.avgHR,
                  steps: session.steps
              )
          }
          writeSummaries(Array(summaries))
      }
  }
  ```

- [ ] **Step 8: Wire ModelContainer into NikoNekoApp**

  `App/NikoNekoApp.swift`:
  ```swift
  import SwiftUI
  import SwiftData

  @main
  struct NikoNekoApp: App {
      @State private var themeManager = ThemeManager()

      var body: some Scene {
          WindowGroup {
              ContentView()
                  .environment(themeManager)
          }
          .modelContainer(for: [RunSession.self, UserProfile.self, ThresholdConfig.self])
      }
  }
  ```

- [ ] **Step 9: Run tests to confirm they pass**

  ```bash
  make test
  ```
  Expected: All 5 tests in `AppGroupDefaultsTests` PASS, all 8 in `ThemeLibraryTests` still PASS.

- [ ] **Step 10: Final build check**

  ```bash
  make build
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 11: Commit**

  ```bash
  git add Core/Models/ Core/AppGroupDefaults.swift App/NikoNekoApp.swift Tests/UnitTests/AppGroupDefaultsTests.swift
  git commit -m "feat(F-03): SwiftData models (RunSession, UserProfile, ThresholdConfig), AppGroupDefaults, DaySessionSummary"
  ```

---

## Wave 0 Complete ✓

After F-03 merges, update `PROGRESS.md`:
- Move F-01, F-02, F-03 to ✅ Done
- Move all Wave 1 tasks to 🟡 In Progress
- All Wave 1 sub-agents may begin simultaneously

**Interface contracts now locked:**
- `ThemeTokens` — shape must not change
- `DaySessionSummary` — Codable shape must not change
- `AppGroupDefaults.suiteName` — must not change
- `RunSession`, `UserProfile`, `ThresholdConfig` — `@Model` properties must not be renamed without migration

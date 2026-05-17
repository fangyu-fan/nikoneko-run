# Wave 2 — Secondary Screens & Extensions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Report screen, Summary screen, all 4 widgets, and Dynamic Island / Live Activity — unlocked as Wave 1 dependencies complete.

**Architecture:** Each task is dep-gated. R-01 needs S-02. U-01 needs T-01+M-01+H-01+D-01. L-01 needs T-01. W-01/W-02/W-03 need S-02. Start each task only once its listed dependencies are merged.

**Tech Stack:** SwiftUI, WidgetKit, ActivityKit, SwiftData, ImageRenderer

**Prerequisites:** See per-task dependency list.

---

## Task R-01: ReportView + ReportViewModel

**Dependencies:** S-02 ✓  
**Files:**
- Create: `Features/Report/ReportViewModel.swift`
- Create: `Features/Report/ReportView.swift`
- Test: `Tests/UnitTests/ReportViewModelTests.swift`

- [ ] **Step 1: Write failing tests**

  `Tests/UnitTests/ReportViewModelTests.swift`:
  ```swift
  import XCTest
  @testable import nikoneko

  final class ReportViewModelTests: XCTestCase {

      private func makeSession(daysAgo: Int, duration: TimeInterval) -> RunSession {
          RunSession(
              startDate: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
              duration: duration
          )
      }

      func test_heroDuration_sumForWeek() {
          let vm = ReportViewModel()
          let sessions = [
              makeSession(daysAgo: 0, duration: 1200),
              makeSession(daysAgo: 1, duration: 900),
              makeSession(daysAgo: 8, duration: 600),  // outside current week
          ]
          vm.loadSessions(sessions)
          vm.period = .week
          vm.currentOffset = 0
          XCTAssertEqual(vm.heroDuration, 2100, accuracy: 1)
      }

      func test_heroDuration_onlyTodayForDay() {
          let vm = ReportViewModel()
          let sessions = [
              makeSession(daysAgo: 0, duration: 1200),
              makeSession(daysAgo: 1, duration: 900),
          ]
          vm.loadSessions(sessions)
          vm.period = .day
          vm.currentOffset = 0
          XCTAssertEqual(vm.heroDuration, 1200, accuracy: 1)
      }

      func test_offsetNavigationMovesBackOneWeek() {
          let vm = ReportViewModel()
          vm.period = .week
          vm.currentOffset = 0
          let range0 = vm.dateRange
          vm.currentOffset = -1
          let range1 = vm.dateRange
          XCTAssertLessThan(range1.start, range0.start)
      }
  }
  ```

- [ ] **Step 2: Implement ReportViewModel**

  `Features/Report/ReportViewModel.swift`:
  ```swift
  import Foundation
  import SwiftData

  @Observable
  final class ReportViewModel {
      enum Period: String, CaseIterable { case day, week, month, year }
      enum Metric: String, CaseIterable { case distance, calories, steps, hrAvg, hrMax, cadence }

      var period: Period = .week
      var selectedMetric: Metric = .distance
      var currentOffset: Int = 0

      private var sessions: [RunSession] = []

      func loadSessions(_ sessions: [RunSession]) {
          self.sessions = sessions
      }

      var dateRange: (start: Date, end: Date) {
          let cal = Calendar.current
          let now = Date()
          switch period {
          case .day:
              let start = cal.startOfDay(for: cal.date(byAdding: .day, value: currentOffset, to: now)!)
              return (start, cal.date(byAdding: .day, value: 1, to: start)!)
          case .week:
              let weekStart = cal.dateInterval(of: .weekOfYear, for: now)!.start
              let start = cal.date(byAdding: .weekOfYear, value: currentOffset, to: weekStart)!
              return (start, cal.date(byAdding: .weekOfYear, value: 1, to: start)!)
          case .month:
              let monthStart = cal.dateInterval(of: .month, for: now)!.start
              let start = cal.date(byAdding: .month, value: currentOffset, to: monthStart)!
              return (start, cal.date(byAdding: .month, value: 1, to: start)!)
          case .year:
              let yearStart = cal.dateInterval(of: .year, for: now)!.start
              let start = cal.date(byAdding: .year, value: currentOffset, to: yearStart)!
              return (start, cal.date(byAdding: .year, value: 1, to: start)!)
          }
      }

      var heroDuration: TimeInterval {
          let range = dateRange
          return sessions
              .filter { $0.startDate >= range.start && $0.startDate < range.end }
              .reduce(0) { $0 + $1.duration }
      }

      var logItems: [RunSession] {
          let range = dateRange
          return sessions
              .filter { $0.startDate >= range.start && $0.startDate < range.end }
              .sorted { $0.startDate > $1.startDate }
      }

      var chartBars: [ChartBar] {
          let range = dateRange
          let cal = Calendar.current
          switch period {
          case .day:
              return (0..<24).map { hour in
                  let hourSessions = sessions.filter {
                      cal.component(.hour, from: $0.startDate) == hour &&
                      cal.isDate($0.startDate, inSameDayAs: range.start)
                  }
                  return ChartBar(
                      label: "\(hour)",
                      value: metricValue(for: hourSessions),
                      isToday: hour == cal.component(.hour, from: Date())
                  )
              }
          case .week:
              return (0..<7).map { dayOffset in
                  let day = cal.date(byAdding: .day, value: dayOffset, to: range.start)!
                  let daySessions = sessions.filter { cal.isDate($0.startDate, inSameDayAs: day) }
                  let labels = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
                  return ChartBar(
                      label: labels[dayOffset % 7],
                      value: metricValue(for: daySessions),
                      isToday: cal.isDateInToday(day)
                  )
              }
          case .month:
              let daysInMonth = cal.range(of: .day, in: .month, for: range.start)!.count
              return (0..<daysInMonth).map { dayOffset in
                  let day = cal.date(byAdding: .day, value: dayOffset, to: range.start)!
                  let daySessions = sessions.filter { cal.isDate($0.startDate, inSameDayAs: day) }
                  return ChartBar(
                      label: "\(dayOffset + 1)",
                      value: metricValue(for: daySessions),
                      isToday: cal.isDateInToday(day)
                  )
              }
          case .year:
              return (0..<12).map { monthOffset in
                  let month = cal.date(byAdding: .month, value: monthOffset, to: range.start)!
                  let monthInterval = cal.dateInterval(of: .month, for: month)!
                  let monthSessions = sessions.filter {
                      $0.startDate >= monthInterval.start && $0.startDate < monthInterval.end
                  }
                  let labels = ["J","F","M","A","M","J","J","A","S","O","N","D"]
                  return ChartBar(
                      label: labels[monthOffset],
                      value: metricValue(for: monthSessions),
                      isToday: cal.isDate(month, equalTo: Date(), toGranularity: .month)
                  )
              }
          }
      }

      private func metricValue(for sessions: [RunSession]) -> Double {
          switch selectedMetric {
          case .distance: return sessions.reduce(0) { $0 + $1.distance }
          case .calories:  return sessions.reduce(0) { $0 + $1.calories }
          case .steps:     return Double(sessions.reduce(0) { $0 + $1.steps })
          case .hrAvg:     return sessions.isEmpty ? 0 : Double(sessions.reduce(0) { $0 + $1.avgHR }) / Double(sessions.count)
          case .hrMax:     return Double(sessions.map(\.maxHR).max() ?? 0)
          case .cadence:   return sessions.isEmpty ? 0 : Double(sessions.reduce(0) { $0 + $1.avgCadence }) / Double(sessions.count)
          }
      }
  }

  struct ChartBar {
      let label: String
      let value: Double
      let isToday: Bool
  }
  ```

- [ ] **Step 3: Implement ReportView**

  `Features/Report/ReportView.swift`:
  ```swift
  import SwiftUI
  import SwiftData

  struct ReportView: View {
      @Environment(ThemeManager.self) private var themeManager
      @Query(sort: \RunSession.startDate, order: .reverse) private var sessions: [RunSession]
      @State private var vm = ReportViewModel()

      private var theme: ThemeTokens { themeManager.current }

      var body: some View {
          NavigationStack {
              ScrollView {
                  VStack(spacing: 0) {
                      periodTabs
                      dateNavRow
                      heroBlock
                      metricCards
                      BarChartView(bars: vm.chartBars)
                          .frame(height: 68)
                          .padding(.horizontal, 12)
                          .padding(.vertical, 8)
                      logList
                  }
              }
              .background(theme.bg)
              .navigationTitle("Report")
              .navigationBarTitleDisplayMode(.inline)
          }
          .onAppear { vm.loadSessions(sessions) }
          .onChange(of: sessions.count) { _, _ in vm.loadSessions(sessions) }
      }

      private var periodTabs: some View {
          HStack(spacing: 0) {
              ForEach(ReportViewModel.Period.allCases, id: \.self) { p in
                  Button(p.rawValue.capitalized) { vm.period = p; vm.currentOffset = 0 }
                      .font(.system(size: 9, weight: .medium))
                      .foregroundColor(vm.period == p ? theme.accent : theme.textDim)
                      .frame(maxWidth: .infinity)
                      .padding(.vertical, 9)
              }
          }
          .background(theme.surface)
      }

      private var dateNavRow: some View {
          HStack {
              Button("‹") { vm.currentOffset -= 1 }.foregroundColor(theme.textDim)
              Spacer()
              Text(vm.period.rawValue).font(.system(size: 9)).foregroundColor(theme.textDim)
              Spacer()
              Button("›") {
                  if vm.currentOffset < 0 { vm.currentOffset += 1 }
              }.foregroundColor(vm.currentOffset < 0 ? theme.textDim : theme.textDim.opacity(0.3))
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 9)
      }

      private var heroBlock: some View {
          VStack(alignment: .leading, spacing: 2) {
              Text("\(Int(vm.heroDuration / 60))")
                  .font(.system(size: 46, weight: .ultraLight)).foregroundColor(theme.text)
              Text("min").font(.system(size: 9)).foregroundColor(theme.textDim)
              Text("DURATION").font(.system(size: 7)).tracking(1).foregroundColor(theme.textDim)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 14)
          .padding(.top, 2)
          .padding(.bottom, 8)
      }

      private var metricCards: some View {
          let metrics: [ReportViewModel.Metric] = vm.period == .day
              ? [.distance, .calories, .steps, .hrAvg, .hrMax, .cadence]
              : [.distance, .calories, .steps]
          return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                          spacing: 4) {
              ForEach(metrics, id: \.self) { metric in
                  MetricCard(metric: metric, vm: vm)
              }
          }
          .padding(.horizontal, 12)
          .padding(.bottom, 6)
      }

      private var logList: some View {
          LazyVStack(spacing: 0) {
              ForEach(vm.logItems) { session in
                  NavigationLink(destination: SessionDetailView(session: session)) {
                      LogRow(session: session, vm: vm)
                  }
              }
          }
          .padding(.horizontal, 12)
      }
  }

  struct MetricCard: View {
      let metric: ReportViewModel.Metric
      @Bindable var vm: ReportViewModel
      @Environment(ThemeManager.self) private var themeManager
      private var theme: ThemeTokens { themeManager.current }
      private var isActive: Bool { vm.selectedMetric == metric }

      var body: some View {
          Button { vm.selectedMetric = metric } label: {
              VStack(alignment: .leading, spacing: 2) {
                  Text(metric.rawValue)
                      .font(.system(size: 6.5)).foregroundColor(theme.textDim)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(9)
              .background(theme.card)
              .overlay(RoundedRectangle(cornerRadius: 9)
                  .stroke(isActive ? theme.accentMid : theme.accentDim, lineWidth: isActive ? 1 : 0.5))
              .cornerRadius(9)
          }
      }
  }

  struct LogRow: View {
      let session: RunSession
      let vm: ReportViewModel
      @Environment(ThemeManager.self) private var themeManager
      private var theme: ThemeTokens { themeManager.current }

      var body: some View {
          HStack(spacing: 8) {
              RoundedRectangle(cornerRadius: 1.5).fill(theme.bar[3])
                  .frame(width: 5, height: 5)
              Text(session.startDate, format: .dateTime.month(.abbreviated).day())
                  .font(.system(size: 10)).foregroundColor(theme.textMid).frame(minWidth: 32)
              Text("\(Int(session.duration / 60)) min")
                  .font(.system(size: 11)).foregroundColor(theme.text)
              Spacer()
              Image(systemName: "chevron.right").font(.system(size: 10)).foregroundColor(theme.textDim)
          }
          .padding(.vertical, 7)
          Divider().background(theme.accentDim)
      }
  }
  ```

- [ ] **Step 4: Run tests**

  ```bash
  make test 2>&1 | grep -E "(PASS|FAIL|ReportViewModel)"
  ```
  Expected: All 3 PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add Features/Report/ReportViewModel.swift Features/Report/ReportView.swift Tests/UnitTests/ReportViewModelTests.swift
  git commit -m "feat(R-01): ReportView + ReportViewModel (Day/Week/Month/Year, metric cards, log list)"
  ```

---

## Task R-02: BarChartView

**Dependencies:** F-02 ✓, R-01 ✓  
**Files:**
- Create: `Features/Report/BarChartView.swift`
- Test: `Tests/UnitTests/BarColorTests.swift`

- [ ] **Step 1: Write failing tests**

  `Tests/UnitTests/BarColorTests.swift`:
  ```swift
  import XCTest
  @testable import nikoneko

  final class BarColorTests: XCTestCase {

      private let theme = ThemeLibrary.obsidian

      func test_zeroRatioReturnsBar0() {
          let color = BarChartView.barColor(ratio: 0.0, theme: theme, t1: 10, t2: 50, t3: 90)
          XCTAssertEqual(color, theme.bar[0])
      }

      func test_atT1ThresholdReturnsBar1() {
          let color = BarChartView.barColor(ratio: 0.10, theme: theme, t1: 10, t2: 50, t3: 90)
          XCTAssertEqual(color, theme.bar[1])
      }

      func test_betweenT1andT2ReturnsBar2() {
          let color = BarChartView.barColor(ratio: 0.30, theme: theme, t1: 10, t2: 50, t3: 90)
          XCTAssertEqual(color, theme.bar[2])
      }

      func test_atT3ThresholdReturnsBar3() {
          let color = BarChartView.barColor(ratio: 0.90, theme: theme, t1: 10, t2: 50, t3: 90)
          XCTAssertEqual(color, theme.bar[3])
      }

      func test_fullCompletionReturnsBar4() {
          let color = BarChartView.barColor(ratio: 1.0, theme: theme, t1: 10, t2: 50, t3: 90)
          XCTAssertEqual(color, theme.bar[4])
      }
  }
  ```

- [ ] **Step 2: Implement BarChartView**

  `Features/Report/BarChartView.swift`:
  ```swift
  import SwiftUI

  struct BarChartView: View {
      let bars: [ChartBar]
      @Environment(ThemeManager.self) private var themeManager
      private var theme: ThemeTokens { themeManager.current }

      private var maxValue: Double { bars.map(\.value).max() ?? 1 }

      var body: some View {
          HStack(alignment: .bottom, spacing: 2) {
              ForEach(bars.indices, id: \.self) { i in
                  let bar = bars[i]
                  let ratio = maxValue > 0 ? bar.value / maxValue : 0
                  VStack(spacing: 2) {
                      RoundedRectangle(cornerRadius: 2)
                          .fill(Self.barColor(ratio: ratio, theme: theme, t1: 10, t2: 50, t3: 90))
                          .frame(height: max(2, ratio * 52))
                          .animation(.easeInOut(duration: 0.25), value: ratio)
                      Text(bar.label)
                          .font(.system(size: 6)).foregroundColor(theme.textDim)
                  }
                  .frame(maxWidth: .infinity)
              }
          }
      }

      // Exposed static for testing
      static func barColor(ratio: Double, theme: ThemeTokens, t1: Int, t2: Int, t3: Int) -> Color {
          let pct = Int(ratio * 100)
          switch pct {
          case 0:          return theme.bar[0]
          case 1..<t2:     return theme.bar[1]
          case t2..<t3:    return theme.bar[2]
          case t3..<100:   return theme.bar[3]
          default:         return theme.bar[4]
          }
      }
  }
  ```

- [ ] **Step 3: Run tests**

  ```bash
  make test 2>&1 | grep -E "(PASS|FAIL|BarColor)"
  ```
  Expected: All 5 PASS.

- [ ] **Step 4: Commit**

  ```bash
  git add Features/Report/BarChartView.swift Tests/UnitTests/BarColorTests.swift
  git commit -m "feat(R-02): BarChartView (5-stop theme ramp, animated, barColor static helper)"
  ```

---

## Task R-03: SessionDetailView

**Dependencies:** R-01 ✓  
**Files:**
- Create: `Features/Report/SessionDetailView.swift`

- [ ] **Step 1: Implement SessionDetailView**

  `Features/Report/SessionDetailView.swift`:
  ```swift
  import SwiftUI

  struct SessionDetailView: View {
      let session: RunSession
      @Environment(ThemeManager.self) private var themeManager
      private var theme: ThemeTokens { themeManager.current }

      var body: some View {
          ScrollView {
              VStack(alignment: .leading, spacing: 16) {
                  // Hero
                  VStack(alignment: .leading, spacing: 2) {
                      Text("\(Int(session.duration / 60))")
                          .font(.system(size: 46, weight: .ultraLight)).foregroundColor(theme.text)
                      Text("min · \(session.startDate, format: .dateTime.month().day().year())")
                          .font(.system(size: 10)).foregroundColor(theme.textDim)
                  }
                  .padding(.horizontal, 16)

                  // Metric grid
                  LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                      metricCell("Distance",   value: String(format: "%.2f km", session.distance / 1000))
                      metricCell("Calories",   value: "\(Int(session.calories)) kcal")
                      metricCell("Steps",      value: "\(session.steps)")
                      metricCell("Avg HR",     value: session.avgHR > 0 ? "\(session.avgHR) bpm" : "—")
                      metricCell("Max HR",     value: session.maxHR > 0 ? "\(session.maxHR) bpm" : "—")
                      metricCell("Cadence",    value: session.avgCadence > 0 ? "\(session.avgCadence) spm" : "—")
                      metricCell("BPM",        value: "\(session.bpm)")
                      metricCell("Mode",       value: session.mode.rawValue.capitalized)
                  }
                  .padding(.horizontal, 12)
              }
              .padding(.top, 12)
          }
          .background(theme.bg)
          .navigationTitle("Session")
          .navigationBarTitleDisplayMode(.inline)
      }

      private func metricCell(_ label: String, value: String) -> some View {
          VStack(alignment: .leading, spacing: 4) {
              Text(label).font(.system(size: 7)).foregroundColor(theme.textDim)
              Text(value).font(.system(size: 16, weight: .ultraLight)).foregroundColor(theme.textMid)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(10)
          .background(theme.card)
          .cornerRadius(9)
      }
  }
  ```

- [ ] **Step 2: Build check**

  ```bash
  make build 2>&1 | tail -5
  ```

- [ ] **Step 3: Commit**

  ```bash
  git add Features/Report/SessionDetailView.swift
  git commit -m "feat(R-03): SessionDetailView (full metric breakdown)"
  ```

---

## Task U-01: SummaryView + SummaryViewModel

**Dependencies:** T-01 ✓, M-01 ✓, H-01 ✓, D-01 ✓  
**Files:**
- Create: `Features/Summary/SummaryViewModel.swift`
- Create: `Features/Summary/SummaryView.swift`
- Test: `Tests/UnitTests/SummaryViewModelTests.swift`

- [ ] **Step 1: Write failing tests**

  `Tests/UnitTests/SummaryViewModelTests.swift`:
  ```swift
  import XCTest
  @testable import nikoneko

  final class SummaryViewModelTests: XCTestCase {

      func test_streakCountsConsecutiveDays() {
          let summaries = (0..<5).map { i in
              DaySessionSummary(
                  date: Calendar.current.date(byAdding: .day, value: -i, to: Date())!,
                  duration: 1200,
                  completionRatio: 1.0,
                  hrAvg: 120,
                  steps: 2000
              )
          }
          let streak = AppGroupDefaults.currentStreak(from: summaries, goalMinutes: 15)
          XCTAssertEqual(streak, 5)
      }

      func test_streakBreaksOnMissedDay() {
          var summaries = (0..<3).map { i in
              DaySessionSummary(
                  date: Calendar.current.date(byAdding: .day, value: -i, to: Date())!,
                  duration: 1200,
                  completionRatio: 1.0,
                  hrAvg: 120,
                  steps: 2000
              )
          }
          // day 3 missing, then day 4
          summaries.append(DaySessionSummary(
              date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
              duration: 1200,
              completionRatio: 1.0,
              hrAvg: 120,
              steps: 2000
          ))
          let streak = AppGroupDefaults.currentStreak(from: summaries, goalMinutes: 15)
          XCTAssertEqual(streak, 3)
      }

      func test_weekDotsCount() {
          let vm = SummaryViewModel(
              session: RunSession(startDate: Date(), duration: 1200),
              summaries: [],
              goalMinutes: 20
          )
          XCTAssertEqual(vm.thisWeekDots.count, 7)
      }
  }
  ```

- [ ] **Step 2: Implement SummaryViewModel**

  `Features/Summary/SummaryViewModel.swift`:
  ```swift
  import Foundation

  enum DotState { case empty, partial, achieved }

  @Observable
  final class SummaryViewModel {
      let session: RunSession
      let streakDays: Int
      let thisWeekDots: [DotState]
      let totalHours: Double

      init(session: RunSession, summaries: [DaySessionSummary], goalMinutes: Int) {
          self.session = session
          self.streakDays = AppGroupDefaults.currentStreak(from: summaries, goalMinutes: goalMinutes)

          let cal = Calendar.current
          let weekStart = cal.dateInterval(of: .weekOfYear, for: Date())!.start
          self.thisWeekDots = (0..<7).map { dayOffset in
              let day = cal.date(byAdding: .day, value: dayOffset, to: weekStart)!
              let dayTotal = summaries
                  .filter { cal.isDate($0.date, inSameDayAs: day) }
                  .reduce(0) { $0 + $1.duration }
              let goal = Double(goalMinutes) * 60
              if dayTotal >= goal { return .achieved }
              if dayTotal > 0 { return .partial }
              return .empty
          }

          self.totalHours = summaries.reduce(0) { $0 + $1.duration } / 3600
      }
  }
  ```

- [ ] **Step 3: Implement SummaryView**

  `Features/Summary/SummaryView.swift`:
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
          VStack(spacing: 20) {
              Spacer()

              // Character (faster speed on summary)
              PlaceholderCharacterView(
                  characterId: session.characterId,
                  color: theme.accentMid,
                  speedMultiplier: 1.5,
                  isAnimating: true
              )
              .frame(height: 60)

              // Hero
              VStack(spacing: 2) {
                  Text("\(Int(session.duration / 60))")
                      .font(.system(size: 46, weight: .ultraLight)).foregroundColor(theme.text)
                  Text("min").font(.system(size: 9)).foregroundColor(theme.textDim)
                  Text("DURATION").font(.system(size: 7)).tracking(1).foregroundColor(theme.textDim)
              }

              // 2×2 stat grid
              LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                  statCell("Avg HR", value: session.avgHR > 0 ? "\(session.avgHR)" : "—")
                  statCell("BPM",    value: "\(session.bpm)")
                  statCell("Goal",   value: session.duration >= Double(goalMinutes * 60) ? "100%" : "\(Int(session.duration / Double(goalMinutes * 60) * 100))%")
                  statCell("Total",  value: String(format: "%.1fh", vm.totalHours))
              }
              .padding(.horizontal, 32)

              // Streak chip
              streakChip(vm)

              Spacer()

              Button("Done") { dismiss() }
                  .font(.system(size: 16, weight: .medium))
                  .foregroundColor(theme.text)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 14)
                  .background(theme.surface)
                  .cornerRadius(12)
                  .padding(.horizontal, 32)
                  .padding(.bottom, 24)
          }
      }

      private func statCell(_ label: String, value: String) -> some View {
          VStack(spacing: 4) {
              Text(value).font(.system(size: 18, weight: .ultraLight)).foregroundColor(theme.textMid)
              Text(label).font(.system(size: 7)).foregroundColor(theme.textDim)
          }
          .frame(maxWidth: .infinity)
          .padding(10)
          .background(theme.surface)
          .cornerRadius(10)
      }

      private func streakChip(_ vm: SummaryViewModel) -> some View {
          VStack(spacing: 8) {
              HStack(spacing: 4) {
                  Text("\(vm.streakDays)")
                      .font(.system(size: 28, weight: .ultraLight)).foregroundColor(theme.accent)
                  Text("day streak").font(.system(size: 9)).foregroundColor(theme.textDim)
              }
              HStack(spacing: 4) {
                  ForEach(vm.thisWeekDots.indices, id: \.self) { i in
                      RoundedRectangle(cornerRadius: 2)
                          .fill(dotColor(vm.thisWeekDots[i]))
                          .frame(width: 8, height: 8)
                  }
              }
          }
          .padding(14)
          .background(theme.surface)
          .cornerRadius(12)
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

- [ ] **Step 4: Run tests**

  ```bash
  make test 2>&1 | grep -E "(PASS|FAIL|SummaryViewModel)"
  ```
  Expected: All 3 PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add Features/Summary/ Tests/UnitTests/SummaryViewModelTests.swift
  git commit -m "feat(U-01): SummaryView + SummaryViewModel (streak calc, week dots, session stats)"
  ```

---

## Task U-02: ShareCardView

**Dependencies:** U-01 ✓, F-02 ✓  
**Files:**
- Create: `Features/Summary/ShareCardView.swift`

- [ ] **Step 1: Implement ShareCardView**

  `Features/Summary/ShareCardView.swift`:
  ```swift
  import SwiftUI

  struct ShareCardView: View {
      let session: RunSession
      let theme: ThemeTokens

      var body: some View {
          VStack(spacing: 12) {
              Text("NIKO NEKO")
                  .font(.system(size: 11, weight: .medium))
                  .tracking(3)
                  .foregroundColor(theme.textDim)

              Text("\(Int(session.duration / 60))")
                  .font(.system(size: 64, weight: .ultraLight))
                  .foregroundColor(theme.text)
                  .monospacedDigit()

              Text("min · \(session.startDate, format: .dateTime.month().day())")
                  .font(.system(size: 10))
                  .foregroundColor(theme.textDim)
          }
          .frame(width: 300, height: 200)
          .background(theme.bg)
      }

      @MainActor
      static func render(session: RunSession, theme: ThemeTokens) -> UIImage? {
          let view = ShareCardView(session: session, theme: theme)
          let renderer = ImageRenderer(content: view)
          renderer.scale = 3.0
          return renderer.uiImage
      }
  }
  ```

- [ ] **Step 2: Wire share button in SummaryView**

  In `Features/Summary/SummaryView.swift`, add after the "Done" button:
  ```swift
  Button("Share") {
      if let img = ShareCardView.render(session: session, theme: theme) {
          let av = UIActivityViewController(activityItems: [img], applicationActivities: nil)
          UIApplication.shared.connectedScenes
              .compactMap { $0 as? UIWindowScene }
              .first?.windows.first?.rootViewController?
              .present(av, animated: true)
      }
  }
  .font(.system(size: 13))
  .foregroundColor(theme.textDim)
  ```

- [ ] **Step 3: Build check**

  ```bash
  make build 2>&1 | tail -5
  ```

- [ ] **Step 4: Commit**

  ```bash
  git add Features/Summary/ShareCardView.swift Features/Summary/SummaryView.swift
  git commit -m "feat(U-02): ShareCardView (ImageRenderer, theme-colored minimal card) + share sheet"
  ```

---

## Tasks W-01, W-02, W-03, W-04: Widget Extension

**Dependencies:** S-02 ✓  
**Files:**
- Create: `Widgets/NikoNekoWidgetBundle.swift`
- Create: `Widgets/WidgetSharedData.swift`
- Create: `Widgets/StreakWidget.swift`
- Create: `Widgets/TotalTimeWidget.swift`
- Create: `Widgets/HeatmapWidget.swift`
- Create: `Widgets/CalendarWidget.swift`
- Test: `Tests/IntegrationTests/WidgetDataTests.swift`

- [ ] **Step 1: Write integration test**

  `Tests/IntegrationTests/WidgetDataTests.swift`:
  ```swift
  import XCTest
  @testable import nikoneko

  final class WidgetDataTests: XCTestCase {

      func test_barColorBoundaries() {
          let theme = ThemeLibrary.obsidian
          XCTAssertEqual(WidgetSharedData.barColor(ratio: 0.0,  theme: theme, t1: 10, t2: 50, t3: 90), theme.cal[0])
          XCTAssertEqual(WidgetSharedData.barColor(ratio: 0.05, theme: theme, t1: 10, t2: 50, t3: 90), theme.cal[1])
          XCTAssertEqual(WidgetSharedData.barColor(ratio: 0.30, theme: theme, t1: 10, t2: 50, t3: 90), theme.cal[2])
          XCTAssertEqual(WidgetSharedData.barColor(ratio: 0.70, theme: theme, t1: 10, t2: 50, t3: 90), theme.cal[3])
          XCTAssertEqual(WidgetSharedData.barColor(ratio: 1.0,  theme: theme, t1: 10, t2: 50, t3: 90), theme.cal[4])
      }

      func test_streakCalculation() {
          let summaries = (0..<7).map { i in
              DaySessionSummary(
                  date: Calendar.current.date(byAdding: .day, value: -i, to: Date())!,
                  duration: 1800, completionRatio: 1.0, hrAvg: 120, steps: 3000
              )
          }
          let streak = AppGroupDefaults.currentStreak(from: summaries, goalMinutes: 20)
          XCTAssertEqual(streak, 7)
      }
  }
  ```

- [ ] **Step 2: Implement WidgetSharedData**

  `Widgets/WidgetSharedData.swift`:
  ```swift
  import SwiftUI
  import WidgetKit

  struct WidgetSharedData {
      static func barColor(ratio: Double, theme: ThemeTokens, t1: Int, t2: Int, t3: Int) -> Color {
          let pct = Int(ratio * 100)
          switch pct {
          case 0:         return theme.cal[0]
          case 1..<t2:    return theme.cal[1]
          case t2..<t3:   return theme.cal[2]
          case t3..<100:  return theme.cal[3]
          default:        return theme.cal[4]
          }
      }

      static func loadTheme() -> ThemeTokens {
          let id = AppGroupDefaults.shared.string(forKey: "activeThemeId") ?? "obsidian"
          return ThemeLibrary.all.first { $0.id == id } ?? ThemeLibrary.obsidian
      }
  }
  ```

- [ ] **Step 3: Implement StreakWidget + TotalTimeWidget**

  `Widgets/StreakWidget.swift`:
  ```swift
  import WidgetKit
  import SwiftUI

  struct StreakEntry: TimelineEntry {
      let date: Date
      let streak: Int
      let theme: ThemeTokens
  }

  struct StreakProvider: TimelineProvider {
      func placeholder(in context: Context) -> StreakEntry {
          StreakEntry(date: Date(), streak: 7, theme: ThemeLibrary.obsidian)
      }
      func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
          completion(entry())
      }
      func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
          let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
          completion(Timeline(entries: [entry()], policy: .after(next)))
      }
      private func entry() -> StreakEntry {
          let theme = WidgetSharedData.loadTheme()
          let summaries = AppGroupDefaults.loadSummaries()
          let goal = AppGroupDefaults.shared.integer(forKey: "dailyGoalMinutes")
          let streak = AppGroupDefaults.currentStreak(from: summaries, goalMinutes: max(goal, 1))
          return StreakEntry(date: Date(), streak: streak, theme: theme)
      }
  }

  struct StreakWidgetView: View {
      let entry: StreakEntry
      var body: some View {
          VStack(alignment: .leading, spacing: 4) {
              Text("STREAK").font(.system(size: 8)).tracking(1).foregroundColor(entry.theme.textDim)
              Text("\(entry.streak)")
                  .font(.system(size: 32, weight: .ultraLight)).foregroundColor(entry.theme.accent)
              Text("days").font(.system(size: 9)).foregroundColor(entry.theme.textDim)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
          .padding(14)
          .background(entry.theme.bg)
          .containerBackground(entry.theme.bg, for: .widget)
      }
  }

  struct StreakWidget: Widget {
      let kind = "StreakWidget"
      var body: some WidgetConfiguration {
          StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
              StreakWidgetView(entry: entry)
          }
          .configurationDisplayName("Streak")
          .description("Your current run streak.")
          .supportedFamilies([.systemSmall])
      }
  }
  ```

  `Widgets/TotalTimeWidget.swift`:
  ```swift
  import WidgetKit
  import SwiftUI

  struct TotalTimeEntry: TimelineEntry {
      let date: Date
      let totalHours: Double
      let theme: ThemeTokens
  }

  struct TotalTimeProvider: TimelineProvider {
      func placeholder(in context: Context) -> TotalTimeEntry {
          TotalTimeEntry(date: Date(), totalHours: 48.4, theme: ThemeLibrary.obsidian)
      }
      func getSnapshot(in context: Context, completion: @escaping (TotalTimeEntry) -> Void) {
          completion(entry())
      }
      func getTimeline(in context: Context, completion: @escaping (Timeline<TotalTimeEntry>) -> Void) {
          let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
          completion(Timeline(entries: [entry()], policy: .after(next)))
      }
      private func entry() -> TotalTimeEntry {
          let theme = WidgetSharedData.loadTheme()
          let total = AppGroupDefaults.loadSummaries().reduce(0) { $0 + $1.duration } / 3600
          return TotalTimeEntry(date: Date(), totalHours: total, theme: theme)
      }
  }

  struct TotalTimeWidgetView: View {
      let entry: TotalTimeEntry
      var body: some View {
          VStack(alignment: .leading, spacing: 4) {
              Text("TOTAL").font(.system(size: 8)).tracking(1).foregroundColor(entry.theme.textDim)
              Text(String(format: "%.1f", entry.totalHours))
                  .font(.system(size: 32, weight: .ultraLight)).foregroundColor(entry.theme.accent)
              Text("hours").font(.system(size: 9)).foregroundColor(entry.theme.textDim)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
          .padding(14)
          .background(entry.theme.bg)
          .containerBackground(entry.theme.bg, for: .widget)
      }
  }

  struct TotalTimeWidget: Widget {
      let kind = "TotalTimeWidget"
      var body: some WidgetConfiguration {
          StaticConfiguration(kind: kind, provider: TotalTimeProvider()) { entry in
              TotalTimeWidgetView(entry: entry)
          }
          .configurationDisplayName("Total Time")
          .description("Cumulative jogging hours.")
          .supportedFamilies([.systemSmall])
      }
  }
  ```

- [ ] **Step 4: Implement HeatmapWidget**

  `Widgets/HeatmapWidget.swift`:
  ```swift
  import WidgetKit
  import SwiftUI

  struct HeatmapEntry: TimelineEntry {
      let date: Date
      let summaries: [DaySessionSummary]
      let theme: ThemeTokens
      let t1: Int; let t2: Int; let t3: Int
  }

  struct HeatmapProvider: TimelineProvider {
      func placeholder(in context: Context) -> HeatmapEntry {
          HeatmapEntry(date: Date(), summaries: [], theme: ThemeLibrary.obsidian, t1: 10, t2: 50, t3: 90)
      }
      func getSnapshot(in context: Context, completion: @escaping (HeatmapEntry) -> Void) {
          completion(entry())
      }
      func getTimeline(in context: Context, completion: @escaping (Timeline<HeatmapEntry>) -> Void) {
          let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
          completion(Timeline(entries: [entry()], policy: .after(next)))
      }
      private func entry() -> HeatmapEntry {
          HeatmapEntry(
              date: Date(),
              summaries: AppGroupDefaults.loadSummaries(),
              theme: WidgetSharedData.loadTheme(),
              t1: 10, t2: 50, t3: 90
          )
      }
  }

  struct HeatmapWidgetView: View {
      let entry: HeatmapEntry
      private let cols = 18, rows = 7

      var body: some View {
          VStack(alignment: .leading, spacing: 4) {
              Text("THIS YEAR")
                  .font(.system(size: 7)).tracking(1).foregroundColor(entry.theme.textDim)
              // 18×7 grid
              let cells = buildCells()
              LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: cols),
                        spacing: 2) {
                  ForEach(0..<cols * rows, id: \.self) { i in
                      let ratio = cells[safe: i] ?? 0.0
                      RoundedRectangle(cornerRadius: 1.5)
                          .fill(WidgetSharedData.barColor(
                              ratio: ratio, theme: entry.theme,
                              t1: entry.t1, t2: entry.t2, t3: entry.t3))
                          .aspectRatio(1, contentMode: .fit)
                  }
              }
          }
          .padding(12)
          .background(entry.theme.bg)
          .containerBackground(entry.theme.bg, for: .widget)
      }

      private func buildCells() -> [Double] {
          let cal = Calendar.current
          let today = cal.startOfDay(for: Date())
          let totalCells = cols * rows
          var result = [Double](repeating: 0, count: totalCells)
          for i in 0..<totalCells {
              let daysAgo = totalCells - 1 - i
              let day = cal.date(byAdding: .day, value: -daysAgo, to: today)!
              let dayTotal = entry.summaries
                  .filter { cal.isDate($0.date, inSameDayAs: day) }
                  .reduce(0) { $0 + $1.completionRatio }
              result[i] = min(1.0, dayTotal)
          }
          return result
      }
  }

  struct HeatmapWidget: Widget {
      let kind = "HeatmapWidget"
      var body: some WidgetConfiguration {
          StaticConfiguration(kind: kind, provider: HeatmapProvider()) { entry in
              HeatmapWidgetView(entry: entry)
          }
          .configurationDisplayName("Year Heatmap")
          .description("GitHub-style activity grid.")
          .supportedFamilies([.systemMedium])
      }
  }

  extension Array {
      subscript(safe index: Int) -> Element? {
          indices.contains(index) ? self[index] : nil
      }
  }
  ```

- [ ] **Step 5: Implement CalendarWidget**

  `Widgets/CalendarWidget.swift`:
  ```swift
  import WidgetKit
  import SwiftUI

  struct CalendarEntry: TimelineEntry {
      let date: Date
      let summaries: [DaySessionSummary]
      let theme: ThemeTokens
      let t1: Int; let t2: Int; let t3: Int
  }

  struct CalendarProvider: TimelineProvider {
      func placeholder(in context: Context) -> CalendarEntry {
          CalendarEntry(date: Date(), summaries: [], theme: ThemeLibrary.obsidian, t1: 10, t2: 50, t3: 90)
      }
      func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
          completion(entry())
      }
      func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
          let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
          completion(Timeline(entries: [entry()], policy: .after(next)))
      }
      private func entry() -> CalendarEntry {
          CalendarEntry(
              date: Date(), summaries: AppGroupDefaults.loadSummaries(),
              theme: WidgetSharedData.loadTheme(), t1: 10, t2: 50, t3: 90
          )
      }
  }

  struct CalendarWidgetView: View {
      let entry: CalendarEntry
      private let cal = Calendar.current
      private let dayHeaders = ["S","M","T","W","T","F","S"]

      var body: some View {
          let monthStart = cal.dateInterval(of: .month, for: entry.date)!.start
          let firstWeekday = cal.component(.weekday, from: monthStart) - 1
          let daysInMonth = cal.range(of: .day, in: .month, for: entry.date)!.count

          VStack(alignment: .leading, spacing: 3) {
              // Month label
              HStack {
                  Text(entry.date, format: .dateTime.month(.wide).year())
                      .font(.system(size: 11, weight: .medium)).foregroundColor(entry.theme.text)
                  Spacer()
              }

              // Day headers
              HStack(spacing: 2) {
                  ForEach(dayHeaders, id: \.self) { d in
                      Text(d).font(.system(size: 7)).foregroundColor(entry.theme.textDim)
                          .frame(maxWidth: .infinity)
                  }
              }

              // Grid
              LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7),
                        spacing: 2) {
                  ForEach(0..<firstWeekday, id: \.self) { _ in Color.clear.aspectRatio(1, contentMode: .fit) }
                  ForEach(1...daysInMonth, id: \.self) { day in
                      let date = cal.date(from: DateComponents(
                          year: cal.component(.year, from: entry.date),
                          month: cal.component(.month, from: entry.date),
                          day: day))!
                      let dayTotal = entry.summaries
                          .filter { cal.isDate($0.date, inSameDayAs: date) }
                          .reduce(0) { $0 + $1.completionRatio }
                      let ratio = min(1.0, dayTotal)
                      let isToday = cal.isDateInToday(date)

                      ZStack {
                          RoundedRectangle(cornerRadius: 2)
                              .fill(WidgetSharedData.barColor(
                                  ratio: ratio, theme: entry.theme,
                                  t1: entry.t1, t2: entry.t2, t3: entry.t3))
                          if isToday {
                              RoundedRectangle(cornerRadius: 2).stroke(entry.theme.text, lineWidth: 1)
                          }
                          Text("\(day)")
                              .font(.system(size: 6.5))
                              .foregroundColor(entry.theme.text.opacity(ratio > 0 ? 0.8 : 0.4))
                      }
                      .aspectRatio(1, contentMode: .fit)
                  }
              }
          }
          .padding(10)
          .background(entry.theme.bg)
          .containerBackground(entry.theme.bg, for: .widget)
      }
  }

  struct CalendarWidget: Widget {
      let kind = "CalendarWidget"
      var body: some WidgetConfiguration {
          StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
              CalendarWidgetView(entry: entry)
          }
          .configurationDisplayName("Month Calendar")
          .description("Full month activity calendar.")
          .supportedFamilies([.systemLarge])
      }
  }
  ```

- [ ] **Step 6: Implement NikoNekoWidgetBundle**

  `Widgets/NikoNekoWidgetBundle.swift`:
  ```swift
  import WidgetKit
  import SwiftUI

  @main
  struct NikoNekoWidgetBundle: WidgetBundle {
      var body: some Widget {
          StreakWidget()
          TotalTimeWidget()
          HeatmapWidget()
          CalendarWidget()
      }
  }
  ```

- [ ] **Step 7: Run tests**

  ```bash
  make test 2>&1 | grep -E "(PASS|FAIL|WidgetData)"
  ```
  Expected: All 2 PASS.

- [ ] **Step 8: Commit**

  ```bash
  git add Widgets/
  git commit -m "feat(W-01,W-02,W-03,W-04): All 4 widgets (Streak, TotalTime, Heatmap, Calendar) + WidgetSharedData"
  ```

---

## Tasks L-01, L-02, L-03: Live Activity + Dynamic Island

**Dependencies:** T-01 ✓  
**Files:**
- Create: `LiveActivity/NikoNekoLiveActivityAttributes.swift`
- Create: `LiveActivity/NikoNekoLiveActivityView.swift`
- Create: `Services/LiveActivityService.swift`

- [ ] **Step 1: Implement NikoNekoLiveActivityAttributes**

  `LiveActivity/NikoNekoLiveActivityAttributes.swift`:
  ```swift
  import ActivityKit
  import Foundation

  struct NikoNekoLiveActivityAttributes: ActivityAttributes {
      public struct ContentState: Codable, Hashable {
          var elapsed: TimeInterval
          var remaining: TimeInterval
          var bpm: Int
          var characterId: String
          var themeId: String
          var isCountdown: Bool
      }
  }
  ```

- [ ] **Step 2: Implement LiveActivityService**

  `Services/LiveActivityService.swift`:
  ```swift
  import ActivityKit

  @Observable
  final class LiveActivityService {
      private var activity: Activity<NikoNekoLiveActivityAttributes>?

      func start(bpm: Int, target: TimeInterval, characterId: String, themeId: String) {
          guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
          let state = NikoNekoLiveActivityAttributes.ContentState(
              elapsed: 0, remaining: target, bpm: bpm,
              characterId: characterId, themeId: themeId, isCountdown: target > 0
          )
          activity = try? Activity.request(
              attributes: NikoNekoLiveActivityAttributes(),
              contentState: state,
              pushType: nil
          )
      }

      func update(elapsed: TimeInterval, remaining: TimeInterval) {
          guard let a = activity else { return }
          Task {
              var s = a.contentState
              s.elapsed = elapsed
              s.remaining = remaining
              await a.update(using: s)
          }
      }

      func end() {
          Task { await activity?.end(dismissalPolicy: .immediate) }
          activity = nil
      }
  }
  ```

- [ ] **Step 3: Implement Dynamic Island and Lock Screen views**

  `LiveActivity/NikoNekoLiveActivityView.swift`:
  ```swift
  import SwiftUI
  import ActivityKit
  import WidgetKit

  struct NikoNekoLiveActivityView: Widget {
      var body: some WidgetConfiguration {
          ActivityConfiguration(for: NikoNekoLiveActivityAttributes.self) { context in
              // Lock Screen card
              let theme = WidgetSharedData.loadTheme()
              LockScreenCardView(state: context.state, theme: theme)
          } dynamicIsland: { context in
              let theme = WidgetSharedData.loadTheme()
              return DynamicIsland {
                  // Expanded
                  DynamicIslandExpandedRegion(.leading) {
                      VStack(alignment: .leading, spacing: 2) {
                          Text("JOG").font(.system(size: 8)).tracking(1).foregroundColor(theme.textDim)
                          Text(formattedTime(context.state, theme: theme))
                              .font(.system(size: 26, weight: .ultraLight)).foregroundColor(theme.text)
                              .monospacedDigit()
                      }
                  }
                  DynamicIslandExpandedRegion(.trailing) {
                      VStack(alignment: .trailing, spacing: 4) {
                          PlaceholderCharacterView(
                              characterId: context.state.characterId,
                              color: theme.accentMid,
                              speedMultiplier: Double(context.state.bpm) / 180.0,
                              isAnimating: true
                          )
                          .frame(width: 44, height: 32)
                          Text("♩ \(context.state.bpm)")
                              .font(.system(size: 9)).foregroundColor(theme.textDim)
                      }
                  }
              } compactLeading: {
                  PlaceholderCharacterView(
                      characterId: context.state.characterId,
                      color: theme.accentMid,
                      speedMultiplier: Double(context.state.bpm) / 180.0,
                      isAnimating: true
                  )
                  .frame(width: 22, height: 22)
              } compactTrailing: {
                  Text(formattedTime(context.state, theme: theme))
                      .font(.system(size: 14, weight: .light)).foregroundColor(theme.text)
                      .monospacedDigit()
              } minimal: {
                  PlaceholderCharacterView(
                      characterId: context.state.characterId,
                      color: theme.accentMid,
                      speedMultiplier: 1.0,
                      isAnimating: true
                  )
                  .frame(width: 18, height: 18)
              }
          }
      }

      private func formattedTime(_ state: NikoNekoLiveActivityAttributes.ContentState, theme: ThemeTokens) -> String {
          let t = state.isCountdown ? state.remaining : state.elapsed
          let min = Int(t / 60)
          let sec = Int(t) % 60
          return String(format: "%d:%02d", min, sec)
      }
  }

  struct LockScreenCardView: View {
      let state: NikoNekoLiveActivityAttributes.ContentState
      let theme: ThemeTokens

      var body: some View {
          HStack {
              VStack(alignment: .leading, spacing: 4) {
                  Text("JOG").font(.system(size: 8)).tracking(1).foregroundColor(theme.textDim)
                  Text(formattedTime)
                      .font(.system(size: 36, weight: .ultraLight)).foregroundColor(theme.text)
                      .monospacedDigit()
                  Text("♩ \(state.bpm)").font(.system(size: 10)).foregroundColor(theme.textDim)
              }
              Spacer()
              PlaceholderCharacterView(
                  characterId: state.characterId,
                  color: theme.accentMid,
                  speedMultiplier: Double(state.bpm) / 180.0,
                  isAnimating: true
              )
              .frame(width: 52, height: 40)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 14)
          .background(theme.bg.opacity(0.88))
      }

      private var formattedTime: String {
          let t = state.isCountdown ? state.remaining : state.elapsed
          let min = Int(t / 60)
          let sec = Int(t) % 60
          return String(format: "%d:%02d", min, sec)
      }
  }
  ```

- [ ] **Step 4: Build check**

  ```bash
  make build 2>&1 | tail -5
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

  ```bash
  git add LiveActivity/ Services/LiveActivityService.swift
  git commit -m "feat(L-01,L-02,L-03): NikoNekoLiveActivityAttributes, LiveActivityService, Dynamic Island (compact+expanded), Lock Screen card"
  ```

---

## Wave 2 Complete ✓

Update `PROGRESS.md` — move all Wave 2 tasks to ✅ Done, move Wave 3 tasks to 🟡 In Progress.

import SwiftUI
import SwiftData

struct ReportView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    @Query(sort: \RunSession.startDate, order: .reverse) private var sessions: [RunSession]
    @State private var vm = ReportViewModel()
    @State private var selectedSession: RunSession? = nil
    @State private var tappedBar: ChartBar? = nil
    @State private var tappedBarX: CGFloat = 0
    @State private var showStreakToast = false
    @State private var isNewRecord = false
    @Environment(\.dismiss) private var dismiss

    private static let bestStreakKey = "nikoneko.bestStreak"

    private var theme: ThemeTokens { themeManager.current }

    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(theme.text)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                periodTabs
                    .padding(.bottom, -12)
                dateNavRow

                // DURATION
                heroBlock

                // SUMMARY (metric cards)
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader(lm.L("report.section.summary"))
                        .padding(.horizontal, 18)
                    metricCards
                }

                // CHART
                VStack(spacing: 8) {
                    sectionHeader("\(lm.L("report.section.chart")) · \(vm.metricLabel(vm.selectedMetric).uppercased())")
                        .padding(.horizontal, 18)
                    if vm.period == .month || vm.period == .year {
                        HeatmapView(bars: vm.chartBars, period: vm.period, valueUnit: vm.metricUnit(vm.selectedMetric), yearStartWeekday: vm.yearStartWeekday)
                            .padding(.horizontal, 18)
                    } else {
                        BarChartView(
                            bars: vm.chartBars,
                            yUnit: vm.metricUnit(vm.selectedMetric),
                            xUnit: vm.period == .day ? lm.L("report.unit.hour") : lm.L("report.unit.day"),
                            onTap: { bar, x in
                                if bar.value > 0 {
                                    tappedBar = bar
                                    tappedBarX = x
                                } else {
                                    tappedBar = nil
                                }
                            }
                        )
                        .padding(.horizontal, 18)
                        .overlay(alignment: .topLeading) {
                            if let bar = tappedBar {
                                Text(bar.displayValue)
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.text)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(theme.surface)
                                    .cornerRadius(6)
                                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                                    .offset(x: max(0, tappedBarX + 18 - 30))
                                    .transition(.opacity)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }

                // SESSIONS
                if vm.period != .month && vm.period != .year {
                    logList
                }
            }
            .padding(.bottom, 20)
        }
        .background(theme.bg.ignoresSafeArea())
        .navigationTitle(lm.L("report.title"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }
        }
        .sheet(item: $selectedSession) { session in
            SessionDetailSheet(session: session)
                .presentationDetents([.fraction(0.55)])
                .presentationDragIndicator(.hidden)
        }
        .overlay(alignment: .top) {
            if showStreakToast {
                streakToast
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .onAppear {
            #if DEBUG
            injectSeedData()
            #endif
            vm.loadSessions(sessions)
            let streak = vm.currentStreak
            if streak > 0 {
                let best = UserDefaults.standard.integer(forKey: Self.bestStreakKey)
                if streak > best {
                    UserDefaults.standard.set(streak, forKey: Self.bestStreakKey)
                    isNewRecord = true
                } else {
                    isNewRecord = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(duration: 0.4)) { showStreakToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        withAnimation(.easeOut(duration: 0.3)) { showStreakToast = false }
                    }
                }
            }
        }
        .onChange(of: sessions.count) { _, _ in vm.loadSessions(sessions) }
    }

    // MARK: - Period tabs

    private var periodTabs: some View {
        HStack(spacing: 0) {
            ForEach(ReportViewModel.Period.allCases, id: \.self) { p in
                Button(action: { vm.period = p; vm.currentOffset = 0 }) {
                    VStack(spacing: 0) {
                        Text(lm.L("report.tab.\(p.rawValue)"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(vm.period == p ? theme.accent : theme.text)
                            .padding(.vertical, 9)
                        Rectangle()
                            .fill(vm.period == p ? theme.accent : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Date nav row

    private var dateNavRow: some View {
        HStack {
            Button(action: { vm.currentOffset -= 1 }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(theme.text)
                    .frame(width: 36, height: 36)
            }
            Spacer()
            Text(vm.dateRangeLabel)
                .font(.system(size: 16))
                .foregroundColor(theme.text)
            Spacer()
            Button(action: { if vm.currentOffset < 0 { vm.currentOffset += 1 } }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(vm.currentOffset < 0 ? theme.text : theme.textDim)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
    }

    // MARK: - Hero block

    private var heroBlock: some View {
        Button(action: { vm.selectedMetric = .duration }) {
            VStack(alignment: .leading, spacing: 2) {
                Text(lm.L("report.label.duration"))
                    .font(.system(size: 10))
                    .tracking(0.8)
                    .foregroundColor(theme.textDim)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(lm.L("report.total")) ")
                        .font(.system(size: 24))
                        .foregroundColor(vm.selectedMetric == .duration ? theme.accent : theme.text)
                    Text(heroText)
                        .font(.system(size: 81, weight: .ultraLight))
                        .kerning(-3)
                        .foregroundColor(vm.selectedMetric == .duration ? theme.accent : theme.text)
                        .monospacedDigit()
                    Text(" \(heroUnit)")
                        .font(.system(size: 24))
                        .foregroundColor(vm.selectedMetric == .duration ? theme.accent : theme.text)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.top, 2)
            .padding(.bottom, 8)
        }
        .buttonStyle(.plain)
    }

    private var heroText: String {
        let seconds = vm.heroDuration
        if seconds < 3600 { return "\(Int(seconds / 60))" }
        return String(format: "%.1f", seconds / 3600)
    }

    private var heroUnit: String {
        vm.heroDuration < 3600 ? lm.L("report.unit.min") : lm.L("report.unit.hrs")
    }

    // MARK: - Metric cards

    private var metricCards: some View {
        let metrics: [ReportViewModel.Metric] = vm.period == .day
            ? [.distance, .calories, .steps, .hrAvg, .hrMax, .count]
            : [.distance, .calories, .steps, .hrAvg, .hrMax, .count]

        return LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
            spacing: 4
        ) {
            ForEach(metrics, id: \.self) { metric in
                MetricCard(metric: metric, vm: vm)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 6)
    }

    // MARK: - Log list

    private var logList: some View {
        VStack(spacing: 0) {
            sectionHeader(lm.L("report.section.sessions"))
            if vm.logItems.isEmpty {
                Text(lm.L("report.noData"))
                    .font(.system(size: 14))
                    .foregroundColor(theme.textDim)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(vm.logItems) { session in
                        Button { selectedSession = session } label: {
                            LogRow(session: session, vm: vm)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                }
            }
        }
        .padding(.horizontal, 18)
    }

    #if DEBUG
    @Environment(\.modelContext) private var modelContext
    private func injectSeedData() {
        guard sessions.isEmpty else { return }
        let cal = Calendar.current
        let now = Date()
        let seeds: [(daysAgo: Int, mins: Double, km: Double, kcal: Double, steps: Int, hr: Int)] = [
            (0, 25, 3.2, 180, 3200, 142), (1, 30, 3.8, 210, 3800, 148),
            (2, 20, 2.5, 140, 2500, 135), (4, 35, 4.5, 250, 4500, 155),
            (5, 28, 3.5, 195, 3500, 144), (7, 32, 4.0, 220, 4000, 150),
            (8, 15, 1.8, 100, 1800, 128), (10, 40, 5.1, 280, 5100, 158),
            (11, 22, 2.8, 155, 2800, 138), (13, 30, 3.8, 210, 3800, 147),
            (14, 18, 2.2, 122, 2200, 132), (16, 35, 4.4, 245, 4400, 153),
            (17, 27, 3.4, 188, 3400, 143), (19, 31, 3.9, 216, 3900, 149),
            (20, 24, 3.0, 167, 3000, 140), (22, 38, 4.8, 265, 4800, 157),
            (23, 20, 2.5, 139, 2500, 134), (25, 33, 4.2, 232, 4200, 151),
            (26, 28, 3.5, 194, 3500, 145), (28, 26, 3.3, 183, 3300, 142),
        ]
        for s in seeds {
            let date = cal.date(byAdding: .day, value: -s.daysAgo, to: now)!
            let session = RunSession(
                startDate: cal.date(bySettingHour: 7, minute: Int.random(in: 0...59), second: 0, of: date)!,
                duration: s.mins * 60,
                distance: s.km * 1000,
                calories: s.kcal,
                steps: s.steps,
                avgHR: s.hr,
                maxHR: s.hr + Int.random(in: 5...15),
                avgCadence: Int.random(in: 165...180)
            )
            modelContext.insert(session)
        }
        try? modelContext.save()
    }
    #endif

    private var streakToast: some View {
        let streak = vm.currentStreak
        let messages: [String]
        switch streak {
        case 1:
            messages = [lm.L("streak.msg.1a"), lm.L("streak.msg.1b"), lm.L("streak.msg.1c")]
        case 2, 3:
            messages = [lm.L("streak.msg.2a"), lm.L("streak.msg.2b"), lm.L("streak.msg.2c")]
        case 4...6:
            messages = [lm.L("streak.msg.4a"), lm.L("streak.msg.4b"), lm.L("streak.msg.4c")]
        case 7...13:
            messages = [lm.L("streak.msg.7a"), lm.L("streak.msg.7b"), lm.L("streak.msg.7c")]
        case 14...29:
            messages = [lm.L("streak.msg.14a"), lm.L("streak.msg.14b"), lm.L("streak.msg.14c")]
        default:
            messages = [lm.L("streak.msg.def.a"), lm.L("streak.msg.def.b"), lm.L("streak.msg.def.c")]
        }
        let message = messages[streak % messages.count]

        return HStack(spacing: 14) {
            if isNewRecord {
                LottieTrophyView()
                    .frame(width: 44, height: 44)
            } else {
                Text("\(streak)")
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundColor(theme.accent)
                    .monospacedDigit()
                    .frame(width: 44)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak) \(lm.L("streak.days"))")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textDim)
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(theme.text)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(theme.surface)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.2)) { showStreakToast = false }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10))
            .tracking(0.8)
            .foregroundColor(theme.textDim)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 12)
            .padding(.bottom, 4)
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
            GeometryReader { geo in
                VStack(alignment: .leading, spacing: 0) {
                    // Fixed-size numeral so all cards have the same number height
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(vm.metricValueString(metric))
                            .font(.system(size: 32, weight: .ultraLight))
                            .foregroundColor(isActive ? theme.accent : theme.text)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(vm.metricUnit(metric))
                            .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                            .foregroundColor(isActive ? theme.accent : theme.text)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                    // Icon + label row at bottom
                    HStack(spacing: 4) {
                        Image(systemName: vm.metricIcon(metric))
                            .font(.system(size: 11))
                            .foregroundColor(isActive ? theme.accent : theme.text)
                        Text(vm.metricLabel(metric))
                            .font(.system(size: 11))
                            .foregroundColor(isActive ? theme.accent : theme.text)
                    }
                    .padding(.top, 4)
                }
                .padding(12)
            }
            .aspectRatio(1, contentMode: .fit)
            .background(theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isActive ? theme.accentMid : theme.accentDim,
                        lineWidth: isActive ? 1 : 0.5
                    )
            )
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - LogRow

struct LogRow: View {
    let session: RunSession
    let vm: ReportViewModel
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(dotColor)
                    .frame(width: 6, height: 6)

                // 日期 · 時間 · 時長 橫排
                Text(session.startDate, format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 16))
                    .foregroundColor(theme.text)

                Circle()
                    .fill(theme.textDim)
                    .frame(width: 3, height: 3)

                Text(timeRange)
                    .font(.system(size: 16))
                    .foregroundColor(theme.text)

                Circle()
                    .fill(theme.textDim)
                    .frame(width: 3, height: 3)

                Text("\(Int(session.duration / 60)) \(lm.L("session.unit.min"))")
                    .font(.system(size: 16))
                    .foregroundColor(theme.text)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(theme.textMid)
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())

            Rectangle()
                .fill(theme.accentDim)
                .frame(height: 0.5)
        }
    }

    private var timeRange: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        let end = session.startDate.addingTimeInterval(session.duration)
        return "\(f.string(from: session.startDate)) – \(f.string(from: end))"
    }

    private var dotColor: Color {
        if session.avgHR > 0 { return theme.bar[3] }
        return theme.bar[2]
    }
}

// MARK: - HeatmapView

struct HeatmapView: View {
    let bars: [ChartBar]
    let period: ReportViewModel.Period
    var valueUnit: String = ""
    var yearStartWeekday: Int = 0  // Mon=0 … Sun=6
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    private var theme: ThemeTokens { themeManager.current }
    private var maxValue: Double { bars.map(\.value).max() ?? 1 }

    var body: some View {
        if period == .month { monthGrid } else { yearGrid }
    }

    private var monthGrid: some View {
        let cols = 7
        let rows = Int(ceil(Double(bars.count) / Double(cols)))
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                ForEach([lm.L("heatmap.mon"), lm.L("heatmap.tue"), lm.L("heatmap.wed"),
                         lm.L("heatmap.thu"), lm.L("heatmap.fri"), lm.L("heatmap.sat"), lm.L("heatmap.sun")],
                        id: \.self) { d in
                    Text(String(d.prefix(1))).font(.system(size: 9)).foregroundColor(theme.textDim).frame(maxWidth: .infinity)
                }
            }
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<cols, id: \.self) { col in
                        let idx = row * cols + col
                        if idx < bars.count {
                            cell(bar: bars[idx])
                        } else {
                            Color.clear.aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
    }

    // 3 rows × 4 months each. Each row is a mini GitHub-style heatmap.
    private var yearGrid: some View {
        let cellSize: CGFloat = 14
        let cellSpacing: CGFloat = 3
        let dayLabelWidth: CGFloat = 32
        let rowHeight = 14 + 7 * (cellSize + cellSpacing)
        let monthNames = [
            lm.L("heatmap.month.jan"), lm.L("heatmap.month.feb"),
            lm.L("heatmap.month.mar"), lm.L("heatmap.month.apr"),
            lm.L("heatmap.month.may"), lm.L("heatmap.month.jun"),
            lm.L("heatmap.month.jul"), lm.L("heatmap.month.aug"),
            lm.L("heatmap.month.sep"), lm.L("heatmap.month.oct"),
            lm.L("heatmap.month.nov"), lm.L("heatmap.month.dec"),
        ]
        let cal = Calendar(identifier: .gregorian)

        return VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<3, id: \.self) { rowIdx in
                let startMonth = rowIdx * 4       // 0, 4, 8
                let endMonth = startMonth + 3     // 3, 7, 11

                // Collect days for these 4 months
                let rowBars = barsForMonths(startMonth: startMonth, endMonth: endMonth, cal: cal)
                let firstWD = rowBars.firstWeekday

                let padded: [ChartBar?] = Array(repeating: nil, count: firstWD) + rowBars.bars.map { Optional($0) }
                let totalCols = Int(ceil(Double(padded.count) / 7.0))
                let dayLabels = [lm.L("heatmap.mon"), lm.L("heatmap.tue"), lm.L("heatmap.wed"),
                                 lm.L("heatmap.thu"), lm.L("heatmap.fri"), lm.L("heatmap.sat"), lm.L("heatmap.sun")]

                VStack(alignment: .leading, spacing: 0) {
                    // Month labels
                    HStack(spacing: 0) {
                        Color.clear.frame(width: dayLabelWidth + cellSpacing)
                        ForEach(0..<4, id: \.self) { mi in
                            Text(monthNames[startMonth + mi])
                                .font(.system(size: 9))
                                .foregroundColor(theme.textDim)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(height: 14)

                    HStack(alignment: .top, spacing: cellSpacing) {
                        // Day labels
                        VStack(alignment: .trailing, spacing: cellSpacing) {
                            ForEach(dayLabels.indices, id: \.self) { i in
                                Text(dayLabels[i])
                                    .font(.system(size: 8))
                                    .foregroundColor(theme.textDim)
                                    .frame(width: dayLabelWidth, height: cellSize)
                            }
                        }
                        // Cells
                        HStack(alignment: .top, spacing: cellSpacing) {
                            ForEach(0..<totalCols, id: \.self) { col in
                                VStack(spacing: cellSpacing) {
                                    ForEach(0..<7, id: \.self) { row in
                                        let idx = col * 7 + row
                                        if idx < padded.count, let bar = padded[idx] {
                                            yearCell(bar: bar, size: cellSize)
                                        } else {
                                            Color.clear.frame(width: cellSize, height: cellSize)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(height: rowHeight)
            }
        }
    }

    private struct RowBars { let bars: [ChartBar]; let firstWeekday: Int }

    private func barsForMonths(startMonth: Int, endMonth: Int, cal: Calendar) -> RowBars {
        var comps = cal.dateComponents([.year], from: Date())
        comps.month = startMonth + 1; comps.day = 1
        guard let firstDay = cal.date(from: comps) else { return RowBars(bars: [], firstWeekday: 0) }

        comps.month = endMonth + 1
        guard let lastMonthStart = cal.date(from: comps),
              let lastMonthRange = cal.range(of: .day, in: .month, for: lastMonthStart),
              let lastDay = cal.date(byAdding: .day, value: lastMonthRange.count - 1, to: lastMonthStart)
        else { return RowBars(bars: [], firstWeekday: 0) }

        // Weekday of first day (Mon=0)
        let wd = cal.component(.weekday, from: firstDay)
        let firstWeekday = (wd + 5) % 7

        var result: [ChartBar] = []
        var current = firstDay
        while current <= lastDay {
            let doy = (cal.ordinality(of: .day, in: .year, for: current) ?? 1) - 1
            if doy < bars.count {
                result.append(bars[doy])
            } else {
                result.append(ChartBar(label: "\(cal.component(.day, from: current))", value: 0, isToday: false))
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return RowBars(bars: result, firstWeekday: firstWeekday)
    }

    private func yearCell(bar: ChartBar, size: CGFloat) -> some View {
        let ratio = maxValue > 0 ? bar.value / maxValue : 0
        let bgColor = bar.value == 0
            ? theme.bar[0]
            : BarChartView.barColor(ratio: ratio, theme: theme, t1: 10, t2: 50, t3: 90)
        return RoundedRectangle(cornerRadius: 2)
            .fill(bgColor)
            .frame(width: size, height: size)
            .animation(.easeInOut(duration: 0.25), value: ratio)
    }

    private func cell(bar: ChartBar) -> some View {
        let ratio = maxValue > 0 ? bar.value / maxValue : 0
        let bgColor = bar.value == 0
            ? theme.bar[0]
            : BarChartView.barColor(ratio: ratio, theme: theme, t1: 10, t2: 50, t3: 90)
        let isDark = bar.value / max(maxValue, 1) > 0.4
        let textColor = isDark ? Color.white.opacity(0.9) : theme.textMid

        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(bgColor)
                    .animation(.easeInOut(duration: 0.25), value: ratio)

                VStack(spacing: 0) {
                    // Day number top-left
                    Text(bar.label)
                        .font(.system(size: geo.size.width * 0.2))
                        .foregroundColor(textColor.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, geo.size.width * 0.1)
                        .padding(.top, geo.size.width * 0.08)

                    Spacer()

                    // Value large, centered, no unit
                    if bar.value > 0 {
                        Text(formatValue(bar.value))
                            .font(.system(size: geo.size.width * 0.36, weight: .ultraLight))
                            .foregroundColor(textColor)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    Spacer()
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func formatValue(_ v: Double) -> String {
        if v >= 1000 { return String(format: "%.1fk", v / 1000) }
        if v >= 10   { return "\(Int(v.rounded()))" }
        return String(format: "%.1f", v)
    }
}

// MARK: - SessionDetailSheet

struct SessionDetailSheet: View {
    let session: RunSession
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    @Environment(\.dismiss) private var dismiss
    private var theme: ThemeTokens { themeManager.current }

    private var durationMins: Int { Int(session.duration / 60) }
    private var timeRange: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        let end = session.startDate.addingTimeInterval(session.duration)
        return "\(f.string(from: session.startDate)) – \(f.string(from: end))"
    }
    private var dateLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"
        return f.string(from: session.startDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateLabel).font(.system(size: 16)).foregroundColor(theme.text)
                    Text(timeRange).font(.system(size: 13)).foregroundColor(theme.textDim)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(theme.textDim)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 12)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(lm.L("session.total")) ")
                    .font(.system(size: 22))
                    .foregroundColor(theme.text)
                Text("\(durationMins)")
                    .font(.system(size: 72, weight: .ultraLight))
                    .kerning(-3)
                    .foregroundColor(theme.text)
                    .monospacedDigit()
                Text(" \(lm.L("session.unit.min"))")
                    .font(.system(size: 22))
                    .foregroundColor(theme.text)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 4)

            Text(lm.L("session.summary").uppercased())
                .font(.system(size: 10)).tracking(0.8).foregroundColor(theme.textDim)
                .padding(.horizontal, 20).padding(.bottom, 12)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                statCard("location.circle", String(format: "%.1f", session.distance / 1000), lm.L("session.unit.km"), lm.L("session.stat.distance"))
                statCard("flame", "\(Int(session.calories))", lm.L("session.unit.kcal"), lm.L("session.stat.calories"))
                statCard("shoeprints.fill", stepsStr, "", lm.L("session.stat.steps"))
                statCard("heart", session.avgHR > 0 ? "\(session.avgHR)" : "—", session.avgHR > 0 ? lm.L("session.unit.bpm") : "", lm.L("session.stat.avgHR"))
                statCard("heart", session.maxHR > 0 ? "\(session.maxHR)" : "—", session.maxHR > 0 ? lm.L("session.unit.bpm") : "", lm.L("session.stat.maxHR"))
                statCard("metronome", session.avgCadence > 0 ? "\(session.avgCadence)" : "—", session.avgCadence > 0 ? lm.L("session.unit.spm") : "", lm.L("session.stat.cadence"))
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(theme.bg.ignoresSafeArea())
    }

    private var stepsStr: String {
        session.steps >= 1000 ? String(format: "%.1fk", Double(session.steps) / 1000) : "\(session.steps)"
    }

    private func statCard(_ icon: String, _ value: String, _ unit: String, _ label: String) -> some View {
        GeometryReader { _ in
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundColor(theme.text)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 11))
                            .foregroundColor(theme.text)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                HStack(spacing: 4) {
                    Image(systemName: icon).font(.system(size: 11)).foregroundColor(theme.text)
                    Text(label).font(.system(size: 11)).foregroundColor(theme.text)
                }
                .padding(.top, 4)
            }
            .padding(12)
        }
        .aspectRatio(1, contentMode: .fit)
        .background(theme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.accentDim, lineWidth: 0.5))
        .cornerRadius(14)
    }
}

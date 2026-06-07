import SwiftUI
import WidgetKit

struct WidgetSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    private var theme: ThemeTokens { themeManager.current }

    @State private var selectedIndex: Int = 0

    @State private var statMetric: StatMetric = {
        AppGroupDefaults.shared.string(forKey: "widget.stat.metric")
            .flatMap { StatMetric(rawValue: $0) } ?? .streak
    }()
    @State private var statPeriod: TimePeriod = {
        AppGroupDefaults.shared.string(forKey: "widget.stat.period")
            .flatMap { TimePeriod(rawValue: $0) } ?? .week
    }()
    @State private var calendarMetric: StatMetric = {
        AppGroupDefaults.shared.string(forKey: "widget.calendar.metric")
            .flatMap { StatMetric(rawValue: $0) } ?? .duration
    }()
    @State private var allStatsPeriod: TimePeriod = {
        AppGroupDefaults.shared.string(forKey: "widget.allStats.period")
            .flatMap { TimePeriod(rawValue: $0) } ?? .week
    }()

    @State private var showAddInstructions: Bool = false

    private let widgetDefs: [(name: String, nameZh: String, size: String, kind: String)] = [
        ("Stat",        "數據",     "Small",  "StatWidget"),
        ("Heatmap",     "熱力圖",   "Medium", "HeatmapWidget"),
        ("Bar Chart",   "長條圖",   "Medium", "BarChartWidget"),
        ("Calendar",    "月曆",     "Large",  "CalendarWidget"),
        ("All Stats",   "所有數據", "Large",  "AllStatsWidget"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Gallery
            TabView(selection: $selectedIndex) {
                ForEach(widgetDefs.indices, id: \.self) { i in
                    galleryCard(widgetDefs[i])
                        .tag(i)
                        .padding(.horizontal, 18)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 270)
            .animation(.easeInOut, value: selectedIndex)
            .tint(theme.accent)

            Divider()
                .padding(.top, 8)

            // Settings area
            VStack(alignment: .leading, spacing: 16) {
                parameterSection
                addToHomeButton
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 24)

            Spacer()
        }
        .background(theme.bg.ignoresSafeArea())
        .id(lm.version)
        .navigationTitle(lm.L("widget.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddInstructions) {
            addInstructionsSheet
        }
    }

    // MARK: - Gallery Card

    private func galleryCard(_ w: (name: String, nameZh: String, size: String, kind: String)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(lm.language == .traditionalChinese ? w.nameZh : w.name)
                    .font(.system(size: 15))
                    .foregroundColor(theme.text)
                Text(w.size)
                    .font(.system(size: 11))
                    .foregroundColor(theme.textMid)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(theme.card).cornerRadius(6)
                Spacer()
            }
            widgetPreview(kind: w.kind, widgetTheme: theme)
                .frame(height: previewHeight(size: w.size))
                .cornerRadius(12)
                .clipped()
        }
        .padding(14)
        .background(theme.surface)
        .cornerRadius(14)
    }

    private func previewHeight(size: String) -> CGFloat {
        switch size {
        case "Large":  return 180
        case "Medium": return 110
        default:       return 140
        }
    }

    // MARK: - Parameter Section

    @ViewBuilder
    private var parameterSection: some View {
        switch selectedIndex {
        case 0: // StatWidget
            VStack(alignment: .leading, spacing: 10) {
                pickerRow(
                    label: lm.language == .traditionalChinese ? "指標" : "Metric",
                    options: StatMetric.allCases,
                    selected: $statMetric,
                    display: { metricLabel($0) }
                ) { value in
                    AppGroupDefaults.shared.set(value.rawValue, forKey: "widget.stat.metric")
                    WidgetCenter.shared.reloadAllTimelines()
                }
                pickerRow(
                    label: lm.language == .traditionalChinese ? "時間範圍" : "Period",
                    options: TimePeriod.allCases,
                    selected: $statPeriod,
                    display: { periodLabel($0) }
                ) { value in
                    AppGroupDefaults.shared.set(value.rawValue, forKey: "widget.stat.period")
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        case 1: // HeatmapWidget
            infoText(lm.language == .traditionalChinese
                ? "顯示近 18 週每日活動熱力圖"
                : "Shows 18-week daily activity heatmap")
        case 2: // BarChartWidget
            infoText(lm.language == .traditionalChinese
                ? "顯示本週每日活動長條圖"
                : "Shows this week's daily activity bar chart")
        case 3: // CalendarWidget
            pickerRow(
                label: lm.language == .traditionalChinese ? "指標" : "Metric",
                options: StatMetric.allCases.filter { $0 != .streak },
                selected: $calendarMetric,
                display: { metricLabel($0) }
            ) { value in
                AppGroupDefaults.shared.set(value.rawValue, forKey: "widget.calendar.metric")
                WidgetCenter.shared.reloadAllTimelines()
            }
        case 4: // AllStatsWidget
            pickerRow(
                label: lm.language == .traditionalChinese ? "時間範圍" : "Period",
                options: TimePeriod.allCases,
                selected: $allStatsPeriod,
                display: { periodLabel($0) }
            ) { value in
                AppGroupDefaults.shared.set(value.rawValue, forKey: "widget.allStats.period")
                WidgetCenter.shared.reloadAllTimelines()
            }
        default:
            EmptyView()
        }
    }

    private func infoText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(theme.textMid)
    }

    // MARK: - Picker Row

    private func pickerRow<T: Hashable>(
        label: String,
        options: [T],
        selected: Binding<T>,
        display: @escaping (T) -> String,
        onChange: @escaping (T) -> Void
    ) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(theme.textMid)
            Spacer()
            Menu {
                ForEach(options, id: \.self) { opt in
                    Button(display(opt)) {
                        selected.wrappedValue = opt
                        onChange(opt)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(display(selected.wrappedValue))
                        .font(.system(size: 14))
                        .foregroundColor(theme.text)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(theme.textMid)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(theme.card)
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Add to Home Button

    private var addToHomeButton: some View {
        Button {
            if let url = URL(string: "widgetkit://") {
                UIApplication.shared.open(url) { success in
                    if !success { showAddInstructions = true }
                }
            } else {
                showAddInstructions = true
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle")
                Text(lm.language == .traditionalChinese ? "加入主畫面" : "Add to Home Screen")
                    .font(.system(size: 15))
            }
            .foregroundColor(theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(theme.surface)
            .cornerRadius(10)
        }
    }

    // MARK: - Instructions Sheet

    private var addInstructionsSheet: some View {
        VStack(spacing: 20) {
            Text(lm.language == .traditionalChinese ? "加入主畫面" : "Add to Home Screen")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(theme.text)

            VStack(alignment: .leading, spacing: 12) {
                instructionStep("1", lm.language == .traditionalChinese ? "長按主畫面空白處" : "Long-press an empty area on your Home Screen")
                instructionStep("2", lm.language == .traditionalChinese ? "點右上角「＋」" : "Tap the + button in the top-right corner")
                instructionStep("3", lm.language == .traditionalChinese ? "搜尋「Nikoneko Run」" : "Search for \"Nikoneko Run\"")
                instructionStep("4", lm.language == .traditionalChinese ? "選擇你要的 widget 尺寸" : "Choose your preferred widget size")
            }
            .padding(.horizontal, 24)

            Button(lm.language == .traditionalChinese ? "知道了" : "Got it") {
                showAddInstructions = false
            }
            .foregroundColor(theme.accent)
            .padding(.top, 8)
        }
        .padding(.vertical, 32)
        .presentationDetents([.medium])
        .background(theme.bg.ignoresSafeArea())
    }

    private func instructionStep(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.accent)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(theme.text)
        }
    }

    // MARK: - Label Helpers

    private func metricLabel(_ m: StatMetric) -> String {
        let zh = lm.language == .traditionalChinese
        switch m {
        case .streak:   return zh ? "連勝天數" : "Streak"
        case .duration: return zh ? "時長" : "Duration"
        case .distance: return zh ? "距離" : "Distance"
        case .calories: return zh ? "卡路里" : "Calories"
        case .steps:    return zh ? "步數" : "Steps"
        case .runs:     return zh ? "次數" : "Runs"
        }
    }

    private func periodLabel(_ p: TimePeriod) -> String {
        let zh = lm.language == .traditionalChinese
        switch p {
        case .today: return zh ? "今天" : "Today"
        case .week:  return zh ? "本週" : "This Week"
        case .month: return zh ? "本月" : "This Month"
        case .year:  return zh ? "本年" : "This Year"
        }
    }

    // MARK: - Widget Previews

    @ViewBuilder
    private func widgetPreview(kind: String, widgetTheme: ThemeTokens) -> some View {
        switch kind {
        case "StatWidget":       statPreview(widgetTheme: widgetTheme)
        case "HeatmapWidget":    heatmapPreview(widgetTheme: widgetTheme)
        case "BarChartWidget":   barChartPreview(widgetTheme: widgetTheme)
        case "CalendarWidget":   calendarPreview(widgetTheme: widgetTheme)
        default:                 allStatsPreview(widgetTheme: widgetTheme)
        }
    }

    private func statPreview(widgetTheme: ThemeTokens) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("NIKONEKO RUN")
                    .font(.system(size: 9)).tracking(0.8)
                    .foregroundColor(widgetTheme.textMid)
                Spacer()
                Image(systemName: "flame")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(widgetTheme.textMid)
            }
            Spacer()
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("12")
                    .font(.system(size: 64, weight: .ultraLight))
                    .foregroundColor(widgetTheme.text)
                    .monospacedDigit()
                Text("days")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(widgetTheme.textMid)
            }
            Spacer(minLength: 4)
            Text("Streak")
                .font(.system(size: 11))
                .foregroundColor(widgetTheme.textMid)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(widgetTheme.bg)
    }

    private func heatmapPreview(widgetTheme: ThemeTokens) -> some View {
        GeometryReader { geo in
            let cols = 18, rows = 7
            let gap: CGFloat = 2
            let pad: CGFloat = 12
            let headerH: CGFloat = 22  // header text + spacing
            let availW = geo.size.width - pad * 2
            let availH = geo.size.height - pad * 2 - headerH
            // cell size = fit both width and height
            let cellW = (availW - CGFloat(cols - 1) * gap) / CGFloat(cols)
            let cellH = (availH - CGFloat(rows - 1) * gap) / CGFloat(rows)
            let cell = min(cellW, cellH)

            ZStack(alignment: .topLeading) {
                widgetTheme.bg
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("NIKONEKO RUN")
                            .font(.system(size: 9)).tracking(0.8)
                            .foregroundColor(widgetTheme.textMid)
                        Spacer()
                        Text(String(Calendar.current.component(.year, from: Date())))
                            .font(.system(size: 9)).tracking(0.8)
                            .foregroundColor(widgetTheme.textMid)
                    }
                    VStack(spacing: gap) {
                        ForEach(0..<rows, id: \.self) { row in
                            HStack(spacing: gap) {
                                ForEach(0..<cols, id: \.self) { col in
                                    let i = row * cols + col
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(widgetTheme.bar[previewTier(index: i, total: cols * rows)])
                                        .frame(width: cell, height: cell)
                                }
                            }
                        }
                    }
                }
                .padding(pad)
            }
            .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func barChartPreview(widgetTheme: ThemeTokens) -> some View {
        ZStack(alignment: .topLeading) {
            widgetTheme.bg
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("NIKONEKO RUN")
                        .font(.system(size: 9)).tracking(0.8)
                        .foregroundColor(widgetTheme.textMid)
                    Spacer()
                    Text("JUN 1 – 7")
                        .font(.system(size: 9)).tracking(0.8)
                        .foregroundColor(widgetTheme.textMid)
                }
                let bars: [Double] = [0.4, 0, 0.7, 0.5, 1.0, 0, 0.6]
                GeometryReader { geo in
                    let chartH = geo.size.height
                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(bars.indices, id: \.self) { i in
                            let h = max(CGFloat(bars[i]) * chartH, 3)
                            VStack(spacing: 0) {
                                Spacer(minLength: 0)
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 2, bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 0, topTrailingRadius: 2
                                )
                                .fill(i == 4 ? widgetTheme.bar[4] : (bars[i] > 0 ? widgetTheme.bar[2] : widgetTheme.bar[0]))
                                .frame(maxWidth: .infinity)
                                .frame(height: h)
                            }
                            .frame(height: chartH)
                        }
                    }
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func allStatsPreview(widgetTheme: ThemeTokens) -> some View {
        ZStack(alignment: .topLeading) {
            widgetTheme.bg
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("NIKONEKO RUN")
                        .font(.system(size: 9)).tracking(0.8)
                        .foregroundColor(widgetTheme.textMid)
                    Spacer()
                    Text("THIS WEEK")
                        .font(.system(size: 9)).tracking(0.8)
                        .foregroundColor(widgetTheme.textMid)
                }
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("total")
                        .font(.system(size: 14, weight: .ultraLight))
                        .foregroundColor(widgetTheme.accent)
                    Text("3.5")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundColor(widgetTheme.accent)
                        .monospacedDigit()
                    Text("hrs")
                        .font(.system(size: 16, weight: .ultraLight))
                        .foregroundColor(widgetTheme.accent)
                }
                let stats = [("14.2","km"),("1.4k","kcal"),("21.3k","steps"),("142","avg HR"),("168","max HR"),("5","runs")]
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                    ForEach(Array(stats.enumerated()), id: \.offset) { _, s in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.0)
                                .font(.system(size: 16, weight: .ultraLight))
                                .foregroundColor(widgetTheme.text)
                                .monospacedDigit()
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                            Text(s.1)
                                .font(.system(size: 9))
                                .foregroundColor(widgetTheme.text)
                        }
                        .padding(7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(widgetTheme.card)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(widgetTheme.accentDim, lineWidth: 0.5))
                        .cornerRadius(10)
                    }
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func calendarPreview(widgetTheme: ThemeTokens) -> some View {
        GeometryReader { geo in
            let gap: CGFloat = 3
            let pad: CGFloat = 12
            let headerH: CGFloat = 36  // title row + day headers
            let rows = 5
            let cols = 7
            let availW = geo.size.width - pad * 2
            let availH = geo.size.height - pad * 2 - headerH
            let cellW = (availW - CGFloat(cols - 1) * gap) / CGFloat(cols)
            let cellH = (availH - CGFloat(rows - 1) * gap) / CGFloat(rows)
            let cell = min(cellW, cellH)

            ZStack(alignment: .topLeading) {
                widgetTheme.bg
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("NIKONEKO RUN")
                            .font(.system(size: 9)).tracking(0.8)
                            .foregroundColor(widgetTheme.textMid)
                        Spacer()
                        Text(monthYearString())
                            .font(.system(size: 9)).tracking(0.8)
                            .foregroundColor(widgetTheme.textMid)
                    }
                    HStack(spacing: gap) {
                        ForEach(Array(["M","T","W","T","F","S","S"].enumerated()), id: \.offset) { _, d in
                            Text(d)
                                .font(.system(size: 8))
                                .foregroundColor(widgetTheme.textMid)
                                .frame(width: cell)
                        }
                    }
                    // 5 rows × 7 cols, days 1–30 + empty cells
                    VStack(spacing: gap) {
                        ForEach(0..<rows, id: \.self) { row in
                            HStack(spacing: gap) {
                                ForEach(0..<cols, id: \.self) { col in
                                    let n = row * cols + col + 1
                                    ZStack(alignment: .topLeading) {
                                        if n <= 30 {
                                            let tier = previewTier(index: n, total: 30)
                                            widgetTheme.cal[tier].cornerRadius(5)
                                            Text("\(n)")
                                                .font(.system(size: max(cell * 0.28, 6)))
                                                .foregroundColor(widgetTheme.text.opacity(tier > 0 ? 0.7 : 0.4))
                                                .padding(3)
                                        } else {
                                            widgetTheme.cal[0].cornerRadius(5)
                                        }
                                    }
                                    .frame(width: cell, height: cell)
                                }
                            }
                        }
                    }
                }
                .padding(pad)
            }
            .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func monthYearString() -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }

    private func previewTier(index: Int, total: Int) -> Int {
        let wave = sin(Double(index) / Double(total) * .pi * 4 + 1.0)
        let mapped = (wave + 1.0) / 2.0
        return min(4, Int(mapped * 5))
    }
}

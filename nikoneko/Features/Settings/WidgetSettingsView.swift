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
            .frame(height: galleryFrameHeight)
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
                .aspectRatio(previewAspectRatio(size: w.size), contentMode: .fit)
                .cornerRadius(12)
                .clipped()
        }
        .padding(14)
        .background(theme.surface)
        .cornerRadius(14)
    }

    // Widget actual pt sizes (iPhone 16): Small 158×158, Medium 338×158, Large 338×354
    private func previewAspectRatio(size: String) -> CGFloat {
        switch size {
        case "Medium": return 338.0 / 158.0  // ~2.14:1
        case "Large":  return 338.0 / 354.0  // ~0.955:1
        default:       return 1.0             // Small: 1:1 square
        }
    }

    // Dynamic gallery height based on current widget's aspect ratio
    // card width ≈ screen(375) - outer padding(36) - card padding(28) = 311pt
    private var galleryFrameHeight: CGFloat {
        let cardW: CGFloat = 311
        let size = widgetDefs[selectedIndex].size
        let ratio = previewAspectRatio(size: size)
        let previewH = cardW / ratio
        return previewH + 36 + 28 + 28  // preview + label row + card padding + page dots
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
            showAddInstructions = true
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

    // MARK: Stat (Small) — header top-right icon, big number, unit baseline, label bottom-left
    private func statPreview(widgetTheme: ThemeTokens) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("NIKONEKO RUN")
                    .font(.system(size: 9)).tracking(0.8)
                    .foregroundColor(widgetTheme.textMid)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Image(systemName: "flame")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(widgetTheme.textMid)
            }
            Spacer()
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("12")
                    .font(.system(size: 56, weight: .ultraLight))
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
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(widgetTheme.bg)
    }

    // MARK: Heatmap (Medium) — left day labels + month headers + grid
    private func heatmapPreview(widgetTheme: ThemeTokens) -> some View {
        GeometryReader { geo in
            let dayLabels = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
            let labelW: CGFloat = 26
            let gap: CGFloat = 2
            let pad: CGFloat = 10
            let headerH: CGFloat = 20
            let cols = 18, rows = 7
            let availW = geo.size.width - pad * 2 - labelW - gap
            let availH = geo.size.height - pad * 2 - headerH
            let cellW = (availW - CGFloat(cols - 1) * gap) / CGFloat(cols)
            let cellH = (availH - CGFloat(rows - 1) * gap) / CGFloat(rows)
            let cell = min(cellW, cellH)

            ZStack(alignment: .topLeading) {
                widgetTheme.bg
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Text("NIKONEKO RUN")
                            .font(.system(size: 9)).tracking(0.8)
                            .foregroundColor(widgetTheme.textMid)
                        Spacer()
                        Text(String(Calendar.current.component(.year, from: Date())))
                            .font(.system(size: 9)).tracking(0.8)
                            .foregroundColor(widgetTheme.textMid)
                    }
                    .frame(height: headerH)
                    // Grid with day labels
                    HStack(alignment: .top, spacing: gap) {
                        // Day label column
                        VStack(alignment: .leading, spacing: gap) {
                            ForEach(dayLabels, id: \.self) { d in
                                Text(d)
                                    .font(.system(size: 7))
                                    .foregroundColor(widgetTheme.textMid)
                                    .frame(width: labelW, height: cell, alignment: .leading)
                            }
                        }
                        // Cells
                        VStack(spacing: gap) {
                            ForEach(0..<rows, id: \.self) { row in
                                HStack(spacing: gap) {
                                    ForEach(0..<cols, id: \.self) { col in
                                        let i = row * cols + col
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(widgetTheme.bar[previewTier(index: i, total: cols * rows)])
                                            .frame(width: cell, height: cell)
                                    }
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

    // MARK: Bar Chart (Medium) — Y-axis labels + grid lines + bars + X-axis labels
    private func barChartPreview(widgetTheme: ThemeTokens) -> some View {
        GeometryReader { geo in
            let bars: [Double] = [0.5, 0.02, 0.7, 0.45, 1.0, 0.02, 0.6]
            let xLabels = ["M","T","W","T","F","S","S"]
            let todayIdx = 6
            let yAxisW: CGFloat = 24
            let pad: CGFloat = 10
            let headerH: CGFloat = 20
            let xLabelH: CGFloat = 14
            let chartH = geo.size.height - pad * 2 - headerH - xLabelH

            ZStack(alignment: .topLeading) {
                widgetTheme.bg
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Text("NIKONEKO RUN")
                            .font(.system(size: 9)).tracking(0.8)
                            .foregroundColor(widgetTheme.textMid)
                        Spacer()
                        Text("JUN 1 – 7")
                            .font(.system(size: 9)).tracking(0.8)
                            .foregroundColor(widgetTheme.textMid)
                    }
                    .frame(height: headerH)

                    HStack(alignment: .bottom, spacing: 4) {
                        // Y-axis
                        VStack(alignment: .leading, spacing: 0) {
                            Text("min").font(.system(size: 8)).foregroundColor(widgetTheme.textMid)
                            Spacer()
                            Text("40").font(.system(size: 8)).foregroundColor(widgetTheme.textMid)
                            Spacer()
                            Text("20").font(.system(size: 8)).foregroundColor(widgetTheme.textMid)
                            Spacer()
                            Text("0").font(.system(size: 8)).foregroundColor(widgetTheme.textMid)
                        }
                        .frame(width: yAxisW, height: chartH + xLabelH)
                        .padding(.bottom, xLabelH)

                        VStack(spacing: 0) {
                            // Chart area
                            ZStack(alignment: .bottom) {
                                // Grid lines
                                VStack(spacing: 0) {
                                    Rectangle().fill(widgetTheme.textMid.opacity(0.15)).frame(height: 0.5)
                                    Spacer()
                                    Rectangle().fill(widgetTheme.textMid.opacity(0.15)).frame(height: 0.5)
                                    Spacer()
                                    Rectangle().fill(widgetTheme.textMid.opacity(0.3)).frame(height: 0.5)
                                }
                                // Bars
                                HStack(alignment: .bottom, spacing: 0) {
                                    ForEach(bars.indices, id: \.self) { i in
                                        let h = max(CGFloat(bars[i]) * chartH, 3)
                                        VStack(spacing: 0) {
                                            Spacer(minLength: 0)
                                            UnevenRoundedRectangle(
                                                topLeadingRadius: 2, bottomLeadingRadius: 0,
                                                bottomTrailingRadius: 0, topTrailingRadius: 2
                                            )
                                            .fill(i == todayIdx ? widgetTheme.bar[4] : (bars[i] > 0.05 ? widgetTheme.bar[2] : widgetTheme.bar[0]))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: h)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: chartH)
                                    }
                                }
                            }
                            .frame(height: chartH)
                            // X-axis labels
                            HStack(spacing: 0) {
                                ForEach(xLabels.indices, id: \.self) { i in
                                    Text(xLabels[i])
                                        .font(.system(size: 9))
                                        .foregroundColor(widgetTheme.textMid)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .frame(height: xLabelH)
                        }
                    }
                }
                .padding(pad)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: AllStats (Large) — header + hero duration + 3×2 summary card grid
    private func allStatsPreview(widgetTheme: ThemeTokens) -> some View {
        let cards: [(value: String, unit: String, icon: String, label: String)] = [
            ("2.8", "km",   "location.circle",  "Distance"),
            ("168", "kcal", "flame",             "Calories"),
            ("3.2k","",     "shoeprints.fill",   "Steps"),
            ("—",   "",     "heart",             "Avg HR"),
            ("—",   "",     "heart",             "Max HR"),
            ("1",   "runs", "figure.run",        "Runs"),
        ]
        return VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("NIKONEKO RUN")
                    .font(.system(size: 9)).tracking(0.8)
                    .foregroundColor(widgetTheme.textMid)
                Spacer()
                Text("June 8")
                    .font(.system(size: 9)).tracking(0.8)
                    .foregroundColor(widgetTheme.textMid)
            }
            .padding(.bottom, 4)

            // Hero
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("total")
                    .font(.system(size: 13, weight: .ultraLight))
                    .foregroundColor(widgetTheme.accent)
                Text("24")
                    .font(.system(size: 52, weight: .ultraLight))
                    .foregroundColor(widgetTheme.accent)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("min")
                    .font(.system(size: 16, weight: .ultraLight))
                    .foregroundColor(widgetTheme.accent)
            }
            .padding(.bottom, 8)

            // 3×2 grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 3), spacing: 5) {
                ForEach(cards, id: \.label) { c in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .lastTextBaseline, spacing: 3) {
                            Text(c.value)
                                .font(.system(size: 18, weight: .ultraLight))
                                .foregroundColor(widgetTheme.text)
                                .monospacedDigit()
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            if !c.unit.isEmpty {
                                Text(c.unit)
                                    .font(.system(size: 10))
                                    .foregroundColor(widgetTheme.text)
                            }
                        }
                        HStack(spacing: 3) {
                            Image(systemName: c.icon)
                                .font(.system(size: 9))
                                .foregroundColor(widgetTheme.text)
                            Text(c.label)
                                .font(.system(size: 9))
                                .foregroundColor(widgetTheme.text)
                        }
                    }
                    .padding(7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(widgetTheme.card)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(widgetTheme.accentDim, lineWidth: 0.5))
                    .cornerRadius(10)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(widgetTheme.bg)
    }

    // MARK: Calendar (Large) — header + M/T/W/T/F/S/S + date grid + bottom stats row
    private func calendarPreview(widgetTheme: ThemeTokens) -> some View {
        GeometryReader { geo in
            let gap: CGFloat = 4
            let pad: CGFloat = 12
            // 月份從當前日期算
            let cal = Calendar.current
            let now = Date()
            let year = cal.component(.year, from: now)
            let month = cal.component(.month, from: now)
            let daysInMonth = cal.range(of: .day, in: .month, for: now)!.count
            let firstWeekday = cal.component(.weekday, from: cal.date(from: DateComponents(year: year, month: month, day: 1))!)
            let firstOffset = (firstWeekday + 5) % 7  // Mon=0

            let bottomH: CGFloat = 44
            let headerH: CGFloat = 20
            let dayHeaderH: CGFloat = 16
            let availH = geo.size.height - pad * 2 - headerH - dayHeaderH - bottomH - gap * 2
            let rows = 5
            let cols = 7
            let availW = geo.size.width - pad * 2
            let cellW = (availW - CGFloat(cols - 1) * gap) / CGFloat(cols)
            let cellH = (availH - CGFloat(rows - 1) * gap) / CGFloat(rows)
            let cell = min(cellW, cellH)

            ZStack(alignment: .topLeading) {
                widgetTheme.bg
                VStack(alignment: .leading, spacing: 0) {
                    // Title row
                    HStack {
                        Text("NIKONEKO RUN")
                            .font(.system(size: 9)).tracking(0.8)
                            .foregroundColor(widgetTheme.textMid)
                        Spacer()
                        Text(monthYearString())
                            .font(.system(size: 9)).tracking(0.8)
                            .foregroundColor(widgetTheme.textMid)
                    }
                    .frame(height: headerH)

                    // Day headers M T W T F S S
                    HStack(spacing: gap) {
                        ForEach(Array(["M","T","W","T","F","S","S"].enumerated()), id: \.offset) { _, d in
                            Text(d)
                                .font(.system(size: 9))
                                .foregroundColor(widgetTheme.textMid)
                                .frame(width: cell, height: dayHeaderH)
                        }
                    }

                    // Calendar cells
                    let totalCells = rows * cols
                    VStack(spacing: gap) {
                        ForEach(0..<rows, id: \.self) { row in
                            HStack(spacing: gap) {
                                ForEach(0..<cols, id: \.self) { col in
                                    let cellIdx = row * cols + col
                                    let day = cellIdx - firstOffset + 1
                                    ZStack(alignment: .topLeading) {
                                        if day >= 1 && day <= daysInMonth {
                                            let tier = previewTier(index: day, total: daysInMonth)
                                            widgetTheme.cal[tier]
                                                .cornerRadius(6)
                                            Text("\(day)")
                                                .font(.system(size: max(cell * 0.26, 7)))
                                                .foregroundColor(widgetTheme.text.opacity(tier > 0 ? 0.7 : 0.35))
                                                .padding(3)
                                        } else {
                                            widgetTheme.cal[0].cornerRadius(6).opacity(0)
                                        }
                                    }
                                    .frame(width: cell, height: cell)
                                }
                            }
                        }
                    }
                    .padding(.bottom, gap)

                    // Bottom stats row
                    HStack(alignment: .top, spacing: 0) {
                        bottomStatCell(icon: "timer", label: "TODAY", value: "18", unit: "min", t: widgetTheme, align: .leading)
                        bottomStatCell(icon: "calendar", label: "MONTH", value: "2", unit: "hr", t: widgetTheme, align: .center)
                        bottomStatCell(icon: "flame", label: "STREAK", value: "3", unit: "days", t: widgetTheme, align: .trailing)
                    }
                    .frame(height: bottomH)
                }
                .padding(pad)
            }
            .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func bottomStatCell(icon: String, label: String, value: String, unit: String, t: ThemeTokens, align: HorizontalAlignment) -> some View {
        let frameAlign: Alignment = align == .leading ? .leading : align == .trailing ? .trailing : .center
        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 8, weight: .light)).foregroundColor(t.textMid)
                Text(label).font(.system(size: 8)).tracking(0.6).foregroundColor(t.textMid)
            }
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.system(size: 20, weight: .ultraLight)).foregroundColor(t.text).monospacedDigit()
                Text(unit).font(.system(size: 8, weight: .light)).foregroundColor(t.textMid)
            }
        }
        .frame(maxWidth: .infinity, alignment: frameAlign)
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

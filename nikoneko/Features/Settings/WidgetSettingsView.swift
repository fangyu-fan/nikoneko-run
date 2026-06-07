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
            if w.size == "Small" {
                // Small widget: fixed 50% of native size (79×79), centred
                widgetPreview(kind: w.kind, widgetTheme: theme)
                    .frame(width: 79, height: 79)
                    .cornerRadius(12)
                    .clipped()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                widgetPreview(kind: w.kind, widgetTheme: theme)
                    .aspectRatio(w.size == "Medium" ? 338.0/158.0 : 338.0/354.0, contentMode: .fit)
                    .cornerRadius(12)
                    .clipped()
            }
        }
        .padding(14)
        .background(theme.surface)
        .cornerRadius(14)
    }

    // Gallery height is fixed so it doesn't jump when swiping between widget sizes.
    // Sized for Medium widgets (widest cards) + label row + card padding + page dots.
    // card width ≈ 375 - 36 (outer) - 28 (card padding) = 311pt
    // Medium preview height = 311 / (338/158) ≈ 145pt
    private var galleryFrameHeight: CGFloat { 145 + 36 + 28 + 28 }

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
    // Uses actual widget views scaled down to match preview frame size.
    // Widget native sizes (iPhone 16): Small 158×158, Medium 338×158, Large 338×354

    private static let nativeSize: [String: CGSize] = [
        "StatWidget":     CGSize(width: 158, height: 158),
        "HeatmapWidget":  CGSize(width: 338, height: 158),
        "BarChartWidget": CGSize(width: 338, height: 158),
        "CalendarWidget": CGSize(width: 338, height: 354),
        "AllStatsWidget": CGSize(width: 338, height: 354),
    ]

    @ViewBuilder
    private func widgetPreview(kind: String, widgetTheme: ThemeTokens) -> some View {
        let native = Self.nativeSize[kind] ?? CGSize(width: 158, height: 158)
        GeometryReader { geo in
            let scale = geo.size.width / native.width
            Group {
                switch kind {
                case "StatWidget":
                    StatWidgetView(entry: StatEntry(
                        date: .now, metric: .streak, period: .week,
                        formattedValue: "12", unit: "days",
                        metricLabel: "Streak", periodLabel: nil,
                        fontSize: 80, theme: widgetTheme
                    ))
                case "HeatmapWidget":
                    HeatmapWidgetView(entry: HeatmapEntry(
                        date: .now, summaries: previewSummaries,
                        metric: .duration, theme: widgetTheme
                    ))
                case "BarChartWidget":
                    BarChartWidgetView(entry: BarChartEntry(
                        date: .now,
                        bars: [23, 2, 35, 21, 46, 2, 28],
                        todayIndex: 6, maxValue: 46,
                        yTop: "46", yMid: "23",
                        weekLabel: "JUN 1 – 7",
                        metric: .duration, theme: widgetTheme
                    ))
                case "CalendarWidget":
                    CalendarWidgetView(entry: CalendarEntry(
                        date: .now, summaries: previewSummaries,
                        metric: .duration, theme: widgetTheme
                    ))
                default: // AllStatsWidget
                    AllStatsWidgetView(entry: AllStatsEntry(
                        date: .now, period: .week,
                        durationFormatted: "24", durationUnit: "min",
                        distanceKm: "2.8", caloriesStr: "168",
                        stepsStr: "3.2k", avgHR: "—", maxHR: "—",
                        runsStr: "1", theme: widgetTheme
                    ))
                }
            }
            .frame(width: native.width, height: native.height)
            .background(widgetTheme.bg)  // containerBackground doesn't apply outside WidgetKit
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .clipped()
        }
    }

    // Sample summaries for heatmap/calendar previews
    private var previewSummaries: [DaySessionSummary] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<30).compactMap { d -> DaySessionSummary? in
            guard d % 2 == 0 || d % 3 == 0 else { return nil }
            let date = cal.date(byAdding: .day, value: -d, to: today)!
            return DaySessionSummary(
                date: date,
                duration: Double.random(in: 600...2400),
                completionRatio: 1.0,
                hrAvg: Int.random(in: 120...160),
                steps: Int.random(in: 2000...7000)
            )
        }
    }

}

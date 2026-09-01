import SwiftUI
import WidgetKit

struct WidgetSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var theme: ThemeTokens { themeManager.current }

    @State private var selectedIndex: Int = 0

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
            // Gallery — fixed height = Large widget full size, all previews centred vertically
            TabView(selection: $selectedIndex) {
                ForEach(widgetDefs.indices, id: \.self) { i in
                    galleryCard(widgetDefs[i])
                        .tag(i)
                        .padding(.horizontal, 18)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: galleryFrameHeight)
            .animation(nil, value: selectedIndex)
            .tint(theme.accent)

            // Page indicator below the cards
            HStack(spacing: 6) {
                ForEach(widgetDefs.indices, id: \.self) { i in
                    Circle()
                        .fill(i == selectedIndex ? theme.accent : theme.textDim.opacity(0.4))
                        .frame(width: i == selectedIndex ? 7 : 5, height: i == selectedIndex ? 7 : 5)
                        .animation(.easeInOut(duration: 0.2), value: selectedIndex)
                }
            }
            .padding(.vertical, 8)

            Divider()
                .padding(.top, 8)

            // Settings area — scrollable middle section
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    parameterSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }

            // Add to Home pinned at bottom
            VStack(spacing: 0) {
                Divider()
                addToHomeButton
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .padding(.bottom, 4)
            }
            .background(theme.bg)
        }
        .frame(maxWidth: contentMaxWidth)
        .frame(maxWidth: .infinity)
        .background(theme.bg.ignoresSafeArea())
        .id(lm.version)
        .navigationTitle(lm.L("widget.title"))
        .navigationBarTitleDisplayMode(.inline)
        .themedNavigationBar(theme)
        .sheet(isPresented: $showAddInstructions) {
            addInstructionsSheet
        }
    }

    // MARK: - Gallery Card

    private func galleryCard(_ w: (name: String, nameZh: String, size: String, kind: String)) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title row — name + size badge on the same line
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(lm.language == .traditionalChinese ? w.nameZh : w.name)
                    .font(.system(size: 30, weight: .regular))
                    .foregroundColor(theme.text)
                Text(w.size)
                    .font(.system(size: 11))
                    .foregroundColor(theme.textMid)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(theme.accentDim.opacity(0.5))
                    .cornerRadius(6)
            }

            GeometryReader { geo in
                let previewSize = fittedPreviewSize(for: w.kind, available: geo.size)
                widgetPreview(kind: w.kind, widgetTheme: theme)
                    .frame(width: previewSize.width, height: previewSize.height)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .padding(14)
        .frame(maxHeight: .infinity)
        .background(theme.surface)
        .cornerRadius(14)
    }

    private var isRegularWidth: Bool { horizontalSizeClass == .regular }
    private var contentMaxWidth: CGFloat { isRegularWidth ? 560 : 430 }
    private var galleryFrameHeight: CGFloat { isRegularWidth ? 580 : 417 }

    private func fittedPreviewSize(for kind: String, available: CGSize) -> CGSize {
        let native = Self.nativeSize[kind] ?? CGSize(width: 158, height: 158)
        let maximumWidth: CGFloat
        if isRegularWidth {
            maximumWidth = kind == "StatWidget" ? 240 : (native.height > native.width ? 460 : 500)
        } else {
            maximumWidth = native.width
        }
        let scale = min(
            maximumWidth / native.width,
            available.width / native.width,
            available.height / native.height
        )
        return CGSize(width: native.width * scale, height: native.height * scale)
    }

    // MARK: - Parameter Section

    @ViewBuilder
    private var parameterSection: some View {
        switch selectedIndex {
        case 0: // StatWidget
            infoText(lm.language == .traditionalChinese
                ? "加入小工具後，長按小工具並選擇「編輯小工具」來更換指標與時間範圍"
                : "After adding the widget, long-press it and choose Edit Widget to change its metric and period")
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
        let zh = lm.language == .traditionalChinese
        let steps: [(icon: String, title: String, body: String)] = zh ? [
            ("hand.tap",          "長按主畫面",     "長按主畫面空白處，等待 app 圖示開始晃動"),
            ("plus.circle",       "點擊「＋」",     "點擊右上角的加號按鈕"),
            ("magnifyingglass",   "搜尋 Nikoneko", "在搜尋欄輸入「Nikoneko Run」"),
            ("rectangle.3.group", "選擇尺寸",       "選取你想要的 widget 並點擊「加入 Widget」"),
        ] : [
            ("hand.tap",          "Long-press",       "Long-press an empty area until icons start jiggling"),
            ("plus.circle",       "Tap +",            "Tap the + button in the top-right corner"),
            ("magnifyingglass",   "Search",           "Type \"Nikoneko Run\" in the search bar"),
            ("rectangle.3.group", "Choose size",      "Select your widget size and tap Add Widget"),
        ]
        return VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(theme.textDim.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            Text(zh ? "加入主畫面" : "Add to Home Screen")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(theme.text)
                .padding(.bottom, 24)

            ScrollView {
                VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                    HStack(alignment: .top, spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(theme.accentDim)
                                .frame(width: 40, height: 40)
                            Image(systemName: step.icon)
                                .font(.system(size: 17, weight: .light))
                                .foregroundColor(theme.accent)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(theme.text)
                            Text(step.body)
                                .font(.system(size: 13))
                                .foregroundColor(theme.textMid)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)

                    if idx < steps.count - 1 {
                        Rectangle()
                            .fill(theme.accentDim.opacity(0.5))
                            .frame(height: 0.5)
                            .padding(.leading, 80)
                    }
                }
                }
                .background(theme.surface)
                .cornerRadius(14)
                .padding(.horizontal, 18)
            }
            .scrollBounceBehavior(.basedOnSize)

            Button {
                showAddInstructions = false
            } label: {
                Text(zh ? "知道了" : "Got it")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(theme.surface)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 8)

        }
        .background(theme.bg.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
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
                    StatWidgetView(entry: statPreviewEntry(theme: widgetTheme))
                case "HeatmapWidget":
                    HeatmapWidgetView(entry: HeatmapEntry(
                        date: .now, summaries: previewSummaries,
                        metric: .duration, theme: widgetTheme,
                        reportSettings: .defaults
                    ))
                case "BarChartWidget":
                    BarChartWidgetView(entry: BarChartEntry(
                        date: .now,
                        bars: [23, 2, 35, 21, 46, 2, 28],
                        completionRatios: [0.5, 0.05, 0.8, 0.45, 1.0, 0.1, 0.65],
                        todayIndex: 6, maxValue: 46,
                        yTop: "46", yMid: "23",
                        weekLabel: "JUN 1 – 7",
                        metric: .duration, theme: widgetTheme,
                        reportSettings: .defaults
                    ))
                case "CalendarWidget":
                    CalendarWidgetView(entry: CalendarEntry(
                        date: .now, summaries: previewSummaries,
                        metric: calendarMetric, theme: widgetTheme,
                        reportSettings: .defaults
                    ))
                default: // AllStatsWidget
                    AllStatsWidgetView(entry: allStatsPreviewEntry(theme: widgetTheme))
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

    // StatWidget preview entry. Each installed small widget is configured via Edit Widget.
    private func statPreviewEntry(theme: ThemeTokens) -> StatEntry {
        return StatEntry(
            date: .now, metric: .steps, period: .year,
            formattedValue: "6083", unit: "steps",
            metricLabel: "Steps", periodLabel: "per year",
            fontSize: 42, theme: theme
        )
    }

    // AllStats preview entry — reflects current period selection
    private func allStatsPreviewEntry(theme: ThemeTokens) -> AllStatsEntry {
        AllStatsEntry(
            date: .now, period: allStatsPeriod,
            durationFormatted: "3.5", durationUnit: "hrs",
            distanceKm: "14.2", caloriesStr: "1.4k",
            stepsStr: "21.3k", avgHR: "142", maxHR: "168",
            runsStr: "5", theme: theme
        )
    }

}

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Intent

struct BarChartWidgetIntent: AppIntent, WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Bar Chart"
    static let description = IntentDescription("Weekly training chart.")

    @Parameter(title: "Metric", default: .duration) var metric: StatMetric
}

// MARK: - Entry

struct BarChartEntry: TimelineEntry {
    let date: Date
    let bars: [Double]      // 7 values Mon–Sun, 0 = no data
    let todayIndex: Int     // which bar is today (0=Mon, 6=Sun)
    let maxValue: Double
    let yTop: String        // formatted top y-label
    let yMid: String        // formatted mid y-label
    let metric: StatMetric
    let theme: ThemeTokens
}

// MARK: - Provider

struct BarChartProvider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> BarChartEntry {
        makePlaceholder()
    }

    func snapshot(for configuration: BarChartWidgetIntent, in context: Context) async -> BarChartEntry {
        build(metric: configuration.metric)
    }

    func timeline(for configuration: BarChartWidgetIntent, in context: Context) async -> Timeline<BarChartEntry> {
        let entry = build(metric: configuration.metric)
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        return Timeline(entries: [entry], policy: .after(next))
    }

    // MARK: Private helpers

    private func makePlaceholder() -> BarChartEntry {
        BarChartEntry(
            date: Date(),
            bars: [12, 0, 25, 18, 30, 0, 20],
            todayIndex: 6,
            maxValue: 30,
            yTop: "30",
            yMid: "15",
            metric: .duration,
            theme: ThemeLibrary.obsidian
        )
    }

    private func build(metric: StatMetric) -> BarChartEntry {
        let theme = WidgetTheme.load(for: "widget.barChart.themeId")
        let summaries = AppGroupDefaults.loadSummaries()

        let cal = Calendar.current
        let today = Date()

        // Determine the Mon–Sun week containing today
        // isoWeekday: Mon=2, Sun=1 in Gregorian. Map to Mon=0, Sun=6.
        let weekdayComponent = cal.component(.weekday, from: today)
        // weekday: Sun=1, Mon=2 … Sat=7 → ISO Mon=0 … Sun=6
        let todayIndex = weekdayComponent == 1 ? 6 : weekdayComponent - 2

        // Build the 7 daily values Mon–Sun
        var dailyValues: [Double] = Array(repeating: 0, count: 7)

        // Find Monday of this week
        let daysFromMonday = todayIndex  // todayIndex == days since Mon
        guard let monday = cal.date(byAdding: .day, value: -daysFromMonday, to: cal.startOfDay(for: today)) else {
            return BarChartEntry(date: today, bars: dailyValues, todayIndex: todayIndex,
                                 maxValue: 1, yTop: "1", yMid: "0", metric: metric, theme: theme)
        }

        for dayOffset in 0..<7 {
            guard let dayStart = cal.date(byAdding: .day, value: dayOffset, to: monday) else { continue }
            let daySessions = summaries.filter { cal.isDate($0.date, inSameDayAs: dayStart) }
            dailyValues[dayOffset] = metricValue(for: metric, sessions: daySessions)
        }

        let maxValue = max(dailyValues.max() ?? 0, 1)
        let yTop = formattedLabel(value: maxValue, metric: metric)
        let yMid = formattedLabel(value: maxValue / 2, metric: metric)

        return BarChartEntry(
            date: today,
            bars: dailyValues,
            todayIndex: todayIndex,
            maxValue: maxValue,
            yTop: yTop,
            yMid: yMid,
            metric: metric,
            theme: theme
        )
    }

    private func metricValue(for metric: StatMetric, sessions: [DaySessionSummary]) -> Double {
        switch metric {
        case .duration:
            return sessions.reduce(0) { $0 + $1.duration } / 60.0  // minutes
        case .distance:
            return Double(sessions.reduce(0) { $0 + $1.steps }) / 1500.0  // km estimate
        case .calories:
            return sessions.reduce(0) { $0 + $1.duration } / 60.0 * 7.0  // kcal
        case .steps:
            return Double(sessions.reduce(0) { $0 + $1.steps })
        case .runs:
            return Double(sessions.count)
        case .streak:
            // Streak doesn't map to a daily value; return 0 gracefully
            return 0
        }
    }

    private func formattedLabel(value: Double, metric: StatMetric) -> String {
        switch metric {
        case .duration, .calories, .runs:
            return "\(Int(value.rounded()))"
        case .steps:
            return value >= 1000 ? String(format: "%.0fk", value / 1000) : "\(Int(value.rounded()))"
        case .distance:
            return value >= 10 ? "\(Int(value.rounded()))" : String(format: "%.1f", value)
        case .streak:
            return "0"
        }
    }
}

// MARK: - View

struct BarChartWidgetView: View {
    let entry: BarChartEntry

    private let xLabels = ["M", "T", "W", "T", "F", "S", "S"]
    private let yAxisWidth: CGFloat = 22

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header label
            Text("CHART · \(entry.metric.rawValue.uppercased())")
                .font(.system(size: 9))
                .tracking(0.5)
                .foregroundColor(entry.theme.textMid)

            // Chart area
            HStack(alignment: .bottom, spacing: 6) {
                // Y-axis labels
                VStack(alignment: .trailing, spacing: 0) {
                    Text(entry.yTop)
                    Spacer()
                    Text(entry.yMid)
                    Spacer()
                    Text("0")
                }
                .font(.system(size: 7))
                .foregroundColor(entry.theme.textMid)
                .frame(width: yAxisWidth)
                .padding(.bottom, 14)  // baseline + x-label row height

                // Chart body: bars + baseline + x-labels
                VStack(spacing: 0) {
                    // Bars area with grid lines
                    ZStack(alignment: .bottom) {
                        // Grid lines at 100% and 50%
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(entry.theme.textDim.opacity(0.15))
                                .frame(height: 0.5)
                            Spacer()
                            Rectangle()
                                .fill(entry.theme.textDim.opacity(0.15))
                                .frame(height: 0.5)
                            Spacer()
                        }

                        // Bar columns
                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(0..<7, id: \.self) { index in
                                barView(index: index)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }

                    // Baseline
                    Rectangle()
                        .fill(entry.theme.textDim.opacity(0.3))
                        .frame(height: 1)

                    // X-axis labels
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { index in
                            Text(xLabels[index])
                                .font(.system(size: 7))
                                .foregroundColor(entry.theme.textMid)
                                .frame(maxWidth: .infinity)
                        }
                        // Spacer matching y-axis width so x-labels align under bars
                        Color.clear.frame(width: 0)
                    }
                    .frame(height: 11)
                }
            }
        }
        .padding(13)
        .background(entry.theme.bg)
        .containerBackground(entry.theme.bg, for: .widget)
    }

    @ViewBuilder
    private func barView(index: Int) -> some View {
        let value = entry.bars[index]
        let isToday = index == entry.todayIndex

        GeometryReader { geo in
            let maxH = geo.size.height
            let barH: CGFloat = {
                if value <= 0 { return 2 }
                let proportional = CGFloat(value / entry.maxValue) * maxH
                return max(proportional, 2)
            }()

            let barColor: Color = {
                if value <= 0 { return entry.theme.bar[0] }
                if isToday { return entry.theme.bar[4] }
                return entry.theme.bar[2]
            }()

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                UnevenRoundedRectangle(
                    topLeadingRadius: 2,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 2
                )
                .fill(barColor)
                .frame(width: 4, height: barH)
            }
        }
    }
}

// MARK: - Widget

struct BarChartWidget: Widget {
    let kind = "BarChartWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: BarChartWidgetIntent.self, provider: BarChartProvider()) { entry in
            BarChartWidgetView(entry: entry)
        }
        .configurationDisplayName("Bar Chart")
        .description("Weekly training chart.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Preview

#if DEBUG
#Preview(as: .systemMedium) {
    BarChartWidget()
} timeline: {
    BarChartEntry(
        date: Date(),
        bars: [20, 0, 35, 18, 40, 0, 25],
        todayIndex: 6,
        maxValue: 40,
        yTop: "40",
        yMid: "20",
        metric: .duration,
        theme: ThemeLibrary.obsidian
    )
}
#endif

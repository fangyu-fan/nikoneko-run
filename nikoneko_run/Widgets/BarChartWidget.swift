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
    let weekLabel: String   // e.g. "6/1 – 6/7"
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
            weekLabel: weekLabel(from: Date()),
            metric: .duration,
            theme: ThemeLibrary.moss
        )
    }

    private func build(metric: StatMetric) -> BarChartEntry {
        let theme = WidgetSharedData.loadTheme()
        let summaries = AppGroupDefaults.loadSummaries()

        let cal = Calendar.current
        let today = Date()

        let todayIndex = AppGroupDefaults.weekdayOffset(for: today)

        var dailyValues: [Double] = Array(repeating: 0, count: 7)

        let daysFromStart = todayIndex
        guard let monday = cal.date(byAdding: .day, value: -daysFromStart, to: cal.startOfDay(for: today)) else {
            return BarChartEntry(date: today, bars: dailyValues, todayIndex: todayIndex,
                                 maxValue: 1, yTop: "1", yMid: "0", weekLabel: "", metric: metric, theme: theme)
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
            weekLabel: weekLabel(from: monday),
            metric: metric,
            theme: theme
        )
    }

    private func weekLabel(from monday: Date) -> String {
        let cal = Calendar.current
        guard let sunday = cal.date(byAdding: .day, value: 6, to: monday) else { return "" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        let mMonth = cal.component(.month, from: monday)
        let sMonth = cal.component(.month, from: sunday)
        if mMonth == sMonth {
            let dayF = DateFormatter()
            dayF.dateFormat = "d"
            return "\(f.string(from: monday).uppercased()) – \(dayF.string(from: sunday))"
        } else {
            return "\(f.string(from: monday).uppercased()) – \(f.string(from: sunday).uppercased())"
        }
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

    private var xLabels: [String] {
        AppGroupDefaults.weekStartsOnMonday
            ? ["M","T","W","T","F","S","S"]
            : ["S","M","T","W","T","F","S"]
    }
    private let yAxisWidth: CGFloat = 26

    private var metricUnit: String {
        switch entry.metric {
        case .duration:  return "min"
        case .distance:  return "km"
        case .calories:  return "kcal"
        case .steps:     return "steps"
        case .runs:      return "runs"
        case .streak:    return ""
        }
    }

    private let barWidth: CGFloat = 6
    private let chartHeight: CGFloat = 96

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("NIKONEKO RUN")
                    .font(.system(size: 10)).tracking(0.8)
                    .foregroundColor(entry.theme.textMid)
                Spacer()
                Text(entry.weekLabel)
                    .font(.system(size: 10)).tracking(0.8)
                    .foregroundColor(entry.theme.textMid)
            }
            .padding(.bottom, 6)

            // Chart area
            HStack(alignment: .bottom, spacing: 6) {
                // Y-axis
                VStack(alignment: .leading, spacing: 0) {
                    Text(metricUnit)
                        .font(.system(size: 10))
                        .foregroundColor(entry.theme.textMid)
                        .padding(.bottom, 2)
                    Text(entry.yTop)
                        .font(.system(size: 10))
                        .foregroundColor(entry.theme.textMid)
                    Spacer()
                    Text(entry.yMid)
                        .font(.system(size: 10))
                        .foregroundColor(entry.theme.textMid)
                    Spacer()
                    Text("0")
                        .font(.system(size: 10))
                        .foregroundColor(entry.theme.textMid)
                }
                .padding(.bottom, 13)

                // Chart body
                VStack(spacing: 0) {
                    // Bars + grid
                    ZStack(alignment: .bottom) {
                        VStack(spacing: 0) {
                            Spacer()
                            Rectangle()
                                .fill(entry.theme.textMid.opacity(0.2))
                                .frame(height: 0.5)
                            Spacer()
                            Rectangle()
                                .fill(entry.theme.textMid.opacity(0.2))
                                .frame(height: 0.5)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(0..<7, id: \.self) { index in
                                barView(index: index)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .frame(height: chartHeight)

                    // Baseline
                    Rectangle()
                        .fill(entry.theme.textMid.opacity(0.4))
                        .frame(height: 0.5)

                    // X-axis day labels
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { index in
                            Text(xLabels[index])
                                .font(.system(size: 10))
                                .foregroundColor(entry.theme.textMid)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 12)

                }
            }
        }
        .padding(14)
        .containerBackground(entry.theme.bg, for: .widget)
    }

    @ViewBuilder
    private func barView(index: Int) -> some View {
        let value = entry.bars[index]
        let isToday = index == entry.todayIndex
        let barH: CGFloat = {
            if value <= 0 { return 2 }
            return max(CGFloat(value / entry.maxValue) * chartHeight, 2)
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
            .frame(width: barWidth, height: barH)
        }
        .frame(height: chartHeight)
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
        weekLabel: "Jun 1 – 7",
        metric: .duration,
        theme: ThemeLibrary.moss
    )
}
#endif

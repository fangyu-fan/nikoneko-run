import WidgetKit
import SwiftUI
import AppIntents

// MARK: - StatEntry

struct StatEntry: TimelineEntry {
    let date: Date
    let metric: StatMetric
    let period: TimePeriod
    let formattedValue: String  // e.g. "3.5", "23.6k", "12"
    let unit: String            // "hrs", "min", "steps", "days", "km", "cal", "runs"
    let metricLabel: String     // "Streak", "Duration", etc.
    let periodLabel: String?    // "per week", "today", nil for streak
    let fontSize: CGFloat       // 72, 66, or 54 based on char count
    let theme: ThemeTokens
}

// MARK: - StatProvider

struct StatProvider: AppIntentTimelineProvider {
    typealias Entry = StatEntry
    typealias Intent = StatWidgetIntent

    func placeholder(in context: Context) -> StatEntry {
        makeEntry(metric: .streak, period: .week, theme: ThemeLibrary.moss)
    }

    func snapshot(for configuration: StatWidgetIntent, in context: Context) async -> StatEntry {
        let theme = WidgetSharedData.loadTheme()
        let metric = AppGroupDefaults.shared.string(forKey: "widget.stat.metric")
            .flatMap { StatMetric(rawValue: $0) } ?? configuration.metric
        let period = AppGroupDefaults.shared.string(forKey: "widget.stat.period")
            .flatMap { TimePeriod(rawValue: $0) } ?? configuration.period
        return makeEntry(metric: metric, period: period, theme: theme)
    }

    func timeline(for configuration: StatWidgetIntent, in context: Context) async -> Timeline<StatEntry> {
        let theme = WidgetSharedData.loadTheme()
        let metric = AppGroupDefaults.shared.string(forKey: "widget.stat.metric")
            .flatMap { StatMetric(rawValue: $0) } ?? configuration.metric
        let period = AppGroupDefaults.shared.string(forKey: "widget.stat.period")
            .flatMap { TimePeriod(rawValue: $0) } ?? configuration.period
        let entry = makeEntry(metric: metric, period: period, theme: theme)
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    // MARK: Data computation

    private func makeEntry(metric: StatMetric, period: TimePeriod, theme: ThemeTokens) -> StatEntry {
        let summaries = AppGroupDefaults.loadSummaries()
        let filtered = summaries.filter { inPeriod($0.date, period: period) }

        let (formattedValue, unit) = compute(metric: metric, period: period, summaries: summaries, filtered: filtered)
        let (metricLabel, periodLabel) = makeLabels(metric: metric, period: period)
        let fontSize = fontSizeFor(formattedValue)

        return StatEntry(
            date: Date(),
            metric: metric,
            period: period,
            formattedValue: formattedValue,
            unit: unit,
            metricLabel: metricLabel,
            periodLabel: periodLabel,
            fontSize: fontSize,
            theme: theme
        )
    }

    private func inPeriod(_ date: Date, period: TimePeriod) -> Bool {
        let cal = Calendar.current
        switch period {
        case .today:
            return cal.isDateInToday(date)
        case .week:
            let sevenDaysAgo = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: Date()))!
            return date >= sevenDaysAgo
        case .month:
            let comps = cal.dateComponents([.year, .month], from: Date())
            guard let monthStart = cal.date(from: comps) else { return false }
            return date >= monthStart
        case .year:
            let comps = cal.dateComponents([.year], from: Date())
            guard let yearStart = cal.date(from: comps) else { return false }
            return date >= yearStart
        }
    }

    private func compute(
        metric: StatMetric,
        period: TimePeriod,
        summaries: [DaySessionSummary],
        filtered: [DaySessionSummary]
    ) -> (formattedValue: String, unit: String) {
        switch metric {
        case .streak:
            let goal = max(AppGroupDefaults.shared.integer(forKey: "dailyGoalMinutes"), 1)
            let streak = AppGroupDefaults.currentStreak(from: summaries, goalMinutes: goal)
            return ("\(streak)", "days")

        case .duration:
            let totalSeconds = filtered.reduce(0.0) { $0 + $1.duration }
            let totalMinutes = totalSeconds / 60.0
            if totalMinutes >= 60 {
                let hrs = totalMinutes / 60.0
                return (String(format: "%.1f", hrs), "hrs")
            } else {
                return ("\(Int(totalMinutes))", "min")
            }

        case .distance:
            // DaySessionSummary has no distance field; distance is unavailable
            return ("0.0", "km")

        case .calories:
            // Estimate: durationMin * 7 kcal
            let totalMinutes = Int(filtered.reduce(0.0) { $0 + $1.duration } / 60.0)
            let cal = totalMinutes * 7
            return ("\(cal)", "cal")

        case .steps:
            let total = filtered.reduce(0) { $0 + $1.steps }
            if total >= 10_000 {
                return (String(format: "%.1fk", Double(total) / 1000.0), "steps")
            } else {
                return ("\(total)", "steps")
            }

        case .runs:
            return ("\(filtered.count)", "runs")
        }
    }

    private func makeLabels(metric: StatMetric, period: TimePeriod) -> (metricLabel: String, periodLabel: String?) {
        let metricName: String
        switch metric {
        case .streak:   return ("Streak", nil)
        case .duration: metricName = "Duration"
        case .distance: metricName = "Distance"
        case .calories: metricName = "Calories"
        case .steps:    metricName = "Steps"
        case .runs:     metricName = "Runs"
        }
        let periodLine: String
        switch period {
        case .today: periodLine = "today"
        case .week:  periodLine = "per week"
        case .month: periodLine = "per month"
        case .year:  periodLine = "per year"
        }
        return (metricName, periodLine)
    }

    private func fontSizeFor(_ value: String) -> CGFloat {
        switch value.count {
        case ...3: return 80
        case 4:    return 72
        default:   return 72
        }
    }
}

// MARK: - SF Symbol icon helper

private func iconName(for metric: StatMetric) -> String {
    switch metric {
    case .streak:   return "flame"
    case .duration: return "timer"
    case .distance: return "location.circle"
    case .calories: return "flame"
    case .steps:    return "shoeprints.fill"
    case .runs:     return "figure.run"
    }
}

// MARK: - StatWidgetView

struct StatWidgetView: View {
    let entry: StatEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: app name left, metric icon right
            HStack {
                Text("NIKONEKO RUN")
                    .font(.system(size: 10)).tracking(0.8)
                    .foregroundColor(entry.theme.textMid)
                Spacer()
                Image(systemName: iconName(for: entry.metric))
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(entry.theme.textMid)
            }

            Spacer()

            // Value + unit baseline-aligned
            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text(entry.formattedValue)
                    .font(.system(size: entry.fontSize, weight: .ultraLight))
                    .foregroundColor(entry.theme.text)
                    .monospacedDigit()
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                Text(entry.unit)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(entry.theme.textMid)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 6)

            // Bottom label: "Duration per week" on one line
            Text(entry.periodLabel.map { "\(entry.metricLabel) \($0)" } ?? entry.metricLabel)
                .font(.system(size: 11))
                .foregroundColor(entry.theme.textMid)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(10)
        .containerBackground(entry.theme.bg, for: .widget)
    }
}

// MARK: - StatWidget

struct StatWidget: Widget {
    let kind = "StatWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StatWidgetIntent.self, provider: StatProvider()) { entry in
            StatWidgetView(entry: entry)
        }
        .configurationDisplayName("Stat")
        .description("Your running stats at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview

#if DEBUG
#Preview(as: .systemSmall) {
    StatWidget()
} timeline: {
    StatEntry(
        date: .now,
        metric: .streak,
        period: .week,
        formattedValue: "12",
        unit: "days",
        metricLabel: "Streak",
        periodLabel: nil,
        fontSize: 80,
        theme: ThemeLibrary.moss
    )
    StatEntry(
        date: .now,
        metric: .duration,
        period: .week,
        formattedValue: "3.5",
        unit: "hrs",
        metricLabel: "Duration",
        periodLabel: "per week",
        fontSize: 80,
        theme: ThemeLibrary.moss
    )
    StatEntry(
        date: .now,
        metric: .steps,
        period: .today,
        formattedValue: "8.2k",
        unit: "steps",
        metricLabel: "Steps",
        periodLabel: "today",
        fontSize: 72,
        theme: ThemeLibrary.moss
    )
    StatEntry(
        date: .now,
        metric: .runs,
        period: .month,
        formattedValue: "21",
        unit: "runs",
        metricLabel: "Runs",
        periodLabel: "per month",
        fontSize: 80,
        theme: ThemeLibrary.moss
    )
}
#endif

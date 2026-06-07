import WidgetKit
import SwiftUI
import AppIntents

// MARK: - HeatmapWidgetIntent

struct HeatmapWidgetIntent: AppIntent, WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Heatmap"

    @Parameter(title: "Metric", default: .duration)
    var metric: StatMetric
}

// MARK: - HeatmapEntry

struct HeatmapEntry: TimelineEntry {
    let date: Date
    let summaries: [DaySessionSummary]
    let metric: StatMetric   // not .streak
    let theme: ThemeTokens
}

// MARK: - HeatmapProvider

struct HeatmapProvider: AppIntentTimelineProvider {
    typealias Entry = HeatmapEntry
    typealias Intent = HeatmapWidgetIntent

    func placeholder(in context: Context) -> HeatmapEntry {
        HeatmapEntry(date: Date(), summaries: [], metric: .duration, theme: ThemeLibrary.moss)
    }

    func snapshot(for configuration: HeatmapWidgetIntent, in context: Context) async -> HeatmapEntry {
        makeEntry(for: configuration)
    }

    func timeline(for configuration: HeatmapWidgetIntent, in context: Context) async -> Timeline<HeatmapEntry> {
        let entry = makeEntry(for: configuration)
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(next))
    }

    private func makeEntry(for configuration: HeatmapWidgetIntent) -> HeatmapEntry {
        let theme = WidgetSharedData.loadTheme()
        return HeatmapEntry(
            date: Date(),
            summaries: AppGroupDefaults.loadSummaries(),
            metric: configuration.metric,
            theme: theme
        )
    }
}

// MARK: - HeatmapWidgetView

struct HeatmapWidgetView: View {
    let entry: HeatmapEntry

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let monthAbbr = ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"]
    private let labelWidth: CGFloat = 26
    private let gap: CGFloat = 1.5
    private let numCols = 18

    var body: some View {
        let (columns, monthHeaders) = buildColumns()
        let dailyValues = buildDailyValues()
        let maxValue = columns
            .flatMap { $0 }
            .compactMap { $0 }
            .map { dailyValues[$0] ?? 0.0 }
            .max() ?? 1.0

        VStack(alignment: .leading, spacing: 3) {
            // Header
            HStack {
                Text("NIKONEKO RUN")
                    .font(.system(size: 10)).tracking(0.8)
                    .foregroundColor(entry.theme.textMid)
                Spacer()
                Text(String(Calendar.current.component(.year, from: entry.date)))
                    .font(.system(size: 10)).tracking(0.8)
                    .foregroundColor(entry.theme.textMid)
            }
            .padding(.bottom, 6)

            // Month abbreviation row
            HStack(spacing: gap) {
                Spacer().frame(width: labelWidth)
                ForEach(0..<numCols, id: \.self) { col in
                    Text(monthHeaders[col])
                        .font(.system(size: 8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(entry.theme.textMid)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // Day rows: Mon–Sun
            VStack(spacing: gap) {
                ForEach(0..<7, id: \.self) { row in
                    HStack(spacing: gap) {
                        Text(dayLabels[row])
                            .font(.system(size: 8))
                            .foregroundColor(entry.theme.textMid)
                            .frame(width: labelWidth, alignment: .leading)

                        ForEach(0..<numCols, id: \.self) { col in
                            let dateKey = columns[col][row]
                            let value = dateKey.flatMap { dailyValues[$0] } ?? 0.0
                            let ratio = maxValue > 0 ? value / maxValue : 0.0
                            Rectangle()
                                .fill(cellColor(ratio: ratio))
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .cornerRadius(2)
                        }
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .containerBackground(entry.theme.bg, for: .widget)
    }

    // Returns:
    //   columns[col][row] = "YYYY-MM-DD" string or nil if the date is in the future
    //   monthHeaders[col] = "Jan" etc. if this column starts a new month, else ""
    private func buildColumns() -> (columns: [[String?]], monthHeaders: [String]) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: entry.date)

        // Find the Monday of the week that is (numCols - 1) weeks ago
        // "This week's Monday" = start of the week containing today (ISO: Mon=1)
        let todayWeekday = isoWeekday(of: today) // 1=Mon..7=Sun
        let daysToMonday = todayWeekday - 1
        let thisMonday = cal.date(byAdding: .day, value: -daysToMonday, to: today)!
        let oldestMonday = cal.date(byAdding: .weekOfYear, value: -(numCols - 1), to: thisMonday)!

        var columns = [[String?]](repeating: [String?](repeating: nil, count: 7), count: numCols)
        var monthHeaders = [String](repeating: "", count: numCols)
        var prevMonth: Int? = nil

        for col in 0..<numCols {
            let colMonday = cal.date(byAdding: .weekOfYear, value: col, to: oldestMonday)!
            let comps = cal.dateComponents([.month], from: colMonday)
            let month = comps.month!

            // Show month label when month changes
            if month != prevMonth {
                monthHeaders[col] = monthAbbr[month - 1]
                prevMonth = month
            }

            for row in 0..<7 {
                let day = cal.date(byAdding: .day, value: row, to: colMonday)!
                // Skip future dates
                if day <= today {
                    let dc = cal.dateComponents([.year, .month, .day], from: day)
                    columns[col][row] = String(format: "%04d-%02d-%02d", dc.year!, dc.month!, dc.day!)
                }
            }
        }

        return (columns, monthHeaders)
    }

    // Returns a dict keyed by "YYYY-MM-DD" with the metric value for that day.
    private func buildDailyValues() -> [String: Double] {
        let cal = Calendar.current
        var map: [String: (duration: Double, steps: Int, count: Int)] = [:]

        for summary in entry.summaries {
            let dc = cal.dateComponents([.year, .month, .day], from: summary.date)
            guard let y = dc.year, let m = dc.month, let d = dc.day else { continue }
            let key = String(format: "%04d-%02d-%02d", y, m, d)
            let existing = map[key] ?? (duration: 0, steps: 0, count: 0)
            map[key] = (
                duration: existing.duration + summary.duration,
                steps: existing.steps + summary.steps,
                count: existing.count + 1
            )
        }

        var result: [String: Double] = [:]
        for (key, agg) in map {
            let value: Double
            switch entry.metric {
            case .duration:
                value = agg.duration / 60.0   // minutes
            case .calories:
                let durationMin = agg.duration / 60.0
                value = durationMin * 7.0
            case .steps:
                value = Double(agg.steps)
            case .runs:
                value = Double(agg.count)
            case .distance:
                // DaySessionSummary has no distance field; estimate from steps
                value = Double(agg.steps) / 1500.0
            case .streak:
                // Streak is not a per-day metric; treat as completionRatio present/absent
                value = agg.count > 0 ? 1.0 : 0.0
            }
            result[key] = value
        }
        return result
    }

    // Maps a ratio (0–1 relative to daily max) to the bar color ramp.
    private func cellColor(ratio: Double) -> Color {
        if ratio == 0           { return entry.theme.bar[0] }
        else if ratio <= 0.25   { return entry.theme.bar[1] }
        else if ratio <= 0.50   { return entry.theme.bar[2] }
        else if ratio <= 0.75   { return entry.theme.bar[3] }
        else                    { return entry.theme.bar[4] }
    }

    // ISO weekday: Mon=1, Sun=7
    private func isoWeekday(of date: Date) -> Int {
        let wd = Calendar.current.component(.weekday, from: date) // 1=Sun..7=Sat
        return wd == 1 ? 7 : wd - 1
    }
}

// MARK: - HeatmapWidget

struct HeatmapWidget: Widget {
    let kind = "HeatmapWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: HeatmapWidgetIntent.self, provider: HeatmapProvider()) { entry in
            HeatmapWidgetView(entry: entry)
        }
        .configurationDisplayName("Heatmap")
        .description("18-week activity heatmap.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    HeatmapWidget()
} timeline: {
    HeatmapEntry(
        date: Date(),
        summaries: HeatmapPreviewData.summaries,
        metric: .duration,
        theme: ThemeLibrary.moss
    )
}

private enum HeatmapPreviewData {
    static let summaries: [DaySessionSummary] = {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var result: [DaySessionSummary] = []
        for daysAgo in 0..<126 {
            guard daysAgo % Int.random(in: 1...3) == 0 else { continue }
            let date = cal.date(byAdding: .day, value: -daysAgo, to: today)!
            result.append(DaySessionSummary  (
                date: date,
                duration: Double.random(in: 600...2400),
                completionRatio: Double.random(in: 0.5...1.0),
                hrAvg: Int.random(in: 110...160),
                steps: Int.random(in: 2000...8000)
            ))
        }
        return result
    }()
}

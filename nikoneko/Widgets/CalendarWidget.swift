import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Intent

struct CalendarWidgetIntent: AppIntent, WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Calendar Heatmap"
    @Parameter(title: "Metric", default: .duration) var metric: StatMetric
}

// MARK: - Entry

struct CalendarEntry: TimelineEntry {
    let date: Date
    let summaries: [DaySessionSummary]
    let metric: StatMetric
    let theme: ThemeTokens
}

// MARK: - Provider

struct CalendarProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: Date(), summaries: [], metric: .duration, theme: ThemeLibrary.obsidian)
    }
    func snapshot(for configuration: CalendarWidgetIntent, in context: Context) async -> CalendarEntry {
        entry(for: configuration)
    }
    func timeline(for configuration: CalendarWidgetIntent, in context: Context) async -> Timeline<CalendarEntry> {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        return Timeline(entries: [entry(for: configuration)], policy: .after(next))
    }
    private func entry(for config: CalendarWidgetIntent) -> CalendarEntry {
        let themeId = AppGroupDefaults.shared.string(forKey: "activeThemeId") ?? "obsidian"
        let theme = ThemeLibrary.all.first { $0.id == themeId } ?? ThemeLibrary.obsidian
        return CalendarEntry(date: Date(), summaries: AppGroupDefaults.loadSummaries(),
                             metric: config.metric, theme: theme)
    }
}

// MARK: - View

struct CalendarWidgetView: View {
    let entry: CalendarEntry
    private let cal = Calendar.current
    // Mon-first headers
    private let dayHeaders = ["M","T","W","T","F","S","S"]

    var body: some View {
        let monthStart = cal.dateInterval(of: .month, for: entry.date)!.start
        // weekday offset Mon=0: cal.component(.weekday) Sun=1..Sat=7 → Mon-based offset
        let rawWeekday = cal.component(.weekday, from: monthStart) // 1=Sun..7=Sat
        let firstOffset = (rawWeekday + 5) % 7  // Sun→6, Mon→0, Tue→1…
        let daysInMonth = cal.range(of: .day, in: .month, for: entry.date)!.count
        let today = cal.startOfDay(for: entry.date)
        let dailyMax = maxDailyValue()

        VStack(alignment: .leading, spacing: 0) {
            // Title
            Text("CHART · \(entry.metric.localizedStringResource.key.uppercased())")
                .font(.system(size: 9)).tracking(0.8)
                .foregroundColor(Color(white: 0.733))
                .padding(.bottom, 6)

            // Day headers
            HStack(spacing: 5) {
                ForEach(dayHeaders, id: \.self) { d in
                    Text(d).font(.system(size: 9)).foregroundColor(Color(white: 0.8))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 2)

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7),
                      spacing: 5) {
                // Empty slots before first day
                ForEach(0..<firstOffset, id: \.self) { _ in
                    Color(white: 0.922).aspectRatio(1, contentMode: .fit).cornerRadius(8)
                }
                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = cal.date(from: DateComponents(
                        year: cal.component(.year, from: entry.date),
                        month: cal.component(.month, from: entry.date),
                        day: day))!
                    let isFuture = date > today
                    let value = isFuture ? 0.0 : dayValue(for: date)
                    let level = colorLevel(value: value, max: dailyMax, isFuture: isFuture, hasData: value > 0)
                    let cellColor = entry.theme.cal[level]
                    let dateColor: Color = isFuture ? Color(white: 0.816) : (level >= 3 ? Color.white.opacity(0.65) : Color(white: 0.733))
                    let valColor: Color = level >= 3 ? Color.white.opacity(0.9) : Color(white: 0.533)

                    ZStack(alignment: .topLeading) {
                        cellColor.aspectRatio(1, contentMode: .fit).cornerRadius(8)
                        Text("\(day)")
                            .font(.system(size: 9)).foregroundColor(dateColor)
                            .padding(5)
                        if !isFuture && value > 0 {
                            Text(formattedCellValue(value))
                                .font(.system(size: 12, weight: .ultraLight))
                                .foregroundColor(valColor)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                .padding(.bottom, 5)
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(entry.theme.bg)
        .containerBackground(entry.theme.bg, for: .widget)
    }

    private func dayValue(for date: Date) -> Double {
        let daySummaries = entry.summaries.filter { cal.isDate($0.date, inSameDayAs: date) }
        switch entry.metric {
        case .duration:   return daySummaries.reduce(0) { $0 + $1.duration } / 60  // minutes
        case .steps:      return Double(daySummaries.reduce(0) { $0 + $1.steps })
        case .calories:   return daySummaries.reduce(0) { $0 + $1.duration } / 60 * 7
        case .distance:   return Double(daySummaries.reduce(0) { $0 + $1.steps }) / 1500
        case .runs:       return Double(daySummaries.count)
        case .streak:     return 0
        }
    }

    private func maxDailyValue() -> Double {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: entry.date)
        let month = calendar.component(.month, from: entry.date)
        let days = calendar.range(of: .day, in: .month, for: entry.date)!.count
        var max = 1.0
        for day in 1...days {
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                let v = dayValue(for: date)
                if v > max { max = v }
            }
        }
        return max
    }

    private func colorLevel(value: Double, max: Double, isFuture: Bool, hasData: Bool) -> Int {
        if isFuture || !hasData { return 0 }
        let ratio = value / max
        if ratio <= 0.25 { return 1 }
        if ratio <= 0.50 { return 2 }
        if ratio <= 0.75 { return 3 }
        return 4
    }

    private func formattedCellValue(_ value: Double) -> String {
        switch entry.metric {
        case .duration:
            return value >= 60 ? String(format: "%.0fh", value / 60) : "\(Int(value))"
        case .steps:
            return value >= 1000 ? String(format: "%.1fk", value / 1000) : "\(Int(value))"
        case .calories:
            return "\(Int(value))"
        case .distance:
            return String(format: "%.1f", value)
        case .runs:
            return "\(Int(value))"
        case .streak:
            return ""
        }
    }
}

// MARK: - Widget

struct CalendarWidget: Widget {
    let kind = "CalendarWidget"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: CalendarWidgetIntent.self,
                               provider: CalendarProvider()) { entry in
            CalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("Calendar Heatmap")
        .description("Monthly activity by day.")
        .supportedFamilies([.systemLarge])
    }
}

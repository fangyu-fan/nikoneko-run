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
        let rawWeekday = cal.component(.weekday, from: monthStart)
        let firstOffset = (rawWeekday + 5) % 7
        let daysInMonth = cal.range(of: .day, in: .month, for: entry.date)!.count
        let today = cal.startOfDay(for: entry.date)
        let dailyMax = maxDailyValue()

        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("NIKONEKO RUN")
                    .font(.system(size: 9)).tracking(0.8)
                    .foregroundColor(entry.theme.textMid)
                Spacer()
                Text(monthYearLabel())
                    .font(.system(size: 9)).tracking(0.8)
                    .foregroundColor(entry.theme.textMid)
            }
            .padding(.bottom, 8)

            HStack(spacing: 4) {
                ForEach(dayHeaders, id: \.self) { d in
                    Text(d).font(.system(size: 10)).foregroundColor(entry.theme.textMid)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
                spacing: 4
            ) {
                ForEach(0..<firstOffset, id: \.self) { _ in
                    entry.theme.cal[0]
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(8)
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
                    let dateColor: Color = isFuture ? entry.theme.textDim : entry.theme.onCal[level].opacity(0.65)
                    let valColor: Color = entry.theme.onCal[level]

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
            .frame(maxWidth: .infinity)

            Spacer()

            // Bottom stats row: today (left) · month (center) · streak (right)
            HStack(alignment: .top, spacing: 0) {
                let todayStats = statValueUnit(dayValue(for: today))
                statCell(icon: metricIcon(), label: "TODAY",
                         value: todayStats.value, unit: todayStats.unit,
                         alignment: .leading)
                let monthStats = statValueUnit(monthTotal())
                statCell(icon: metricIcon(), label: "THIS MONTH",
                         value: monthStats.value, unit: monthStats.unit,
                         alignment: .center)
                statCell(icon: "flame", label: "STREAK",
                         value: "\(currentStreak())", unit: "days",
                         alignment: .trailing)
            }
            .padding(.top, 10)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(entry.theme.bg)
        .containerBackground(entry.theme.bg, for: .widget)
    }

    @ViewBuilder
    private func statCell(icon: String, label: String, value: String, unit: String, alignment: HorizontalAlignment) -> some View {
        let hAlign: Alignment = alignment == .leading ? .leading : alignment == .trailing ? .trailing : .center
        VStack(alignment: alignment, spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8, weight: .light))
                    .foregroundColor(entry.theme.textMid)
                Text(label)
                    .font(.system(size: 7)).tracking(0.4)
                    .foregroundColor(entry.theme.textMid)
            }
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 24, weight: .ultraLight))
                    .foregroundColor(entry.theme.text)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(unit)
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(entry.theme.textMid)
            }
        }
        .frame(maxWidth: .infinity, alignment: hAlign)
    }

    private func statValueUnit(_ raw: Double) -> (value: String, unit: String) {
        switch entry.metric {
        case .duration:
            if raw >= 60 { return (String(format: "%.0f", raw / 60), "hr") }
            return ("\(Int(raw))", "min")
        case .steps:
            if raw >= 1000 { return (String(format: "%.1f", raw / 1000), "k") }
            return ("\(Int(raw))", "steps")
        case .calories:
            return ("\(Int(raw))", "kcal")
        case .distance:
            return (String(format: "%.1f", raw), "km")
        case .runs:
            return ("\(Int(raw))", "runs")
        case .streak:
            return ("\(Int(raw))", "days")
        }
    }

    private func monthTotal() -> Double {
        let year = cal.component(.year, from: entry.date)
        let month = cal.component(.month, from: entry.date)
        return entry.summaries
            .filter {
                cal.component(.year, from: $0.date) == year &&
                cal.component(.month, from: $0.date) == month
            }
            .reduce(0.0) { sum, s in
                switch entry.metric {
                case .duration:  return sum + s.duration / 60
                case .steps:     return sum + Double(s.steps)
                case .calories:  return sum + s.duration / 60 * 7
                case .distance:  return sum + Double(s.steps) / 1500
                case .runs:      return sum + 1
                case .streak:    return sum
                }
            }
    }

    private func monthYearLabel() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: entry.date)
    }

    private func metricIcon() -> String {
        switch entry.metric {
        case .duration:  return "timer"
        case .steps:     return "shoeprints.fill"
        case .calories:  return "flame"
        case .distance:  return "location.circle"
        case .runs:      return "number.circle"
        case .streak:    return "flame"
        }
    }

    private func metricUnit() -> String {
        switch entry.metric {
        case .duration:  return "min"
        case .steps:     return "steps"
        case .calories:  return "kcal"
        case .distance:  return "km"
        case .runs:      return "runs"
        case .streak:    return "days"
        }
    }

private func currentStreak() -> Int {
        let today = cal.startOfDay(for: entry.date)
        var streak = 0
        var cursor = today
        while true {
            let hasSessions = entry.summaries.contains { cal.isDate($0.date, inSameDayAs: cursor) }
            if hasSessions {
                streak += 1
                cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
            } else {
                break
            }
        }
        return streak
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

// MARK: - Preview

#Preview(as: .systemLarge) {
    CalendarWidget()
} timeline: {
    CalendarEntry(
        date: Date(),
        summaries: CalendarPreviewData.summaries,
        metric: .duration,
        theme: ThemeLibrary.obsidian
    )
}

private enum CalendarPreviewData {
    static let summaries: [DaySessionSummary] = {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var result: [DaySessionSummary] = []
        for daysAgo in 0..<30 {
            guard daysAgo % Int.random(in: 1...3) == 0 else { continue }
            let date = cal.date(byAdding: .day, value: -daysAgo, to: today)!
            result.append(DaySessionSummary(
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

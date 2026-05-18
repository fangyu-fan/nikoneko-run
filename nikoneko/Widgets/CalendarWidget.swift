import WidgetKit
import SwiftUI

struct CalendarEntry: TimelineEntry {
    let date: Date
    let summaries: [DaySessionSummary]
    let theme: ThemeTokens
    let t1: Int; let t2: Int; let t3: Int
}

struct CalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: Date(), summaries: [], theme: ThemeLibrary.obsidian, t1: 10, t2: 50, t3: 90)
    }
    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        completion(entry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry()], policy: .after(next)))
    }
    private func entry() -> CalendarEntry {
        let themeId = AppGroupDefaults.shared.string(forKey: "widget.calendar.themeId")
            ?? AppGroupDefaults.shared.string(forKey: "activeThemeId") ?? "obsidian"
        let theme = ThemeLibrary.all.first { $0.id == themeId } ?? ThemeLibrary.obsidian
        return CalendarEntry(
            date: Date(), summaries: AppGroupDefaults.loadSummaries(),
            theme: theme, t1: 10, t2: 50, t3: 90
        )
    }
}

struct CalendarWidgetView: View {
    let entry: CalendarEntry
    private let cal = Calendar.current
    private let dayHeaders = ["S","M","T","W","T","F","S"]

    var body: some View {
        let monthStart = cal.dateInterval(of: .month, for: entry.date)!.start
        let firstWeekday = cal.component(.weekday, from: monthStart) - 1
        let daysInMonth = cal.range(of: .day, in: .month, for: entry.date)!.count

        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(entry.date, format: .dateTime.month(.wide).year())
                    .font(.system(size: 11, weight: .medium)).foregroundColor(entry.theme.text)
                Spacer()
            }

            HStack(spacing: 2) {
                ForEach(dayHeaders, id: \.self) { d in
                    Text(d).font(.system(size: 7)).foregroundColor(entry.theme.textDim)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7),
                      spacing: 2) {
                ForEach(0..<firstWeekday, id: \.self) { _ in Color.clear.aspectRatio(1, contentMode: .fit) }
                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = cal.date(from: DateComponents(
                        year: cal.component(.year, from: entry.date),
                        month: cal.component(.month, from: entry.date),
                        day: day))!
                    let dayTotal = entry.summaries
                        .filter { cal.isDate($0.date, inSameDayAs: date) }
                        .reduce(0) { $0 + $1.completionRatio }
                    let ratio = min(1.0, dayTotal)
                    let isToday = cal.isDateInToday(date)

                    ZStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(WidgetSharedData.barColor(
                                ratio: ratio, theme: entry.theme,
                                t1: entry.t1, t2: entry.t2, t3: entry.t3))
                        if isToday {
                            RoundedRectangle(cornerRadius: 2).stroke(entry.theme.text, lineWidth: 1)
                        }
                        Text("\(day)")
                            .font(.system(size: 6.5))
                            .foregroundColor(entry.theme.text.opacity(ratio > 0 ? 0.8 : 0.4))
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .padding(10)
        .background(entry.theme.bg)
        .containerBackground(entry.theme.bg, for: .widget)
    }
}

struct CalendarWidget: Widget {
    let kind = "CalendarWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            CalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("Month Calendar")
        .description("Full month activity calendar.")
        .supportedFamilies([.systemLarge])
    }
}

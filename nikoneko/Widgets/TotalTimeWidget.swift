import WidgetKit
import SwiftUI

struct TodayDurationEntry: TimelineEntry {
    let date: Date
    let durationMin: Int
    let theme: ThemeTokens
}

struct TodayDurationProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayDurationEntry {
        TodayDurationEntry(date: Date(), durationMin: 24, theme: ThemeLibrary.obsidian)
    }
    func getSnapshot(in context: Context, completion: @escaping (TodayDurationEntry) -> Void) {
        completion(entry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayDurationEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry()], policy: .after(next)))
    }
    private func entry() -> TodayDurationEntry {
        let theme = WidgetTheme.load(for: "widget.todayDuration.themeId")
        let stats = WidgetTheme.todayStats(from: AppGroupDefaults.loadSummaries())
        return TodayDurationEntry(date: Date(), durationMin: stats.durationMin, theme: theme)
    }
}

struct TodayDurationWidgetView: View {
    let entry: TodayDurationEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TODAY")
                .font(.system(size: 8)).tracking(1)
                .foregroundColor(entry.theme.textDim)
            Text("\(entry.durationMin)")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundColor(entry.theme.accent)
                .monospacedDigit()
            Text("min today")
                .font(.system(size: 9))
                .foregroundColor(entry.theme.textDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
        .background(entry.theme.bg)
        .containerBackground(entry.theme.bg, for: .widget)
    }
}

struct TodayDurationWidget: Widget {
    let kind = "TodayDurationWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayDurationProvider()) { entry in
            TodayDurationWidgetView(entry: entry)
        }
        .configurationDisplayName("Today Duration")
        .description("Minutes jogged today.")
        .supportedFamilies([.systemSmall])
    }
}

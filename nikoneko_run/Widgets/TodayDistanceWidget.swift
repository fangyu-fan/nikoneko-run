import WidgetKit
import SwiftUI

struct TodayDistanceEntry: TimelineEntry {
    let date: Date
    let hasData: Bool
    let theme: ThemeTokens
}

struct TodayDistanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayDistanceEntry {
        TodayDistanceEntry(date: Date(), hasData: false, theme: ThemeLibrary.obsidian)
    }
    func getSnapshot(in context: Context, completion: @escaping (TodayDistanceEntry) -> Void) {
        completion(entry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayDistanceEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry()], policy: .after(next)))
    }
    private func entry() -> TodayDistanceEntry {
        let theme = WidgetTheme.load(for: "widget.todayDistance.themeId")
        let stats = WidgetTheme.todayStats(from: AppGroupDefaults.loadSummaries())
        // DaySessionSummary has no distance field; show "—" when no step data available
        return TodayDistanceEntry(date: Date(), hasData: stats.hasSteps, theme: theme)
    }
}

struct TodayDistanceWidgetView: View {
    let entry: TodayDistanceEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TODAY")
                .font(.system(size: 8)).tracking(1)
                .foregroundColor(entry.theme.textDim)
            Text(entry.hasData ? "—" : "—")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundColor(entry.theme.accent)
            Text("km today")
                .font(.system(size: 9))
                .foregroundColor(entry.theme.textDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
        .background(entry.theme.bg)
        .containerBackground(entry.theme.bg, for: .widget)
    }
}

struct TodayDistanceWidget: Widget {
    let kind = "TodayDistanceWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayDistanceProvider()) { entry in
            TodayDistanceWidgetView(entry: entry)
        }
        .configurationDisplayName("Today Distance")
        .description("Distance jogged today.")
        .supportedFamilies([.systemSmall])
    }
}

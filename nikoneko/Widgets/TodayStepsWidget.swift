import WidgetKit
import SwiftUI

struct TodayStepsEntry: TimelineEntry {
    let date: Date
    let steps: Int
    let theme: ThemeTokens
}

struct TodayStepsProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayStepsEntry {
        TodayStepsEntry(date: Date(), steps: 3200, theme: ThemeLibrary.obsidian)
    }
    func getSnapshot(in context: Context, completion: @escaping (TodayStepsEntry) -> Void) {
        completion(entry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayStepsEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry()], policy: .after(next)))
    }
    private func entry() -> TodayStepsEntry {
        let theme = WidgetTheme.load(for: "widget.todaySteps.themeId")
        let stats = WidgetTheme.todayStats(from: AppGroupDefaults.loadSummaries())
        return TodayStepsEntry(date: Date(), steps: stats.steps, theme: theme)
    }
}

struct TodayStepsWidgetView: View {
    let entry: TodayStepsEntry

    private var stepsFormatted: String {
        if entry.steps >= 10_000 {
            return String(format: "%.1fk", Double(entry.steps) / 1000)
        }
        return "\(entry.steps)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TODAY")
                .font(.system(size: 8)).tracking(1)
                .foregroundColor(entry.theme.textDim)
            Text(stepsFormatted)
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundColor(entry.theme.accent)
                .monospacedDigit()
            Text("steps today")
                .font(.system(size: 9))
                .foregroundColor(entry.theme.textDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
        .background(entry.theme.bg)
        .containerBackground(entry.theme.bg, for: .widget)
    }
}

struct TodayStepsWidget: Widget {
    let kind = "TodayStepsWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayStepsProvider()) { entry in
            TodayStepsWidgetView(entry: entry)
        }
        .configurationDisplayName("Today Steps")
        .description("Steps taken today.")
        .supportedFamilies([.systemSmall])
    }
}

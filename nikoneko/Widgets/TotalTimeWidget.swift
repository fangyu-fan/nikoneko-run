import WidgetKit
import SwiftUI

struct TotalTimeEntry: TimelineEntry {
    let date: Date
    let totalHours: Double
    let theme: ThemeTokens
}

struct TotalTimeProvider: TimelineProvider {
    func placeholder(in context: Context) -> TotalTimeEntry {
        TotalTimeEntry(date: Date(), totalHours: 48.4, theme: ThemeLibrary.obsidian)
    }
    func getSnapshot(in context: Context, completion: @escaping (TotalTimeEntry) -> Void) {
        completion(entry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<TotalTimeEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry()], policy: .after(next)))
    }
    private func entry() -> TotalTimeEntry {
        let theme = WidgetSharedData.loadTheme()
        let total = AppGroupDefaults.loadSummaries().reduce(0) { $0 + $1.duration } / 3600
        return TotalTimeEntry(date: Date(), totalHours: total, theme: theme)
    }
}

struct TotalTimeWidgetView: View {
    let entry: TotalTimeEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TOTAL").font(.system(size: 8)).tracking(1).foregroundColor(entry.theme.textDim)
            Text(String(format: "%.1f", entry.totalHours))
                .font(.system(size: 32, weight: .ultraLight)).foregroundColor(entry.theme.accent)
            Text("hours").font(.system(size: 9)).foregroundColor(entry.theme.textDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
        .background(entry.theme.bg)
        .containerBackground(entry.theme.bg, for: .widget)
    }
}

struct TotalTimeWidget: Widget {
    let kind = "TotalTimeWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TotalTimeProvider()) { entry in
            TotalTimeWidgetView(entry: entry)
        }
        .configurationDisplayName("Total Time")
        .description("Cumulative jogging hours.")
        .supportedFamilies([.systemSmall])
    }
}

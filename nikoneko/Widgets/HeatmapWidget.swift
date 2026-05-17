import WidgetKit
import SwiftUI

struct HeatmapEntry: TimelineEntry {
    let date: Date
    let summaries: [DaySessionSummary]
    let theme: ThemeTokens
    let t1: Int; let t2: Int; let t3: Int
}

struct HeatmapProvider: TimelineProvider {
    func placeholder(in context: Context) -> HeatmapEntry {
        HeatmapEntry(date: Date(), summaries: [], theme: ThemeLibrary.obsidian, t1: 10, t2: 50, t3: 90)
    }
    func getSnapshot(in context: Context, completion: @escaping (HeatmapEntry) -> Void) {
        completion(entry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<HeatmapEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry()], policy: .after(next)))
    }
    private func entry() -> HeatmapEntry {
        HeatmapEntry(
            date: Date(),
            summaries: AppGroupDefaults.loadSummaries(),
            theme: WidgetSharedData.loadTheme(),
            t1: 10, t2: 50, t3: 90
        )
    }
}

struct HeatmapWidgetView: View {
    let entry: HeatmapEntry
    private let cols = 18, rows = 7

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("THIS YEAR")
                .font(.system(size: 7)).tracking(1).foregroundColor(entry.theme.textDim)
            let cells = buildCells()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: cols),
                      spacing: 2) {
                ForEach(0..<cols * rows, id: \.self) { i in
                    let ratio = cells[safe: i] ?? 0.0
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(WidgetSharedData.barColor(
                            ratio: ratio, theme: entry.theme,
                            t1: entry.t1, t2: entry.t2, t3: entry.t3))
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .padding(12)
        .background(entry.theme.bg)
        .containerBackground(entry.theme.bg, for: .widget)
    }

    private func buildCells() -> [Double] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let totalCells = cols * rows
        var result = [Double](repeating: 0, count: totalCells)
        for i in 0..<totalCells {
            let daysAgo = totalCells - 1 - i
            let day = cal.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayTotal = entry.summaries
                .filter { cal.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.completionRatio }
            result[i] = min(1.0, dayTotal)
        }
        return result
    }
}

struct HeatmapWidget: Widget {
    let kind = "HeatmapWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HeatmapProvider()) { entry in
            HeatmapWidgetView(entry: entry)
        }
        .configurationDisplayName("Year Heatmap")
        .description("GitHub-style activity grid.")
        .supportedFamilies([.systemMedium])
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

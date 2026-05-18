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
        let theme = WidgetTheme.load(for: "widget.heatmap.themeId")
        return HeatmapEntry(
            date: Date(),
            summaries: AppGroupDefaults.loadSummaries(),
            theme: theme,
            t1: 10, t2: 50, t3: 90
        )
    }
}

// MARK: - Year Heatmap: 3 rows × 4 months each, GitHub-style grid

struct HeatmapWidgetView: View {
    let entry: HeatmapEntry

    // The calendar year split into three bands of 4 months.
    // Row 0: Jan–Apr, Row 1: May–Aug, Row 2: Sep–Dec
    private let monthBands: [[Int]] = [[1,2,3,4], [5,6,7,8], [9,10,11,12]]
    private let dayLabels = ["M","T","W","T","F","S","S"]
    private let monthAbbr = ["","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

    var body: some View {
        let year = Calendar.current.component(.year, from: entry.date)
        let ratioMap = buildRatioMap(year: year)

        VStack(alignment: .leading, spacing: 5) {
            Text("THIS YEAR")
                .font(.system(size: 7)).tracking(1)
                .foregroundColor(entry.theme.textDim)

            VStack(alignment: .leading, spacing: 5) {
                ForEach(monthBands.indices, id: \.self) { bandIdx in
                    monthBandView(
                        months: monthBands[bandIdx],
                        year: year,
                        ratioMap: ratioMap
                    )
                }
            }
        }
        .padding(10)
        .background(entry.theme.bg)
        .containerBackground(entry.theme.bg, for: .widget)
    }

    // One horizontal strip of 4 months side by side.
    private func monthBandView(months: [Int], year: Int, ratioMap: [String: Double]) -> some View {
        HStack(alignment: .top, spacing: 4) {
            ForEach(months, id: \.self) { month in
                monthColumnView(month: month, year: year, ratioMap: ratioMap)
            }
        }
    }

    // One month rendered as a column of weeks (max 5-6 cols × 7 rows).
    private func monthColumnView(month: Int, year: Int, ratioMap: [String: Double]) -> some View {
        let cal = Calendar.current
        let comps = DateComponents(year: year, month: month, day: 1)
        guard let firstDay = cal.date(from: comps) else { return AnyView(EmptyView()) }
        let daysInMonth = cal.range(of: .day, in: .month, for: firstDay)!.count
        // ISO weekday: 1=Mon ... 7=Sun
        let firstWeekdayISO = isoWeekday(of: firstDay)
        let totalCells = firstWeekdayISO - 1 + daysInMonth
        let weeksNeeded = (totalCells + 6) / 7

        return AnyView(
            VStack(alignment: .leading, spacing: 1) {
                // Month label
                Text(monthAbbr[month])
                    .font(.system(size: 5.5))
                    .foregroundColor(entry.theme.textMid)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Grid: weeks across, days down
                HStack(alignment: .top, spacing: 1) {
                    ForEach(0..<weeksNeeded, id: \.self) { week in
                        VStack(spacing: 1) {
                            ForEach(0..<7, id: \.self) { dow in
                                let cellIndex = week * 7 + dow
                                let dayNumber = cellIndex - (firstWeekdayISO - 1) + 1
                                if dayNumber >= 1 && dayNumber <= daysInMonth {
                                    let key = dateKey(year: year, month: month, day: dayNumber)
                                    let ratio = ratioMap[key] ?? 0.0
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(WidgetSharedData.barColor(
                                            ratio: ratio, theme: entry.theme,
                                            t1: entry.t1, t2: entry.t2, t3: entry.t3))
                                        .frame(width: 4, height: 4)
                                } else {
                                    Color.clear.frame(width: 4, height: 4)
                                }
                            }
                        }
                    }
                }
            }
        )
    }

    // Build a dictionary keyed by "YYYY-MM-DD" → completion ratio for the given year.
    private func buildRatioMap(year: Int) -> [String: Double] {
        var map: [String: Double] = [:]
        let cal = Calendar.current
        for summary in entry.summaries {
            let comps = cal.dateComponents([.year, .month, .day], from: summary.date)
            guard comps.year == year,
                  let m = comps.month, let d = comps.day else { continue }
            let key = dateKey(year: year, month: m, day: d)
            map[key, default: 0] += summary.completionRatio
        }
        // Cap at 1.0
        return map.mapValues { min(1.0, $0) }
    }

    private func dateKey(year: Int, month: Int, day: Int) -> String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    // ISO weekday where Monday=1, Sunday=7.
    private func isoWeekday(of date: Date) -> Int {
        let cal = Calendar.current
        // Calendar.current.weekday: 1=Sun, 2=Mon... 7=Sat
        let wd = cal.component(.weekday, from: date)
        return wd == 1 ? 7 : wd - 1
    }
}

struct HeatmapWidget: Widget {
    let kind = "HeatmapWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HeatmapProvider()) { entry in
            HeatmapWidgetView(entry: entry)
        }
        .configurationDisplayName("Year Heatmap")
        .description("GitHub-style activity grid for the full year.")
        .supportedFamilies([.systemMedium])
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

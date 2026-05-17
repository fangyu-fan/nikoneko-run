import WidgetKit
import SwiftUI

struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let theme: ThemeTokens
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), streak: 7, theme: ThemeLibrary.obsidian)
    }
    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(entry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry()], policy: .after(next)))
    }
    private func entry() -> StreakEntry {
        let theme = WidgetSharedData.loadTheme()
        let summaries = AppGroupDefaults.loadSummaries()
        let goal = max(AppGroupDefaults.shared.integer(forKey: "dailyGoalMinutes"), 1)
        let streak = AppGroupDefaults.currentStreak(from: summaries, goalMinutes: goal)
        return StreakEntry(date: Date(), streak: streak, theme: theme)
    }
}

struct StreakWidgetView: View {
    let entry: StreakEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("STREAK").font(.system(size: 8)).tracking(1).foregroundColor(entry.theme.textDim)
            Text("\(entry.streak)")
                .font(.system(size: 32, weight: .ultraLight)).foregroundColor(entry.theme.accent)
            Text("days").font(.system(size: 9)).foregroundColor(entry.theme.textDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
        .background(entry.theme.bg)
        .containerBackground(entry.theme.bg, for: .widget)
    }
}

struct StreakWidget: Widget {
    let kind = "StreakWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Your current run streak.")
        .supportedFamilies([.systemSmall])
    }
}

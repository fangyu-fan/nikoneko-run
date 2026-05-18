import WidgetKit
import SwiftUI

// MARK: - Entry

struct AllStatsEntry: TimelineEntry {
    let date: Date
    let theme: ThemeTokens
    // Today values
    let durationMin: Int
    let steps: Int
    let calories: Int
    let hrAvg: Int
    let streak: Int
}

// MARK: - Provider

struct AllStatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> AllStatsEntry {
        AllStatsEntry(date: Date(), theme: ThemeLibrary.obsidian,
                      durationMin: 30, steps: 4200, calories: 240, hrAvg: 148, streak: 7)
    }
    func getSnapshot(in context: Context, completion: @escaping (AllStatsEntry) -> Void) {
        completion(entry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<AllStatsEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry()], policy: .after(next)))
    }
    private func entry() -> AllStatsEntry {
        let theme = WidgetTheme.load(for: "widget.allStats.themeId")
        let summaries = AppGroupDefaults.loadSummaries()
        let stats = WidgetTheme.todayStats(from: summaries)
        let goal = max(AppGroupDefaults.shared.integer(forKey: "dailyGoalMinutes"), 1)
        let streak = AppGroupDefaults.currentStreak(from: summaries, goalMinutes: goal)
        // Rough calorie estimate: ~7 kcal/min for slow jogging
        let calories = stats.durationMin * 7
        return AllStatsEntry(
            date: Date(),
            theme: theme,
            durationMin: stats.durationMin,
            steps: stats.steps,
            calories: calories,
            hrAvg: stats.hrAvg,
            streak: streak
        )
    }
}

// MARK: - View

struct AllStatsWidgetView: View {
    let entry: AllStatsEntry

    private var stepsFormatted: String {
        entry.steps >= 10_000
            ? String(format: "%.1fk", Double(entry.steps) / 1000)
            : "\(entry.steps)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("TODAY")
                .font(.system(size: 8)).tracking(1)
                .foregroundColor(entry.theme.textDim)
                .padding(.bottom, 10)

            // 2 × 3 stat grid
            VStack(spacing: 12) {
                statRow(
                    left: (value: "\(entry.durationMin)", label: "min"),
                    right: (value: entry.steps > 0 ? stepsFormatted : "—", label: "steps")
                )
                statRow(
                    left: (value: "\(entry.calories)", label: "kcal"),
                    right: (value: entry.hrAvg > 0 ? "\(entry.hrAvg)" : "—", label: "avg HR")
                )
                statRow(
                    left: (value: "—", label: "km"),
                    right: (value: "\(entry.streak)", label: "day streak")
                )
            }

            Spacer()

            // Footer date
            Text(entry.date, style: .date)
                .font(.system(size: 8))
                .foregroundColor(entry.theme.textDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(14)
        .background(entry.theme.bg)
        .containerBackground(entry.theme.bg, for: .widget)
    }

    private func statRow(
        left: (value: String, label: String),
        right: (value: String, label: String)
    ) -> some View {
        HStack(spacing: 0) {
            statCell(value: left.value, label: left.label)
            Spacer()
            statCell(value: right.value, label: right.label)
            Spacer()
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.system(size: 28, weight: .ultraLight))
                .foregroundColor(entry.theme.accent)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(entry.theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Widget

struct AllStatsWidget: Widget {
    let kind = "AllStatsWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AllStatsProvider()) { entry in
            AllStatsWidgetView(entry: entry)
        }
        .configurationDisplayName("All Stats")
        .description("Duration, steps, calories, HR, and streak at a glance.")
        .supportedFamilies([.systemLarge])
    }
}

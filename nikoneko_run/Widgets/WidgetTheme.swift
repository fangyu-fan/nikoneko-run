import Foundation

// Shared helper for all widget providers — theme loading and today stat aggregation.
enum WidgetTheme {
    static func load(for widgetKey: String) -> ThemeTokens {
        let id = AppGroupDefaults.shared.string(forKey: widgetKey)
            ?? AppGroupDefaults.shared.string(forKey: "activeThemeId")
            ?? "obsidian"
        return ThemeLibrary.all.first { $0.id == id } ?? ThemeLibrary.obsidian
    }

    struct TodayStats {
        let durationMin: Int
        let steps: Int
        let hrAvg: Int
        let hasSteps: Bool
    }

    static func todayStats(from summaries: [DaySessionSummary]) -> TodayStats {
        let cal = Calendar.current
        let today = summaries.filter { cal.isDateInToday($0.date) }
        let durationMin = Int(today.reduce(0) { $0 + $1.duration } / 60)
        let steps = today.reduce(0) { $0 + $1.steps }
        let hrSamples = today.filter { $0.hrAvg > 0 }
        let hrAvg = hrSamples.isEmpty ? 0 : hrSamples.reduce(0) { $0 + $1.hrAvg } / hrSamples.count
        return TodayStats(durationMin: durationMin, steps: steps, hrAvg: hrAvg, hasSteps: steps > 0)
    }
}

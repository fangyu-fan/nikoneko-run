import SwiftUI
import WidgetKit

struct WidgetSharedData {
    static func colorLevel(ratio: Double, settings: WidgetReportSettings) -> Int {
        let percentage = ratio * 100
        if percentage <= 0 { return 0 }
        if percentage <= Double(settings.threshold1) { return 1 }
        if percentage < Double(settings.threshold2) { return 2 }
        if percentage <= Double(settings.threshold3) { return 3 }
        return 4
    }

    static func barColor(ratio: Double, theme: ThemeTokens, t1: Int, t2: Int, t3: Int) -> Color {
        let settings = WidgetReportSettings(
            dailyGoalMinutes: WidgetReportSettings.defaults.dailyGoalMinutes,
            threshold1: t1,
            threshold2: t2,
            threshold3: t3
        )
        return theme.bar[colorLevel(ratio: ratio, settings: settings)]
    }

    static func calendarColor(ratio: Double, theme: ThemeTokens, settings: WidgetReportSettings) -> Color {
        theme.cal[colorLevel(ratio: ratio, settings: settings)]
    }

    static func completionRatio(
        for summaries: [DaySessionSummary],
        settings: WidgetReportSettings
    ) -> Double {
        let duration = summaries.reduce(0.0) { $0 + $1.duration }
        return duration / (Double(settings.dailyGoalMinutes) * 60)
    }

    static func loadTheme() -> ThemeTokens {
        let id = AppGroupDefaults.shared.string(forKey: "activeThemeId") ?? "obsidian"
        return ThemeLibrary.all.first { $0.id == id } ?? ThemeLibrary.obsidian
    }
}

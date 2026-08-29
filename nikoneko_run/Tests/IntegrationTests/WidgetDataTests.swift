import XCTest
@testable import nikoneko

final class WidgetDataTests: XCTestCase {

    func test_barColorBoundaries() {
        let theme = ThemeLibrary.obsidian
        XCTAssertEqual(WidgetSharedData.barColor(ratio: 0.0,  theme: theme, t1: 10, t2: 50, t3: 90), theme.bar[0])
        XCTAssertEqual(WidgetSharedData.barColor(ratio: 0.05, theme: theme, t1: 10, t2: 50, t3: 90), theme.bar[1])
        XCTAssertEqual(WidgetSharedData.barColor(ratio: 0.30, theme: theme, t1: 10, t2: 50, t3: 90), theme.bar[2])
        XCTAssertEqual(WidgetSharedData.barColor(ratio: 0.70, theme: theme, t1: 10, t2: 50, t3: 90), theme.bar[3])
        XCTAssertEqual(WidgetSharedData.barColor(ratio: 1.0,  theme: theme, t1: 10, t2: 50, t3: 90), theme.bar[4])
    }

    func test_completionRatioUsesDailyGoal() {
        let settings = WidgetReportSettings(
            dailyGoalMinutes: 20,
            threshold1: 25,
            threshold2: 60,
            threshold3: 90
        )
        let summaries = [
            DaySessionSummary(
                date: Date(),
                duration: 6 * 60,
                completionRatio: 0,
                hrAvg: 0,
                steps: 0
            ),
            DaySessionSummary(
                date: Date(),
                duration: 4 * 60,
                completionRatio: 0,
                hrAvg: 0,
                steps: 0
            )
        ]

        XCTAssertEqual(
            WidgetSharedData.completionRatio(for: summaries, settings: settings),
            0.5,
            accuracy: 0.001
        )
    }

    func test_streakCalculation() {
        let summaries = (0..<7).map { i in
            DaySessionSummary(
                date: Calendar.current.date(byAdding: .day, value: -i, to: Date())!,
                duration: 1800, completionRatio: 1.0, hrAvg: 120, steps: 3000
            )
        }
        let streak = AppGroupDefaults.currentStreak(from: summaries, goalMinutes: 20)
        XCTAssertEqual(streak, 7)
    }

    func test_themeWrittenToAppGroup() {
        AppGroupDefaults.shared.set("paper", forKey: "activeThemeId")
        let theme = WidgetSharedData.loadTheme()
        XCTAssertEqual(theme.id, "paper")
        AppGroupDefaults.shared.removeObject(forKey: "activeThemeId")
    }
}

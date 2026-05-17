import XCTest
@testable import nikoneko

final class WidgetDataTests: XCTestCase {

    func test_barColorBoundaries() {
        let theme = ThemeLibrary.obsidian
        XCTAssertEqual(WidgetSharedData.barColor(ratio: 0.0,  theme: theme, t1: 10, t2: 50, t3: 90), theme.cal[0])
        XCTAssertEqual(WidgetSharedData.barColor(ratio: 0.05, theme: theme, t1: 10, t2: 50, t3: 90), theme.cal[1])
        XCTAssertEqual(WidgetSharedData.barColor(ratio: 0.30, theme: theme, t1: 10, t2: 50, t3: 90), theme.cal[2])
        XCTAssertEqual(WidgetSharedData.barColor(ratio: 0.70, theme: theme, t1: 10, t2: 50, t3: 90), theme.cal[3])
        XCTAssertEqual(WidgetSharedData.barColor(ratio: 1.0,  theme: theme, t1: 10, t2: 50, t3: 90), theme.cal[4])
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
}

import XCTest
import SwiftUI
@testable import nikoneko

final class CalendarWidgetLayoutTests: XCTestCase {
    func test_allMonthsFitWithinLargeWidgetHeight() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let widgetSize = CGSize(width: 338, height: 354)

        for month in 1...12 {
            let date = calendar.date(from: DateComponents(year: 2026, month: month, day: 1))!
            let weekday = calendar.component(.weekday, from: date)
            let offset = AppGroupDefaults.weekStartsOnMonday
                ? (weekday + 5) % 7
                : weekday - 1
            let days = calendar.range(of: .day, in: .month, for: date)!.count
            let weeks = CalendarWidgetLayout.weekCount(firstOffset: offset, daysInMonth: days)
            let side = CalendarWidgetLayout.cellSide(
                containerSize: widgetSize,
                horizontalPadding: 12,
                topPadding: 4,
                bottomPadding: 1,
                headerHeight: 26,
                statsHeight: 37,
                weekCount: weeks,
                gridSpacing: 4
            )

            XCTAssertGreaterThan(side, 0, "Month \(month) produced an empty grid")
            XCTAssertLessThanOrEqual(weeks * side + CGFloat(weeks - 1) * 4, 286.01,
                                     "Month \(month) overflows the available grid height")
        }
    }

    func testFiveAndSixWeekMonthsUseDifferentVerticalFit() {
        let size = CGSize(width: 338, height: 354)
        let fiveWeekSide = CalendarWidgetLayout.cellSide(
            containerSize: size, horizontalPadding: 12, topPadding: 4, bottomPadding: 1,
            headerHeight: 26, statsHeight: 37, weekCount: 5, gridSpacing: 4
        )
        let sixWeekSide = CalendarWidgetLayout.cellSide(
            containerSize: size, horizontalPadding: 12, topPadding: 4, bottomPadding: 1,
            headerHeight: 26, statsHeight: 37, weekCount: 6, gridSpacing: 4
        )

        XCTAssertGreaterThanOrEqual(fiveWeekSide, sixWeekSide)
    }
}

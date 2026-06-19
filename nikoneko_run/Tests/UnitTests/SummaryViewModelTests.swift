import XCTest
@testable import nikoneko

final class SummaryViewModelTests: XCTestCase {

    func test_streakCountsConsecutiveDays() {
        let summaries = (0..<5).map { i in
            DaySessionSummary(
                date: Calendar.current.date(byAdding: .day, value: -i, to: Date())!,
                duration: 1200,
                completionRatio: 1.0,
                hrAvg: 120,
                steps: 2000
            )
        }
        let streak = AppGroupDefaults.currentStreak(from: summaries, goalMinutes: 15)
        XCTAssertEqual(streak, 5)
    }

    func test_streakBreaksOnMissedDay() {
        var summaries = (0..<3).map { i in
            DaySessionSummary(
                date: Calendar.current.date(byAdding: .day, value: -i, to: Date())!,
                duration: 1200,
                completionRatio: 1.0,
                hrAvg: 120,
                steps: 2000
            )
        }
        summaries.append(DaySessionSummary(
            date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
            duration: 1200,
            completionRatio: 1.0,
            hrAvg: 120,
            steps: 2000
        ))
        let streak = AppGroupDefaults.currentStreak(from: summaries, goalMinutes: 15)
        XCTAssertEqual(streak, 3)
    }

    func test_weekDotsCount() {
        let vm = SummaryViewModel(
            session: RunSession(startDate: Date(), duration: 1200),
            summaries: [],
            goalMinutes: 20
        )
        XCTAssertEqual(vm.thisWeekDots.count, 7)
    }
}

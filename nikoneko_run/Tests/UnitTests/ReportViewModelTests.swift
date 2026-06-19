import XCTest
@testable import nikoneko

final class ReportViewModelTests: XCTestCase {

    private func makeSession(daysAgo: Int, duration: TimeInterval) -> RunSession {
        RunSession(
            startDate: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
            duration: duration
        )
    }

    func test_heroDuration_sumForWeek() {
        let vm = ReportViewModel()
        // Use sessions anchored to this week's start to avoid boundary issues
        let cal = Calendar.current
        let weekStart = cal.dateInterval(of: .weekOfYear, for: Date())!.start
        let withinWeek = RunSession(startDate: cal.date(byAdding: .hour, value: 2, to: weekStart)!, duration: 1200)
        let alsoWithinWeek = RunSession(startDate: cal.date(byAdding: .hour, value: 26, to: weekStart)!, duration: 900)
        let outsideWeek = RunSession(startDate: cal.date(byAdding: .day, value: -8, to: Date())!, duration: 600)
        vm.loadSessions([withinWeek, alsoWithinWeek, outsideWeek])
        vm.period = .week
        vm.currentOffset = 0
        XCTAssertEqual(vm.heroDuration, 2100, accuracy: 1)
    }

    func test_heroDuration_onlyTodayForDay() {
        let vm = ReportViewModel()
        let sessions = [
            makeSession(daysAgo: 0, duration: 1200),
            makeSession(daysAgo: 1, duration: 900),
        ]
        vm.loadSessions(sessions)
        vm.period = .day
        vm.currentOffset = 0
        XCTAssertEqual(vm.heroDuration, 1200, accuracy: 1)
    }

    func test_offsetNavigationMovesBackOneWeek() {
        let vm = ReportViewModel()
        vm.period = .week
        vm.currentOffset = 0
        let range0 = vm.dateRange
        vm.currentOffset = -1
        let range1 = vm.dateRange
        XCTAssertLessThan(range1.start, range0.start)
    }
}

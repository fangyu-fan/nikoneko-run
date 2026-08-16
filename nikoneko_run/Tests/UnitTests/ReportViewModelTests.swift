import XCTest
@testable import nikoneko

@MainActor
final class ReportViewModelTests: XCTestCase {

    private func makeSession(daysAgo: Int, duration: TimeInterval) -> RunSession {
        RunSession(
            startDate: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
            duration: duration
        )
    }

    func test_heroDuration_sumForWeek() {
        let vm = ReportViewModel()
        vm.period = .week
        vm.currentOffset = 0
        // Anchor to the same configurable week boundary used by the view model.
        let cal = Calendar.current
        let weekStart = vm.dateRange.start
        let withinWeek = RunSession(startDate: cal.date(byAdding: .hour, value: 2, to: weekStart)!, duration: 1200)
        let alsoWithinWeek = RunSession(startDate: cal.date(byAdding: .hour, value: 26, to: weekStart)!, duration: 900)
        let outsideWeek = RunSession(startDate: cal.date(byAdding: .day, value: -8, to: Date())!, duration: 600)
        vm.loadSessions([withinWeek, alsoWithinWeek, outsideWeek])
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

    func test_chartColorRatioUsesDailyGoalInsteadOfSelectedMetricMaximum() {
        let vm = ReportViewModel()
        vm.period = .week
        vm.dailyGoalMinutes = 20
        vm.selectedMetric = .distance

        let firstDay = vm.dateRange.start.addingTimeInterval(2 * 60 * 60)
        let secondDay = vm.dateRange.start.addingTimeInterval(26 * 60 * 60)
        vm.loadSessions([
            RunSession(startDate: firstDay, duration: 5 * 60, distance: 10_000),
            RunSession(startDate: secondDay, duration: 20 * 60, distance: 1_000),
        ])

        let distanceLeader = vm.chartBars.first { $0.value == 10_000 }
        let goalLeader = vm.chartBars.first { $0.value == 1_000 }

        XCTAssertEqual(distanceLeader?.goalRatio ?? -1, 0.25, accuracy: 0.001)
        XCTAssertEqual(goalLeader?.goalRatio ?? -1, 1.0, accuracy: 0.001)
    }
}

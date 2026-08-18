import XCTest
@testable import nikoneko

@MainActor
final class AppGroupBridgeTests: XCTestCase {

    func test_writeThenLoadSummariesRoundTrip() {
        let summaries = [
            DaySessionSummary(date: Date(), duration: 1200, completionRatio: 1.0, hrAvg: 120, steps: 2000),
            DaySessionSummary(date: Date(timeIntervalSinceNow: -86400), duration: 900, completionRatio: 0.75, hrAvg: 115, steps: 1500)
        ]
        AppGroupDefaults.writeSummaries(summaries)
        let loaded = AppGroupDefaults.loadSummaries()

        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].hrAvg, 120)
        XCTAssertEqual(loaded[1].steps, 1500)
    }

    func test_emptyDataReturnsEmptyArray() {
        AppGroupDefaults.shared.removeObject(forKey: "sessionSummaries")
        let loaded = AppGroupDefaults.loadSummaries()
        XCTAssertEqual(loaded.count, 0)
    }

    func test_sessionSyncAlsoWritesDailyGoal() {
        defer {
            AppGroupDefaults.shared.removeObject(forKey: "sessionSummaries")
            AppGroupDefaults.shared.removeObject(forKey: "dailyGoalMinutes")
        }

        let session = RunSession(startDate: Date(), duration: 15 * 60, steps: 1_500)
        AppGroupDefaults.writeSessionSummaries(from: [session], dailyGoalMinutes: 30)

        let summaries = AppGroupDefaults.loadSummaries()
        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries[0].completionRatio, 0.5, accuracy: 0.001)
        XCTAssertEqual(AppGroupDefaults.shared.integer(forKey: "dailyGoalMinutes"), 30)
    }
}

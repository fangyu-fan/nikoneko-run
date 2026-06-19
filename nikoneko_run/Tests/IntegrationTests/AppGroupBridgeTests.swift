import XCTest
@testable import nikoneko

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
}

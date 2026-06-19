import XCTest
@testable import nikoneko

@MainActor
final class HeartRateServiceTests: XCTestCase {

    func test_initialSourceIsNone() {
        let svc = HeartRateService()
        XCTAssertEqual(svc.source, .none)
    }

    func test_initialHRIsZero() {
        let svc = HeartRateService()
        XCTAssertEqual(svc.currentHR, 0)
    }

    func test_processSamplesUpdatesCurrentHR() {
        let svc = HeartRateService()
        svc.simulateSample(hr: 125)
        XCTAssertEqual(svc.currentHR, 125)
    }

    func test_processSamplesTracksMaxHR() {
        let svc = HeartRateService()
        svc.simulateSample(hr: 110)
        svc.simulateSample(hr: 135)
        svc.simulateSample(hr: 120)
        XCTAssertEqual(svc.maxHR, 135)
    }

    func test_processSamplesCalculatesAvgHR() {
        let svc = HeartRateService()
        svc.simulateSample(hr: 100)
        svc.simulateSample(hr: 120)
        XCTAssertEqual(svc.avgHR, 110)
    }
}

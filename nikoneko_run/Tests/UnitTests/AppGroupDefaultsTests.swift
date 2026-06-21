import XCTest
@testable import nikoneko

final class AppGroupDefaultsTests: XCTestCase {

    func test_daySessionSummaryEncodesAndDecodes() throws {
        let original = DaySessionSummary(
            date: Date(timeIntervalSince1970: 1_000_000),
            duration: 1260,
            completionRatio: 0.75,
            hrAvg: 118,
            steps: 2400
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DaySessionSummary.self, from: data)

        XCTAssertEqual(decoded.duration, original.duration)
        XCTAssertEqual(decoded.completionRatio, original.completionRatio, accuracy: 0.001)
        XCTAssertEqual(decoded.hrAvg, original.hrAvg)
        XCTAssertEqual(decoded.steps, original.steps)
    }

    func test_daySessionSummaryArrayEncodesAndDecodes() throws {
        let summaries = (0..<5).map { i in
            DaySessionSummary(
                date: Date(timeIntervalSince1970: Double(i) * 86400),
                duration: Double(i) * 600,
                completionRatio: Double(i) / 4.0,
                hrAvg: 110 + i,
                steps: 1000 * i
            )
        }
        let data = try JSONEncoder().encode(summaries)
        let decoded = try JSONDecoder().decode([DaySessionSummary].self, from: data)
        XCTAssertEqual(decoded.count, 5)
        XCTAssertEqual(decoded[2].hrAvg, 112)
    }

    func test_timerModeRawValues() {
        XCTAssertEqual(TimerMode.countdown.rawValue, "countdown")
        XCTAssertEqual(TimerMode.stopwatch.rawValue, "stopwatch")
    }

    func test_soundTypeRawValues() {
        XCTAssertEqual(SoundType.tap.rawValue, "tap")
        XCTAssertEqual(SoundType.bell.rawValue, "bell")
        XCTAssertEqual(SoundType.drum.rawValue, "drum")
        XCTAssertEqual(SoundType.wood.rawValue, "wood")
        XCTAssertEqual(SoundType.woodHi.rawValue, "woodHi")
        XCTAssertEqual(SoundType.woodLo.rawValue, "woodLo")
    }

    func test_widgetCellInfoRawValues() {
        XCTAssertEqual(WidgetCellInfo.duration.rawValue, "duration")
        XCTAssertEqual(WidgetCellInfo.heartRate.rawValue, "heartRate")
        XCTAssertEqual(WidgetCellInfo.completion.rawValue, "completion")
    }
}

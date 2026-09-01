import XCTest
@testable import nikoneko

final class CSVSessionCodecTests: XCTestCase {

    func testExportedCSVCanBeImported() throws {
        let startDate = try XCTUnwrap(
            ISO8601DateFormatter().date(from: "2026-09-01T04:18:00Z")
        )
        let session = RunSession(
            startDate: startDate,
            duration: 18 * 60,
            distance: 2_400,
            calories: 133,
            steps: 2_600,
            avgHR: 136,
            maxHR: 164,
            avgCadence: 166,
            bpm: 180
        )

        let exported = CSVSessionCodec.encode(sessions: [session])
        let records = try CSVSessionCodec.decode(exported)

        XCTAssertEqual(records.count, 1)
        let record = try XCTUnwrap(records.first)
        XCTAssertEqual(record.startDate, startDate)
        XCTAssertEqual(record.durationMinutes, 18)
        XCTAssertEqual(record.distanceKilometers, 2.4, accuracy: 0.001)
        XCTAssertEqual(record.calories, 133)
        XCTAssertEqual(record.steps, 2_600)
        XCTAssertEqual(record.avgHR, 136)
        XCTAssertEqual(record.maxHR, 164)
        XCTAssertEqual(record.bpm, 180)
    }

    func testImportAcceptsBOMAndWindowsLineEndings() throws {
        let csv = "\u{feff}\(CSVSessionCodec.header)\r\n"
            + "2026-09-01T04:18:00Z,18,2.40,133,2600,136,164,180\r\n"

        let records = try CSVSessionCodec.decode(csv)

        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].distanceKilometers, 2.4, accuracy: 0.001)
    }

    func testImportRejectsAnUnknownHeader() {
        XCTAssertThrowsError(
            try CSVSessionCodec.decode("Wrong,Header\n2026-09-01,18\n")
        )
    }
}

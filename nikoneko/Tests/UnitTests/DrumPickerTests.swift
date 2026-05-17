import XCTest
@testable import nikoneko

final class DrumPickerTests: XCTestCase {

    func test_stepsFromTranslation_positiveScrollDecreasesValue() {
        let steps = DrumPickerView.stepsFrom(translationY: -56, stepHeight: 28)
        XCTAssertEqual(steps, 2)
    }

    func test_stepsFromTranslation_negativeScrollIncreasesValue() {
        let steps = DrumPickerView.stepsFrom(translationY: 28, stepHeight: 28)
        XCTAssertEqual(steps, -1)
    }

    func test_clamp_staysWithinRange() {
        XCTAssertEqual(DrumPickerView.clamped(0, to: 1...999), 1)
        XCTAssertEqual(DrumPickerView.clamped(1000, to: 1...999), 999)
        XCTAssertEqual(DrumPickerView.clamped(15, to: 1...999), 15)
    }
}

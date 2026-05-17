import XCTest
@testable import nikoneko

final class BarColorTests: XCTestCase {

    private let theme = ThemeLibrary.obsidian

    func test_zeroRatioReturnsBar0() {
        let color = BarChartView.barColor(ratio: 0.0, theme: theme, t1: 10, t2: 50, t3: 90)
        XCTAssertEqual(color, theme.bar[0])
    }

    func test_atT1ThresholdReturnsBar1() {
        let color = BarChartView.barColor(ratio: 0.10, theme: theme, t1: 10, t2: 50, t3: 90)
        XCTAssertEqual(color, theme.bar[1])
    }

    func test_betweenT1andT2ReturnsBar2() {
        let color = BarChartView.barColor(ratio: 0.30, theme: theme, t1: 10, t2: 50, t3: 90)
        XCTAssertEqual(color, theme.bar[2])
    }

    func test_atT3ThresholdReturnsBar3() {
        let color = BarChartView.barColor(ratio: 0.90, theme: theme, t1: 10, t2: 50, t3: 90)
        XCTAssertEqual(color, theme.bar[3])
    }

    func test_fullCompletionReturnsBar4() {
        let color = BarChartView.barColor(ratio: 1.0, theme: theme, t1: 10, t2: 50, t3: 90)
        XCTAssertEqual(color, theme.bar[4])
    }
}

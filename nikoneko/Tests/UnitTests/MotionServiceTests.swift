import XCTest
@testable import nikoneko

final class MotionServiceTests: XCTestCase {

    func test_calorieEstimateFor2000Steps_65kg_170cm() {
        let cal = MotionService.estimateCalories(steps: 2000, weightKg: 65, heightCm: 170)
        XCTAssertEqual(cal, 95.0, accuracy: 5.0)
    }

    func test_calorieEstimateIsZeroForZeroSteps() {
        let cal = MotionService.estimateCalories(steps: 0, weightKg: 65, heightCm: 170)
        XCTAssertEqual(cal, 0.0, accuracy: 0.001)
    }

    func test_initialValuesAreZero() {
        let svc = MotionService()
        XCTAssertEqual(svc.steps, 0)
        XCTAssertEqual(svc.distance, 0)
        XCTAssertEqual(svc.calories, 0)
    }
}

import XCTest
@testable import nikoneko

@MainActor
final class TimerViewModelTests: XCTestCase {

    func test_initialStateIsIdle() {
        let vm = TimerViewModel()
        XCTAssertEqual(vm.state, .idle)
    }

    func test_remainingEqualsTargetWhenIdle() {
        let vm = TimerViewModel()
        vm.targetDuration = 900
        XCTAssertEqual(vm.remaining, 900)
    }

    func test_remainingNeverGoesBelowZero() {
        let vm = TimerViewModel()
        vm.targetDuration = 60
        vm.elapsed = 9999
        XCTAssertEqual(vm.remaining, 0)
    }

    func test_displayMinutesFromSeconds() {
        let vm = TimerViewModel()
        vm.targetDuration = 900  // 15 min
        XCTAssertEqual(vm.displayMinutes, 15)
    }

    func test_pauseTransitionsToPaused() {
        let vm = TimerViewModel()
        vm.state = .running
        vm.pause()
        XCTAssertEqual(vm.state, .paused)
    }

    func test_stopTransitionsToIdle() {
        let vm = TimerViewModel()
        vm.state = .running
        vm.forceStop()
        XCTAssertEqual(vm.state, .idle)
    }
}

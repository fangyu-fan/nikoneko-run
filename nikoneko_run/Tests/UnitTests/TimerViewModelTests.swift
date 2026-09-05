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

    func test_pauseCapturesElapsedTimeAndStopsAdvancing() async throws {
        let vm = TimerViewModel()
        vm.isCountdown = false
        vm.start(bpm: 180, characterId: "test", themeId: "test")

        try await Task.sleep(for: .milliseconds(80))
        vm.pause()
        let pausedElapsed = vm.elapsed

        XCTAssertGreaterThan(pausedElapsed, 0.05)
        try await Task.sleep(for: .milliseconds(80))
        XCTAssertEqual(vm.elapsed, pausedElapsed, accuracy: 0.01)
    }

    func test_countdownCanFinishAfterEnteringBackground() async throws {
        let vm = TimerViewModel()
        vm.isCountdown = true
        vm.targetDuration = 0.05
        vm.start(bpm: 180, characterId: "test", themeId: "test")

        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        try await Task.sleep(for: .milliseconds(600))

        XCTAssertEqual(vm.state, .idle)
        XCTAssertTrue(vm.countdownFinished)
        XCTAssertEqual(vm.elapsed, vm.targetDuration, accuracy: 0.001)
    }
}

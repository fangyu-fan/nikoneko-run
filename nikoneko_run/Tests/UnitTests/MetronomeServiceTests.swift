import XCTest
import AVFoundation
@testable import nikoneko

@MainActor
final class MetronomeServiceTests: XCTestCase {

    func test_initialBPMIs180() {
        let m = MetronomeService()
        XCTAssertEqual(m.bpm, 180)
    }

    func test_updateBPMChangesValue() {
        let m = MetronomeService()
        m.updateBPM(160)
        XCTAssertEqual(m.bpm, 160)
    }

    func test_stopSetsIsPlayingFalse() {
        let m = MetronomeService()
        m.stop()
        XCTAssertFalse(m.isPlaying)
    }

    func test_interruptionEndingDoesNotResumeAfterStop() {
        let m = MetronomeService()
        m.stop()

        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
                AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue,
            ]
        )

        XCTAssertFalse(m.isPlaying)
    }

    func test_beatIntervalAt180BPM() {
        let interval = MetronomeService.beatInterval(bpm: 180)
        XCTAssertEqual(interval, 60.0 / 180.0, accuracy: 0.0001)
    }

    func test_beatIntervalAt120BPM() {
        let interval = MetronomeService.beatInterval(bpm: 120)
        XCTAssertEqual(interval, 0.5, accuracy: 0.0001)
    }
}

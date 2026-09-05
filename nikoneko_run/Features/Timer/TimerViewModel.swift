import SwiftUI
import Combine

@MainActor
@Observable
final class TimerViewModel {
    enum State: Equatable { case idle, running, paused }

    var state: State = .idle
    var elapsed: TimeInterval = 0
    var targetDuration: TimeInterval = 15 * 60
    var selectedMinutes: Int = 15
    var completedSession: RunSession? = nil
    var countdownFinished: Bool = false

    private var timer: AnyCancellable?
    private var startDate: Date?
    private var activeSegmentStartedAt: Date?
    private var elapsedAtSegmentStart: TimeInterval = 0
    private var bgObserver: NSObjectProtocol?
    private var fgObserver: NSObjectProtocol?

    var remaining: TimeInterval { max(0, targetDuration - elapsed) }
    var isCountdown: Bool = true

    var displayMinutes: Int {
        isCountdown ? Int(remaining / 60) : Int(elapsed / 60)
    }

    var displaySeconds: Int {
        isCountdown ? Int(remaining) % 60 : Int(elapsed) % 60
    }

    init() {
        setupBackgroundHandlers()
    }

    private func setupBackgroundHandlers() {
        bgObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.state == .running else { return }
                self.refreshElapsed(at: Date())
            }
        }

        fgObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.state == .running else { return }
                self.refreshElapsed(at: Date())
                guard self.state == .running else { return }
                self.startTick()
            }
        }
    }

    func start(bpm: Int, characterId: String, themeId: String) {
        let now = Date()
        state = .running
        startDate = now
        elapsed = 0
        elapsedAtSegmentStart = 0
        activeSegmentStartedAt = now
        startTick()
    }

    func pause() {
        guard state == .running else { return }
        refreshElapsed(at: Date())
        guard state == .running else { return }
        state = .paused
        elapsedAtSegmentStart = elapsed
        activeSegmentStartedAt = nil
        timer?.cancel()
    }

    func resume() {
        guard state == .paused else { return }
        state = .running
        elapsedAtSegmentStart = elapsed
        activeSegmentStartedAt = Date()
        startTick()
    }

    func forceStop() {
        if state == .running {
            refreshElapsed(at: Date(), finishCountdown: false)
        }
        timer?.cancel()
        activeSegmentStartedAt = nil
        countdownFinished = true
        state = .idle
    }

    func stopAndSave(bpm: Int, characterId: String, themeId: String,
                     distance: Double, calories: Double, steps: Int,
                     avgHR: Int, maxHR: Int, avgCadence: Int) {
        countdownFinished = false
        if state == .running {
            refreshElapsed(at: Date(), finishCountdown: false)
        }
        timer?.cancel()
        activeSegmentStartedAt = nil
        let session = RunSession(
            startDate: startDate ?? Date(),
            duration: elapsed,
            distance: distance,
            calories: calories,
            steps: steps,
            avgHR: avgHR,
            maxHR: maxHR,
            avgCadence: avgCadence,
            bpm: bpm,
            characterId: characterId,
            themeId: themeId,
            mode: isCountdown ? .countdown : .stopwatch
        )
        Task { await HealthKitService.shared.writeSession(session) }
        completedSession = session
        state = .idle
    }

    private func startTick() {
        timer?.cancel()
        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                MainActor.assumeIsolated {
                    self?.refreshElapsed(at: now)
                }
            }
    }

    private func refreshElapsed(at now: Date, finishCountdown: Bool = true) {
        guard state == .running, let segmentStart = activeSegmentStartedAt else { return }
        elapsed = elapsedAtSegmentStart + max(0, now.timeIntervalSince(segmentStart))

        guard finishCountdown, isCountdown, elapsed >= targetDuration else { return }
        elapsed = targetDuration
        elapsedAtSegmentStart = elapsed
        activeSegmentStartedAt = nil
        timer?.cancel()
        countdownFinished = true
        state = .idle
    }
}

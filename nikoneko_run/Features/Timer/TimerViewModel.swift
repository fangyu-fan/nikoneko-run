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
    var showSummary: Bool = false
    var onSessionSaved: ((RunSession) -> Void)?

    private var timer: AnyCancellable?
    private var startDate: Date?
    private var backgroundedAt: Date?
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
            guard let self, self.state == .running else { return }
            // Record when we went to background so we can compensate on return
            self.backgroundedAt = Date()
        }

        fgObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self, self.state == .running, let bg = self.backgroundedAt else { return }
            // Add the time we spent in background to elapsed
            let backgroundDuration = Date().timeIntervalSince(bg)
            self.elapsed += backgroundDuration
            self.backgroundedAt = nil
            // Restart tick from current position
            self.startTick()
            // Check if countdown finished while in background
            if self.isCountdown && self.elapsed >= self.targetDuration {
                self.forceStop()
            }
        }
    }

    func start(bpm: Int, characterId: String, themeId: String) {
        state = .running
        startDate = Date()
        elapsed = 0
        backgroundedAt = nil
        startTick()
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        timer?.cancel()
    }

    func resume() {
        guard state == .paused else { return }
        state = .running
        startTick()
    }

    func forceStop() {
        state = .idle
        timer?.cancel()
    }

    func stopAndSave(bpm: Int, characterId: String, themeId: String,
                     distance: Double, calories: Double, steps: Int,
                     avgHR: Int, maxHR: Int, avgCadence: Int) {
        timer?.cancel()
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
        onSessionSaved?(session)
        Task { await HealthKitService.shared.writeSession(session) }
        state = .idle
        showSummary = true
    }

    private func startTick() {
        timer?.cancel()
        let capturedStart = Date()
        let capturedElapsed = elapsed
        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                guard let self, self.state == .running, self.backgroundedAt == nil else { return }
                self.elapsed = capturedElapsed + now.timeIntervalSince(capturedStart)
                if self.isCountdown && self.elapsed >= self.targetDuration {
                    self.forceStop()
                }
            }
    }
}

@preconcurrency import ActivityKit
import Foundation
import Observation

@Observable
@MainActor
final class LiveActivityService {
    nonisolated(unsafe) private var activity: Activity<NikoNekoLiveActivityAttributes>?

    func start(bpm: Int, target: TimeInterval, characterId: String, themeId: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let state = NikoNekoLiveActivityAttributes.ContentState(
            elapsed: 0, remaining: target, bpm: bpm,
            characterId: characterId, themeId: themeId, isCountdown: target > 0,
            hr: 0, distance: 0
        )
        activity = try? Activity.request(
            attributes: NikoNekoLiveActivityAttributes(),
            contentState: state,
            pushType: nil
        )
    }

    func update(elapsed: TimeInterval, remaining: TimeInterval, hr: Int = 0, distance: Double = 0) {
        guard let a = activity else { return }
        var s = a.contentState
        s.elapsed = elapsed
        s.remaining = remaining
        s.hr = hr
        s.distance = distance
        let newState = s
        Task { await a.update(using: newState) }
    }

    func end() {
        guard let a = activity else { return }
        activity = nil
        Task { await a.end(dismissalPolicy: .immediate) }
    }
}

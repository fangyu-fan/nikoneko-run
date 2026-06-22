import ActivityKit
import Foundation

struct NikoNekoLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var elapsed: TimeInterval
        var remaining: TimeInterval
        var bpm: Int
        var characterId: String
        var themeId: String
        var isCountdown: Bool
        var hr: Int
        var distance: Double
        var startDate: Date      // wall-clock start — used for live timer
        var targetDuration: TimeInterval  // 0 for stopwatch
    }
}

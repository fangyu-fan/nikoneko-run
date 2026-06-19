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
    }
}

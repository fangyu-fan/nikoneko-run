import Foundation
import SwiftData

enum TimerMode: String, Codable {
    case countdown, stopwatch
}

enum SoundType: String, Codable, CaseIterable {
    case tap, bell, drum, wood
}

enum TimeFormat: String, Codable {
    case plainMinutes, hhMM
}

enum AppLanguage: String, Codable {
    case english, traditionalChinese

    var code: String {
        switch self {
        case .english: return "en"
        case .traditionalChinese: return "zh-Hant"
        }
    }
}

enum WidgetCellInfo: String, Codable {
    case duration, heartRate, completion
}

@Model
final class RunSession {
    var id: UUID = UUID()
    var startDate: Date = Date()
    var duration: TimeInterval = 0
    var distance: Double = 0
    var calories: Double = 0
    var steps: Int = 0
    var avgHR: Int = 0
    var maxHR: Int = 0
    var avgCadence: Int = 0
    var bpm: Int = 180
    var characterId: String = "cat_a"
    var themeId: String = "obsidian"
    var modeRaw: String = TimerMode.countdown.rawValue
    var mode: TimerMode {
        get { TimerMode(rawValue: modeRaw) ?? .countdown }
        set { modeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        startDate: Date,
        duration: TimeInterval,
        distance: Double = 0,
        calories: Double = 0,
        steps: Int = 0,
        avgHR: Int = 0,
        maxHR: Int = 0,
        avgCadence: Int = 0,
        bpm: Int = 180,
        characterId: String = "cat_a",
        themeId: String = "obsidian",
        mode: TimerMode = .countdown
    ) {
        self.id = id
        self.startDate = startDate
        self.duration = duration
        self.distance = distance
        self.calories = calories
        self.steps = steps
        self.avgHR = avgHR
        self.maxHR = maxHR
        self.avgCadence = avgCadence
        self.bpm = bpm
        self.characterId = characterId
        self.themeId = themeId
        self.mode = mode
    }
}

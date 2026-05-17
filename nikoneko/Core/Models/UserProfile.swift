import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var defaultDuration: Int = 20
    var dailyGoalMinutes: Int = 20
    var defaultBPM: Int = 180
    var soundTypeRaw: String = SoundType.wood.rawValue
    var volumeLockEnabled: Bool = false
    var timerModeRaw: String = TimerMode.countdown.rawValue
    var timeDisplayFormatRaw: String = TimeFormat.plainMinutes.rawValue
    var showHR: Bool = true
    var showProgressRing: Bool = true
    var hapticEnabled: Bool = true
    var showDistance: Bool = true
    var showCalories: Bool = true
    var showSteps: Bool = true
    var activeThemeId: String = "obsidian"
    var activeCharacterId: String = "cat_a"
    var languageRaw: String = AppLanguage.english.rawValue
    var heightCm: Double = 170
    var weightKg: Double = 65
    var useHealthForBody: Bool = false
    var notificationsEnabled: Bool = false
    var notificationHour: Int = 7
    var notificationMinute: Int = 0
    var healthKitEnabled: Bool = false
    var iCloudEnabled: Bool = false

    // Computed enum accessors
    var soundType: SoundType {
        get { SoundType(rawValue: soundTypeRaw) ?? .tap }
        set { soundTypeRaw = newValue.rawValue }
    }
    var timerMode: TimerMode {
        get { TimerMode(rawValue: timerModeRaw) ?? .countdown }
        set { timerModeRaw = newValue.rawValue }
    }
    var timeDisplayFormat: TimeFormat {
        get { TimeFormat(rawValue: timeDisplayFormatRaw) ?? .plainMinutes }
        set { timeDisplayFormatRaw = newValue.rawValue }
    }
    var language: AppLanguage {
        get { AppLanguage(rawValue: languageRaw) ?? .english }
        set { languageRaw = newValue.rawValue }
    }

    init() {}
}

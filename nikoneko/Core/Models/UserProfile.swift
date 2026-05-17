import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var defaultDuration: Int
    var dailyGoalMinutes: Int
    var defaultBPM: Int
    var soundType: SoundType
    var volumeLockEnabled: Bool
    var timerMode: TimerMode
    var timeDisplayFormat: TimeFormat
    var showHR: Bool
    var showProgressRing: Bool
    var hapticEnabled: Bool
    var showDistance: Bool
    var showCalories: Bool
    var showSteps: Bool
    var activeThemeId: String
    var activeCharacterId: String
    var language: AppLanguage
    var heightCm: Double
    var weightKg: Double
    var useHealthForBody: Bool
    var notificationsEnabled: Bool
    var notificationHour: Int
    var notificationMinute: Int
    var healthKitEnabled: Bool
    var iCloudEnabled: Bool

    init() {
        self.id = UUID()
        self.defaultDuration = 20
        self.dailyGoalMinutes = 20
        self.defaultBPM = 180
        self.soundType = .tap
        self.volumeLockEnabled = false
        self.timerMode = .countdown
        self.timeDisplayFormat = .plainMinutes
        self.showHR = true
        self.showProgressRing = true
        self.hapticEnabled = true
        self.showDistance = true
        self.showCalories = true
        self.showSteps = true
        self.activeThemeId = "obsidian"
        self.activeCharacterId = "cat_a"
        self.language = .english
        self.heightCm = 170
        self.weightKg = 65
        self.useHealthForBody = false
        self.notificationsEnabled = false
        self.notificationHour = 7
        self.notificationMinute = 0
        self.healthKitEnabled = false
        self.iCloudEnabled = false
    }
}

import Foundation

enum DotState { case empty, partial, achieved }

@Observable
@MainActor
final class SummaryViewModel {
    let session: RunSession
    let streakDays: Int
    let thisWeekDots: [DotState]
    let totalHours: Double

    init(session: RunSession, summaries: [DaySessionSummary], goalMinutes: Int) {
        self.session = session
        self.streakDays = AppGroupDefaults.currentStreak(from: summaries, goalMinutes: goalMinutes)

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let daysFromStart = AppGroupDefaults.weekdayOffset(for: today)
        let weekStart = cal.date(byAdding: .day, value: -daysFromStart, to: today)!
        self.thisWeekDots = (0..<7).map { dayOffset in
            let day = cal.date(byAdding: .day, value: dayOffset, to: weekStart)!
            let dayTotal = summaries
                .filter { cal.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.duration }
            let goal = Double(goalMinutes) * 60
            if dayTotal >= goal { return .achieved }
            if dayTotal > 0 { return .partial }
            return .empty
        }

        self.totalHours = summaries.reduce(0) { $0 + $1.duration } / 3600
    }
}

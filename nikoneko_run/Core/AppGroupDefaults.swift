import Foundation

extension UserDefaults: @unchecked @retroactive Sendable {}

struct DaySessionSummary: Codable {
    let date: Date
    let duration: TimeInterval
    let completionRatio: Double
    let hrAvg: Int
    let steps: Int
    var calories: Double = 0
    var distance: Double = 0
}

enum AppGroupDefaults {
    static let suiteName = "group.com.fangyu.nikoneko-run-v1.0"

    static let shared = UserDefaults(suiteName: suiteName) ?? .standard

    static func writeSummaries(_ summaries: [DaySessionSummary]) {
        guard let data = try? JSONEncoder().encode(summaries) else { return }
        shared.set(data, forKey: "sessionSummaries")
        shared.set(Date(), forKey: "lastUpdated")
    }

    static func loadSummaries() -> [DaySessionSummary] {
        guard let data = shared.data(forKey: "sessionSummaries"),
              let summaries = try? JSONDecoder().decode([DaySessionSummary].self, from: data)
        else { return [] }
        return summaries
    }

}

extension AppGroupDefaults {
    // Week start preference: true = Monday (default), false = Sunday
    static var weekStartsOnMonday: Bool {
        get {
            // Default true if key not set
            guard shared.object(forKey: "weekStartsOnMonday") != nil else { return true }
            return shared.bool(forKey: "weekStartsOnMonday")
        }
        set {
            shared.set(newValue, forKey: "weekStartsOnMonday")
        }
    }

    // Returns Mon=0..Sun=6 offset for a given date, respecting the week start setting
    static func weekdayOffset(for date: Date) -> Int {
        let cal = Calendar.current
        let wd = cal.component(.weekday, from: date) // 1=Sun..7=Sat
        if weekStartsOnMonday {
            return wd == 1 ? 6 : wd - 2  // Mon=0..Sun=6
        } else {
            return wd - 1  // Sun=0..Sat=6
        }
    }
}

extension AppGroupDefaults {
    static func currentStreak(from summaries: [DaySessionSummary], goalMinutes: Int) -> Int {
        let goalSeconds = Double(goalMinutes) * 60
        let calendar = Calendar.current
        var streak = 0
        let today = calendar.startOfDay(for: Date())
        var checkDate = today

        for _ in 0..<365 {
            let dayTotal = summaries
                .filter { calendar.isDate($0.date, inSameDayAs: checkDate) }
                .reduce(0.0) { $0 + $1.duration }
            if dayTotal >= goalSeconds {
                streak += 1
            } else if checkDate < today {
                // A past day was missed — chain is broken
                break
            }
            // Today not yet met: continue checking previous days (streak-in-progress)
            guard let nextDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = nextDate
        }
        return streak
    }
}

import Foundation

struct DaySessionSummary: Codable {
    let date: Date
    let duration: TimeInterval
    let completionRatio: Double
    let hrAvg: Int
    let steps: Int
}

enum AppGroupDefaults {
    static let suiteName = "group.com.fangyu.nikoneko-run"

    static var shared: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

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

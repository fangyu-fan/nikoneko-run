import Foundation
import SwiftData

extension AppGroupDefaults {
    static func writeSessionSummaries(from sessions: [RunSession], dailyGoalMinutes: Int) {
        let summaries = sessions
            .sorted { $0.startDate > $1.startDate }
            .prefix(400)
            .map { session in
                DaySessionSummary(
                    date: session.startDate,
                    duration: session.duration,
                    completionRatio: min(1.0, session.duration / (Double(dailyGoalMinutes) * 60)),
                    hrAvg: session.avgHR,
                    steps: session.steps
                )
            }
        writeSummaries(Array(summaries))
    }
}

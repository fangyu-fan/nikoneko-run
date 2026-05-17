import Foundation
import SwiftData

@Observable
final class ReportViewModel {
    enum Period: String, CaseIterable { case day, week, month, year }
    enum Metric: String, CaseIterable { case distance, calories, steps, hrAvg, hrMax, cadence }

    var period: Period = .week
    var selectedMetric: Metric = .distance
    var currentOffset: Int = 0

    private var sessions: [RunSession] = []

    func loadSessions(_ sessions: [RunSession]) {
        self.sessions = sessions
    }

    var dateRange: (start: Date, end: Date) {
        let cal = Calendar.current
        let now = Date()
        switch period {
        case .day:
            let start = cal.startOfDay(for: cal.date(byAdding: .day, value: currentOffset, to: now)!)
            return (start, cal.date(byAdding: .day, value: 1, to: start)!)
        case .week:
            let weekStart = cal.dateInterval(of: .weekOfYear, for: now)!.start
            let start = cal.date(byAdding: .weekOfYear, value: currentOffset, to: weekStart)!
            return (start, cal.date(byAdding: .weekOfYear, value: 1, to: start)!)
        case .month:
            let monthStart = cal.dateInterval(of: .month, for: now)!.start
            let start = cal.date(byAdding: .month, value: currentOffset, to: monthStart)!
            return (start, cal.date(byAdding: .month, value: 1, to: start)!)
        case .year:
            let yearStart = cal.dateInterval(of: .year, for: now)!.start
            let start = cal.date(byAdding: .year, value: currentOffset, to: yearStart)!
            return (start, cal.date(byAdding: .year, value: 1, to: start)!)
        }
    }

    var heroDuration: TimeInterval {
        let range = dateRange
        return sessions
            .filter { $0.startDate >= range.start && $0.startDate < range.end }
            .reduce(0) { $0 + $1.duration }
    }

    var logItems: [RunSession] {
        let range = dateRange
        return sessions
            .filter { $0.startDate >= range.start && $0.startDate < range.end }
            .sorted { $0.startDate > $1.startDate }
    }

    var chartBars: [ChartBar] {
        let range = dateRange
        let cal = Calendar.current
        switch period {
        case .day:
            return (0..<24).map { hour in
                let hourSessions = sessions.filter {
                    cal.component(.hour, from: $0.startDate) == hour &&
                    cal.isDate($0.startDate, inSameDayAs: range.start)
                }
                return ChartBar(
                    label: "\(hour)",
                    value: metricValue(for: hourSessions),
                    isToday: hour == cal.component(.hour, from: Date())
                )
            }
        case .week:
            return (0..<7).map { dayOffset in
                let day = cal.date(byAdding: .day, value: dayOffset, to: range.start)!
                let daySessions = sessions.filter { cal.isDate($0.startDate, inSameDayAs: day) }
                let labels = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
                return ChartBar(
                    label: labels[dayOffset % 7],
                    value: metricValue(for: daySessions),
                    isToday: cal.isDateInToday(day)
                )
            }
        case .month:
            let daysInMonth = cal.range(of: .day, in: .month, for: range.start)!.count
            return (0..<daysInMonth).map { dayOffset in
                let day = cal.date(byAdding: .day, value: dayOffset, to: range.start)!
                let daySessions = sessions.filter { cal.isDate($0.startDate, inSameDayAs: day) }
                return ChartBar(
                    label: "\(dayOffset + 1)",
                    value: metricValue(for: daySessions),
                    isToday: cal.isDateInToday(day)
                )
            }
        case .year:
            return (0..<12).map { monthOffset in
                let month = cal.date(byAdding: .month, value: monthOffset, to: range.start)!
                let monthInterval = cal.dateInterval(of: .month, for: month)!
                let monthSessions = sessions.filter {
                    $0.startDate >= monthInterval.start && $0.startDate < monthInterval.end
                }
                let labels = ["J","F","M","A","M","J","J","A","S","O","N","D"]
                return ChartBar(
                    label: labels[monthOffset],
                    value: metricValue(for: monthSessions),
                    isToday: cal.isDate(month, equalTo: Date(), toGranularity: .month)
                )
            }
        }
    }

    private func metricValue(for sessions: [RunSession]) -> Double {
        switch selectedMetric {
        case .distance: return sessions.reduce(0) { $0 + $1.distance }
        case .calories:  return sessions.reduce(0) { $0 + $1.calories }
        case .steps:     return Double(sessions.reduce(0) { $0 + $1.steps })
        case .hrAvg:     return sessions.isEmpty ? 0 : Double(sessions.reduce(0) { $0 + $1.avgHR }) / Double(sessions.count)
        case .hrMax:     return Double(sessions.map(\.maxHR).max() ?? 0)
        case .cadence:   return sessions.isEmpty ? 0 : Double(sessions.reduce(0) { $0 + $1.avgCadence }) / Double(sessions.count)
        }
    }
}

struct ChartBar {
    let label: String
    let value: Double
    let isToday: Bool
}

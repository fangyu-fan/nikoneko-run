import Foundation
import SwiftData

@Observable
final class ReportViewModel {
    enum Period: String, CaseIterable { case day, week, month, year }
    enum Metric: String, CaseIterable { case distance, calories, steps, hrAvg, hrMax, cadence }

    var period: Period = .week
    var selectedMetric: Metric = .distance
    var currentOffset: Int = 0

    var sessions: [RunSession] = []

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

    // MARK: - UI Helpers

    var dateRangeLabel: String {
        let fmt = DateFormatter()
        let range = dateRange
        switch period {
        case .day:
            fmt.dateFormat = "yyyy/MM/dd"
            return fmt.string(from: range.start)
        case .week:
            fmt.dateFormat = "MM/dd"
            let s = fmt.string(from: range.start)
            let e = fmt.string(from: Calendar.current.date(byAdding: .day, value: -1, to: range.end)!)
            return "\(s) ~ \(e)"
        case .month:
            fmt.dateFormat = "yyyy/MM"
            return fmt.string(from: range.start)
        case .year:
            fmt.dateFormat = "yyyy"
            return fmt.string(from: range.start)
        }
    }

    func metricIcon(_ metric: Metric) -> String {
        switch metric {
        case .distance: return "⊙"
        case .calories:  return "△"
        case .steps:     return "⊞"
        case .hrAvg:     return "♥"
        case .hrMax:     return "♥"
        case .cadence:   return "♩"
        }
    }

    func metricLabel(_ metric: Metric) -> String {
        switch metric {
        case .distance: return "Distance"
        case .calories:  return "Calories"
        case .steps:     return "Steps"
        case .hrAvg:     return "Avg HR"
        case .hrMax:     return "Max HR"
        case .cadence:   return "Cadence"
        }
    }

    func metricValueString(_ metric: Metric) -> String {
        let range = dateRange
        let inRange = sessions.filter { $0.startDate >= range.start && $0.startDate < range.end }
        switch metric {
        case .distance:
            let km = inRange.reduce(0.0) { $0 + $1.distance } / 1000
            return km >= 100 ? String(format: "%.0f", km) : String(format: "%.1f", km)
        case .calories:
            let cal = inRange.reduce(0.0) { $0 + $1.calories }
            return cal >= 1000 ? String(format: "%.1fk", cal / 1000) : "\(Int(cal))"
        case .steps:
            let s = inRange.reduce(0) { $0 + $1.steps }
            return s >= 1000 ? String(format: "%.1fk", Double(s) / 1000) : "\(s)"
        case .hrAvg:
            guard !inRange.isEmpty else { return "—" }
            return "\(inRange.reduce(0) { $0 + $1.avgHR } / inRange.count)"
        case .hrMax:
            let mx = inRange.map(\.maxHR).max() ?? 0
            return mx > 0 ? "\(mx)" : "—"
        case .cadence:
            guard !inRange.isEmpty else { return "—" }
            return "\(inRange.reduce(0) { $0 + $1.avgCadence } / inRange.count)"
        }
    }

    func logSecondaryValue(session: RunSession) -> String {
        switch selectedMetric {
        case .distance:
            return String(format: "%.1f km", session.distance / 1000)
        case .calories:
            return "\(Int(session.calories)) cal"
        case .steps:
            return "\(session.steps) steps"
        case .hrAvg:
            return session.avgHR > 0 ? "HR \(session.avgHR)" : ""
        case .hrMax:
            return session.maxHR > 0 ? "HR max \(session.maxHR)" : ""
        case .cadence:
            return session.avgCadence > 0 ? "\(session.avgCadence) spm" : ""
        }
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

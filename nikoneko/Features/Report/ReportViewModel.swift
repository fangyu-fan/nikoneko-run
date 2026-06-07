import Foundation
import SwiftData

@Observable
final class ReportViewModel {
    enum Period: String, CaseIterable { case day, week, month, year }
    enum Metric: String, CaseIterable { case duration, distance, calories, steps, hrAvg, hrMax, count }

    var period: Period = .week
    var selectedMetric: Metric = .duration
    var currentOffset: Int = 0
    var isZh: Bool = false  // injected by View, drives weekday label language

    var yearStartWeekday: Int {
        let cal = Calendar(identifier: .gregorian)
        let range = dateRange
        let wd = cal.component(.weekday, from: range.start)
        return (wd + 5) % 7  // Mon=0 … Sun=6
    }

    var sessions: [RunSession] = []

    func loadSessions(_ sessions: [RunSession]) {
        self.sessions = sessions
    }

    var dateRange: (start: Date, end: Date) {
        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)
        switch period {
        case .day:
            let base = cal.startOfDay(for: now)
            let start = cal.date(byAdding: .day, value: currentOffset, to: base) ?? today
            let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
            return (start, end)
        case .week:
            // ISO week: always starts Monday (weekday 2). Compute this week's Monday.
            let isoWd = cal.component(.weekday, from: today)  // 1=Sun..7=Sat
            let daysFromMon = isoWd == 1 ? 6 : isoWd - 2      // Mon=0..Sun=6
            let thisMonday = cal.date(byAdding: .day, value: -daysFromMon, to: today) ?? today
            let start = cal.date(byAdding: .day, value: currentOffset * 7, to: thisMonday) ?? today
            let end = cal.date(byAdding: .day, value: 7, to: start) ?? start
            return (start, end)
        case .month:
            let monthStart = cal.dateInterval(of: .month, for: now)?.start ?? today
            let start = cal.date(byAdding: .month, value: currentOffset, to: monthStart) ?? today
            let end = cal.date(byAdding: .month, value: 1, to: start) ?? start
            return (start, end)
        case .year:
            let yearStart = cal.dateInterval(of: .year, for: now)?.start ?? today
            let start = cal.date(byAdding: .year, value: currentOffset, to: yearStart) ?? today
            let end = cal.date(byAdding: .year, value: 1, to: start) ?? start
            return (start, end)
        }
    }

    var heroDuration: TimeInterval {
        let range = dateRange
        return sessions
            .filter { $0.startDate >= range.start && $0.startDate < range.end }
            .reduce(0) { $0 + $1.duration }
    }

    var periodSessionCount: Int {
        let range = dateRange
        return sessions.filter { $0.startDate >= range.start && $0.startDate < range.end }.count
    }

    var currentStreak: Int {
        let cal = Calendar.current
        var streak = 0
        var checkDate = cal.startOfDay(for: Date())
        for _ in 0..<365 {
            let hasSessions = sessions.contains { cal.isDate($0.startDate, inSameDayAs: checkDate) }
            if hasSessions {
                streak += 1
            } else if checkDate < cal.startOfDay(for: Date()) {
                break
            }
            guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
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
            let endDay = Calendar.current.date(byAdding: .day, value: -1, to: range.end) ?? range.start
            let e = fmt.string(from: endDay)
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
        case .duration:  return "timer"
        case .distance:  return "location.circle"
        case .calories:  return "flame"
        case .steps:     return "shoeprints.fill"
        case .hrAvg:     return "heart"
        case .hrMax:     return "heart"
        case .count:     return "figure.run"
        }
    }

    func metricUnit(_ metric: Metric) -> String {
        switch metric {
        case .duration:  return NSLocalizedString("report.unit.min", comment: "")
        case .distance:  return NSLocalizedString("session.unit.km", comment: "")
        case .calories:  return NSLocalizedString("session.unit.kcal", comment: "")
        case .steps:     return NSLocalizedString("report.metric.steps", comment: "")
        case .hrAvg:     return NSLocalizedString("session.unit.bpm", comment: "")
        case .hrMax:     return NSLocalizedString("session.unit.bpm", comment: "")
        case .count:     return NSLocalizedString("report.metric.count", comment: "")
        }
    }

    func metricLabel(_ metric: Metric) -> String {
        switch metric {
        case .duration:  return NSLocalizedString("report.metric.duration", comment: "")
        case .distance:  return NSLocalizedString("report.metric.distance", comment: "")
        case .calories:  return NSLocalizedString("report.metric.calories", comment: "")
        case .steps:     return NSLocalizedString("report.metric.steps", comment: "")
        case .hrAvg:     return NSLocalizedString("report.metric.avgHR", comment: "")
        case .hrMax:     return NSLocalizedString("report.metric.maxHR", comment: "")
        case .count:     return NSLocalizedString("report.metric.count", comment: "")
        }
    }

    func metricValueString(_ metric: Metric) -> String {
        let range = dateRange
        let inRange = sessions.filter { $0.startDate >= range.start && $0.startDate < range.end }
        switch metric {
        case .duration:
            let mins = Int(inRange.reduce(0) { $0 + $1.duration } / 60)
            return mins >= 60 ? String(format: "%.1f", Double(mins) / 60) : "\(mins)"
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
            let withHR = inRange.filter { $0.avgHR > 0 }
            guard !withHR.isEmpty else { return "—" }
            let avg = Double(withHR.reduce(0) { $0 + $1.avgHR }) / Double(withHR.count)
            return "\(Int(avg.rounded()))"
        case .hrMax:
            let mx = inRange.map(\.maxHR).max() ?? 0
            return mx > 0 ? "\(mx)" : "—"
        case .count:
            return "\(inRange.count)"
        }
    }

    func logSecondaryValue(session: RunSession) -> String {
        switch selectedMetric {
        case .duration:
            return ""
        case .distance:
            return String(format: "%.1f km", session.distance / 1000)
        case .calories:
            return "\(Int(session.calories)) kcal"
        case .steps:
            return "\(session.steps) steps"
        case .hrAvg:
            return session.avgHR > 0 ? "HR \(session.avgHR)" : ""
        case .hrMax:
            return session.maxHR > 0 ? "HR max \(session.maxHR)" : ""
        case .count:
            return ""
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
                let v = metricValue(for: hourSessions)
                return ChartBar(label: "\(hour)", value: v,
                    isToday: hour == cal.component(.hour, from: Date()),
                    displayValue: formatBarValue(v))
            }
        case .week:
            // Use fixed labels to avoid locale-dependent prefix bugs (e.g. "週一".prefix(1) == "週")
            let enLabels = ["M","T","W","T","F","S","S"]
            let zhLabels = ["一","二","三","四","五","六","日"]
            let labels = isZh ? zhLabels : enLabels
            return (0..<7).map { dayOffset in
                let day = cal.date(byAdding: .day, value: dayOffset, to: range.start) ?? range.start
                let daySessions = sessions.filter { cal.isDate($0.startDate, inSameDayAs: day) }
                let isoWd = cal.component(.weekday, from: day)  // 1=Sun..7=Sat
                let monIdx = isoWd == 1 ? 6 : isoWd - 2        // Mon=0..Sun=6
                let label = labels[monIdx]
                let v2 = metricValue(for: daySessions)
                return ChartBar(label: label, value: v2,
                    isToday: cal.isDateInToday(day),
                    displayValue: formatBarValue(v2))
            }
        case .month:
            let daysInMonth = cal.range(of: .day, in: .month, for: range.start)?.count ?? 30
            return (0..<daysInMonth).map { dayOffset in
                let day = cal.date(byAdding: .day, value: dayOffset, to: range.start) ?? range.start
                let daySessions = sessions.filter { cal.isDate($0.startDate, inSameDayAs: day) }
                let v3 = metricValue(for: daySessions)
                return ChartBar(label: "\(dayOffset + 1)", value: v3,
                    isToday: cal.isDateInToday(day),
                    displayValue: formatBarValue(v3))
            }
        case .year:
            let daysInYear = cal.range(of: .day, in: .year, for: range.start)?.count ?? 365
            return (0..<daysInYear).map { dayOffset in
                let day = cal.date(byAdding: .day, value: dayOffset, to: range.start) ?? range.start
                let daySessions = sessions.filter { cal.isDate($0.startDate, inSameDayAs: day) }
                let dayNum = cal.component(.day, from: day)
                let v4 = metricValue(for: daySessions)
                return ChartBar(label: "\(dayNum)", value: v4,
                    isToday: cal.isDateInToday(day),
                    displayValue: formatBarValue(v4))
            }
        }
    }

    private func formatBarValue(_ v: Double) -> String {
        guard v > 0 else { return "—" }
        let unit = metricUnit(selectedMetric)
        switch selectedMetric {
        case .duration:
            return "\(Int(v)) \(unit)"
        case .distance:
            let km = v / 1000
            return "\(km >= 100 ? String(format: "%.0f", km) : String(format: "%.1f", km)) \(unit)"
        case .calories:
            return "\(v >= 1000 ? String(format: "%.1fk", v/1000) : "\(Int(v))") \(unit)"
        case .steps:
            return "\(v >= 1000 ? String(format: "%.1fk", v/1000) : "\(Int(v))") \(unit)"
        case .hrAvg, .hrMax:
            return "\(Int(v.rounded())) \(unit)"
        case .count:
            return "\(Int(v)) sessions"
        }
    }

    private func metricValue(for sessions: [RunSession]) -> Double {
        switch selectedMetric {
        case .duration:  return sessions.reduce(0) { $0 + $1.duration } / 60
        case .distance:  return sessions.reduce(0) { $0 + $1.distance }
        case .calories:  return sessions.reduce(0) { $0 + $1.calories }
        case .steps:     return Double(sessions.reduce(0) { $0 + $1.steps })
        case .hrAvg:     return sessions.isEmpty ? 0 : Double(sessions.reduce(0) { $0 + $1.avgHR }) / Double(sessions.count)
        case .hrMax:     return Double(sessions.map(\.maxHR).max() ?? 0)
        case .count:     return Double(sessions.count)
        }
    }
}

struct ChartBar {
    let label: String
    let value: Double
    let isToday: Bool
    var displayValue: String = ""  // formatted value + unit for tooltip
}

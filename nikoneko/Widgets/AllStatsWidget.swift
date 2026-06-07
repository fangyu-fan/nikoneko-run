import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Intent

struct AllStatsWidgetIntent: AppIntent, WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "All Stats"
    @Parameter(title: "Period", default: .week) var period: TimePeriod
}

// MARK: - Entry

struct AllStatsEntry: TimelineEntry {
    let date: Date
    let period: TimePeriod
    // Hero: duration
    let durationFormatted: String  // "9.3" or "120"
    let durationUnit: String       // "hrs" or "min"
    // Summary grid (6 cells)
    let distanceKm: String         // "70.2"
    let caloriesStr: String        // "3.9k" or "912"
    let stepsStr: String           // "70.2k" or "4200"
    let avgHR: String              // "145" or "—"
    let maxHR: String              // "171" or "—"
    let runsStr: String            // "21"
    let theme: ThemeTokens
}

// MARK: - Provider

struct AllStatsProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> AllStatsEntry {
        AllStatsEntry(
            date: Date(), period: .week,
            durationFormatted: "9.3", durationUnit: "hrs",
            distanceKm: "70.2", caloriesStr: "3.9k",
            stepsStr: "70.2k", avgHR: "145", maxHR: "171",
            runsStr: "21", theme: ThemeLibrary.moss
        )
    }

    func snapshot(for configuration: AllStatsWidgetIntent, in context: Context) async -> AllStatsEntry {
        entry(for: configuration)
    }

    func timeline(for configuration: AllStatsWidgetIntent, in context: Context) async -> Timeline<AllStatsEntry> {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        return Timeline(entries: [entry(for: configuration)], policy: .after(next))
    }

    private func entry(for configuration: AllStatsWidgetIntent) -> AllStatsEntry {
        let theme = WidgetTheme.load(for: "widget.allStats.themeId")
        let summaries = AppGroupDefaults.loadSummaries()
        let filtered = Self.filter(summaries, for: configuration.period)

        // Duration
        let totalSeconds = filtered.reduce(0.0) { $0 + $1.duration }
        let totalMinutes = totalSeconds / 60.0
        let durationFormatted: String
        let durationUnit: String
        if totalMinutes >= 60 {
            durationFormatted = String(format: "%.1f", totalMinutes / 60.0)
            durationUnit = "hrs"
        } else {
            durationFormatted = "\(Int(totalMinutes))"
            durationUnit = "min"
        }

        // Distance (estimated from steps: 1500 steps ≈ 1 km)
        let totalSteps = filtered.reduce(0) { $0 + $1.steps }
        let distanceKm = String(format: "%.1f", Double(totalSteps) / 1500.0)

        // Calories (~7 kcal/min)
        let totalCalories = Int(totalMinutes) * 7
        let caloriesStr: String
        if totalCalories >= 1000 {
            caloriesStr = String(format: "%.1fk", Double(totalCalories) / 1000.0)
        } else {
            caloriesStr = "\(totalCalories)"
        }

        // Steps formatted
        let stepsStr: String
        if totalSteps >= 1000 {
            stepsStr = String(format: "%.1fk", Double(totalSteps) / 1000.0)
        } else {
            stepsStr = "\(totalSteps)"
        }

        // HR
        let hrSamples = filtered.filter { $0.hrAvg > 0 }.map { $0.hrAvg }
        let avgHR: String
        let maxHR: String
        if hrSamples.isEmpty {
            avgHR = "—"
            maxHR = "—"
        } else {
            let avg = hrSamples.reduce(0, +) / hrSamples.count
            avgHR = "\(avg)"
            maxHR = "\(hrSamples.max()!)"
        }

        // Runs
        let runsStr = "\(filtered.count)"

        return AllStatsEntry(
            date: Date(),
            period: configuration.period,
            durationFormatted: durationFormatted,
            durationUnit: durationUnit,
            distanceKm: distanceKm,
            caloriesStr: caloriesStr,
            stepsStr: stepsStr,
            avgHR: avgHR,
            maxHR: maxHR,
            runsStr: runsStr,
            theme: theme
        )
    }

    private static func filter(_ summaries: [DaySessionSummary], for period: TimePeriod) -> [DaySessionSummary] {
        let calendar = Calendar.current
        let now = Date()
        switch period {
        case .today:
            return summaries.filter { calendar.isDateInToday($0.date) }
        case .week:
            let cutoff = calendar.date(byAdding: .day, value: -7, to: now)!
            return summaries.filter { $0.date >= cutoff }
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: now)
            guard let startOfMonth = calendar.date(from: comps) else { return [] }
            return summaries.filter { $0.date >= startOfMonth }
        case .year:
            let comps = calendar.dateComponents([.year], from: now)
            guard let startOfYear = calendar.date(from: comps) else { return [] }
            return summaries.filter { $0.date >= startOfYear }
        }
    }
}

// MARK: - View

struct AllStatsWidgetView: View {
    let entry: AllStatsEntry

    private var periodLabel: String {
        switch entry.period {
        case .today: return "TODAY"
        case .week:  return "THIS WEEK"
        case .month: return "THIS MONTH"
        case .year:  return "THIS YEAR"
        }
    }

    private var rightLabel: String {
        let cal = Calendar.current
        let now = entry.date
        switch entry.period {
        case .today:
            let f = DateFormatter()
            f.dateFormat = "MMMM d"
            return f.string(from: now)  // MMMM → Title Case: June 6
        case .week:
            let weekday = cal.component(.weekday, from: now)
            let daysFromMon = weekday == 1 ? 6 : weekday - 2
            guard let monday = cal.date(byAdding: .day, value: -daysFromMon, to: cal.startOfDay(for: now)),
                  let sunday = cal.date(byAdding: .day, value: 6, to: monday) else { return "" }
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            let mComps = cal.dateComponents([.month], from: monday)
            let sComps = cal.dateComponents([.month], from: sunday)
            if mComps.month == sComps.month {
                let dayF = DateFormatter()
                dayF.dateFormat = "d"
                return "\(f.string(from: monday).uppercased()) – \(dayF.string(from: sunday))"
            } else {
                return "\(f.string(from: monday).uppercased()) – \(f.string(from: sunday).uppercased())"
            }
        case .month:
            let f = DateFormatter()
            f.dateFormat = "MMMM yyyy"
            return f.string(from: now)  // MMMM → Title Case: June 2026
        case .year:
            let f = DateFormatter()
            f.dateFormat = "yyyy"
            return f.string(from: now)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("NIKONEKO RUN")
                    .font(.system(size: 10)).tracking(0.8)
                    .foregroundColor(entry.theme.textMid)
                Spacer()
                Text(rightLabel)
                    .font(.system(size: 10)).tracking(0.8)
                    .foregroundColor(entry.theme.textMid)
            }
            .padding(.bottom, 8)

            // Hero: duration
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("total")
                    .font(.system(size: 18, weight: .ultraLight)).foregroundColor(entry.theme.accent)
                Text(entry.durationFormatted)
                    .font(.system(size: 72, weight: .ultraLight)).foregroundColor(entry.theme.accent)
                    .monospacedDigit().kerning(-3).minimumScaleFactor(0.5).lineLimit(1)
                Text(entry.durationUnit)
                    .font(.system(size: 20, weight: .ultraLight)).foregroundColor(entry.theme.accent)
            }
            .padding(.bottom, 8)

            // Summary grid
            VStack(alignment: .leading, spacing: 6) {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 3),
                    spacing: 5
                ) {
                    summaryCell(value: entry.distanceKm,  unit: "km",   icon: "location.circle",  label: "Distance")
                    summaryCell(value: entry.caloriesStr, unit: "kcal", icon: "flame",             label: "Calories")
                    summaryCell(value: entry.stepsStr,    unit: "",     icon: "shoeprints.fill",   label: "Steps")
                    summaryCell(value: entry.avgHR,       unit: entry.avgHR == "—" ? "" : "bpm",  icon: "heart",     label: "Avg HR")
                    summaryCell(value: entry.maxHR,       unit: entry.maxHR == "—" ? "" : "bpm",  icon: "heart",     label: "Max HR")
                    summaryCell(value: entry.runsStr,     unit: "runs", icon: "figure.run",        label: "Runs")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(10)
        .containerBackground(entry.theme.bg, for: .widget)
    }

    private func summaryCell(value: String, unit: String, icon: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundColor(entry.theme.text)
                    .monospacedDigit()
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 12))
                        .foregroundColor(entry.theme.text)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(entry.theme.text)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(entry.theme.text)
            }
            .padding(.top, 4)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(entry.theme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(entry.theme.accentDim, lineWidth: 0.5))
        .cornerRadius(14)
    }
}

// MARK: - Preview

#if DEBUG
#Preview(as: .systemLarge) {
    AllStatsWidget()
} timeline: {
    AllStatsEntry(
        date: .now,
        period: .week,
        durationFormatted: "3.5", durationUnit: "hrs",
        distanceKm: "14.2", caloriesStr: "1.4k",
        stepsStr: "21.3k", avgHR: "142", maxHR: "168",
        runsStr: "5", theme: ThemeLibrary.moss
    )
    AllStatsEntry(
        date: .now,
        period: .month,
        durationFormatted: "9.3", durationUnit: "hrs",
        distanceKm: "52.1", caloriesStr: "3.9k",
        stepsStr: "70.2k", avgHR: "145", maxHR: "171",
        runsStr: "18", theme: ThemeLibrary.moss
    )
    AllStatsEntry(
        date: .now,
        period: .today,
        durationFormatted: "24", durationUnit: "min",
        distanceKm: "2.8", caloriesStr: "168",
        stepsStr: "3.2k", avgHR: "—", maxHR: "—",
        runsStr: "1", theme: ThemeLibrary.moss
    )
}
#endif

// MARK: - Widget

struct AllStatsWidget: Widget {
    let kind = "AllStatsWidget"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: AllStatsWidgetIntent.self, provider: AllStatsProvider()) { entry in
            AllStatsWidgetView(entry: entry)
        }
        .configurationDisplayName("All Stats")
        .description("Full summary of your training.")
        .supportedFamilies([.systemLarge])
    }
}

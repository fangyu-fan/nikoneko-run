import SwiftUI
import SwiftData

struct SummaryView: View {
    let session: RunSession
    @Query private var profiles: [UserProfile]
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    @Environment(\.dismiss) private var dismiss

    private var theme: ThemeTokens { themeManager.current }
    private var goalMinutes: Int { profiles.first?.dailyGoalMinutes ?? 20 }

    @State private var vm: SummaryViewModel?

    private var durationMins: Int { Int(session.duration / 60) }

    private var timeRange: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        let end = session.startDate.addingTimeInterval(session.duration)
        return "\(f.string(from: session.startDate)) – \(f.string(from: end))"
    }

    private var dateLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMMM d, yyyy"
        return f.string(from: session.startDate)
    }

    private var stepsStr: String {
        session.steps >= 1000
            ? String(format: "%.1fk", Double(session.steps) / 1000)
            : "\(session.steps)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateLabel).font(.system(size: 16)).foregroundColor(theme.text)
                    Text(timeRange).font(.system(size: 13)).foregroundColor(theme.textDim)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(theme.textDim)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 12)

            // Duration hero
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(lm.L("session.total")) ")
                    .font(.system(size: 22))
                    .foregroundColor(theme.text)
                Text("\(durationMins)")
                    .font(.system(size: 72, weight: .ultraLight))
                    .kerning(-3)
                    .foregroundColor(theme.text)
                    .monospacedDigit()
                Text(" \(lm.L("session.unit.min"))")
                    .font(.system(size: 22))
                    .foregroundColor(theme.text)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 4)

            Text(lm.L("session.summary").uppercased())
                .font(.system(size: 10)).tracking(0.8).foregroundColor(theme.textDim)
                .padding(.horizontal, 20).padding(.bottom, 12)

            // Stat grid
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 4
            ) {
                statCard("location.circle",
                         String(format: "%.1f", session.distance / 1000),
                         lm.L("session.unit.km"),
                         lm.L("session.stat.distance"))
                statCard("flame",
                         "\(Int(session.calories))",
                         lm.L("session.unit.kcal"),
                         lm.L("session.stat.calories"))
                statCard("shoeprints.fill",
                         stepsStr, "",
                         lm.L("session.stat.steps"))
                statCard("heart",
                         session.avgHR > 0 ? "\(session.avgHR)" : "—",
                         session.avgHR > 0 ? lm.L("session.unit.bpm") : "",
                         lm.L("session.stat.avgHR"))
                statCard("heart",
                         session.maxHR > 0 ? "\(session.maxHR)" : "—",
                         session.maxHR > 0 ? lm.L("session.unit.bpm") : "",
                         lm.L("session.stat.maxHR"))
                statCard("metronome",
                         session.avgCadence > 0 ? "\(session.avgCadence)" : "—",
                         session.avgCadence > 0 ? lm.L("session.unit.spm") : "",
                         lm.L("session.stat.cadence"))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // Streak chip
            if let vm {
                streakChip(vm)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }

            Spacer()
        }
        .background(theme.bg.ignoresSafeArea())
        .onAppear {
            let summaries = AppGroupDefaults.loadSummaries()
            vm = SummaryViewModel(session: session, summaries: summaries, goalMinutes: goalMinutes)
        }
    }

    private func statCard(_ icon: String, _ value: String, _ unit: String, _ label: String) -> some View {
        GeometryReader { _ in
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundColor(theme.text)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 11))
                            .foregroundColor(theme.text)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                HStack(spacing: 4) {
                    Image(systemName: icon).font(.system(size: 11)).foregroundColor(theme.text)
                    Text(label).font(.system(size: 11)).foregroundColor(theme.text)
                }
                .padding(.top, 4)
            }
            .padding(12)
        }
        .aspectRatio(1, contentMode: .fit)
        .background(theme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.accentDim, lineWidth: 0.5))
        .cornerRadius(14)
    }

    private func streakChip(_ vm: SummaryViewModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(vm.streakDays)")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundColor(theme.accent)
                    .monospacedDigit()
                    .kerning(-1.5)
                Text(lm.L("summary.streak"))
                    .font(.system(size: 11))
                    .foregroundColor(theme.bar[1])
            }
            Spacer()
            HStack(spacing: 5) {
                ForEach(vm.thisWeekDots.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(dotColor(vm.thisWeekDots[i]))
                        .frame(width: 10, height: 10)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(theme.accentDim)
        .cornerRadius(14)
    }

    private func dotColor(_ state: DotState) -> Color {
        switch state {
        case .empty:    return theme.bar[0]
        case .partial:  return theme.bar[2]
        case .achieved: return theme.bar[4]
        }
    }
}

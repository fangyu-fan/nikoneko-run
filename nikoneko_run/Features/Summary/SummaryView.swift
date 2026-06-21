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

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()
            if let vm {
                summaryContent(vm)
            }
        }
        .onAppear {
            let summaries = AppGroupDefaults.loadSummaries()
            vm = SummaryViewModel(session: session, summaries: summaries, goalMinutes: goalMinutes)
        }
    }

    private func summaryContent(_ vm: SummaryViewModel) -> some View {
        VStack(spacing: 16) {
            Spacer()

            LottieCharacterView(
                color: theme.accentMid,
                shadowColor: theme.accentDim,
                bpm: 240,
                isAnimating: true
            )
            .frame(height: 52)

            VStack(spacing: 2) {
                Text("\(Int(session.duration / 60))")
                    .font(.system(size: 78, weight: .ultraLight))
                    .foregroundColor(theme.text)
                    .monospacedDigit()
                    .kerning(-3.5)
                Text(lm.L("summary.completed"))
                    .font(.system(size: 11))
                    .foregroundColor(theme.textDim)
                    .tracking(0.1 * 11)
                    .textCase(.uppercase)
            }

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 5
            ) {
                statCell(icon: "♥", label: lm.L("summary.stat.avgHR"),
                         value: session.avgHR > 0 ? "\(session.avgHR)" : "—")
                statCell(icon: "♩", label: lm.L("summary.stat.bpm"),
                         value: "\(session.bpm)")
                statCell(icon: "◎", label: lm.L("summary.stat.goal"),
                         value: goalPercent)
                statCell(icon: "◷", label: lm.L("summary.stat.total"),
                         value: String(format: "%.1fh", vm.totalHours))
            }

            streakChip(vm)

            Spacer()

            VStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text(lm.L("summary.done"))
                        .font(.system(size: 15, weight: .medium))
                        .tracking(0.04 * 15)
                        .foregroundColor(theme.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(theme.text)
                        .cornerRadius(18)
                }

                Button(action: {}) {
                    Text(lm.L("summary.share"))
                        .font(.system(size: 12))
                        .tracking(0.04 * 12)
                        .foregroundColor(theme.textDim)
                }
            }
            .padding(.bottom, 24)
        }
    }

    private var goalPercent: String {
        let ratio = session.duration / Double(goalMinutes * 60)
        return "\(min(100, Int(ratio * 100)))%"
    }

    private func statCell(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(icon)
                .font(.system(size: 12))
                .foregroundColor(theme.textDim)
            Text(value)
                .font(.system(size: 20, weight: .ultraLight))
                .foregroundColor(theme.textMid)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(theme.card)
        .cornerRadius(12)
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

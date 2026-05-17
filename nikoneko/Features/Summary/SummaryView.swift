import SwiftUI
import SwiftData

struct SummaryView: View {
    let session: RunSession
    @Query private var profiles: [UserProfile]
    @Environment(ThemeManager.self) private var themeManager
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

            // Celebrating character — faster speed signals completion
            LottieCharacterView(
                characterId: session.characterId,
                color: theme.accentMid,
                bpm: 240,
                isAnimating: true
            )
            .frame(height: 60)

            // Duration hero
            VStack(spacing: 2) {
                Text("\(Int(session.duration / 60))")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundColor(theme.text)
                    .monospacedDigit()
                Text("min")
                    .font(.system(size: 9))
                    .foregroundColor(theme.textDim)
                Text("DURATION")
                    .font(.system(size: 7))
                    .tracking(1)
                    .foregroundColor(theme.textDim)
            }

            // 2×2 stat grid
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 8
            ) {
                statCell(icon: "♥", label: "Avg HR",
                         value: session.avgHR > 0 ? "\(session.avgHR)" : "—")
                statCell(icon: "♩", label: "BPM",
                         value: "\(session.bpm)")
                statCell(icon: "◎", label: "Goal",
                         value: goalPercent)
                statCell(icon: "◷", label: "Total",
                         value: String(format: "%.1fh", vm.totalHours))
            }
            .padding(.horizontal, 32)

            // Streak chip
            streakChip(vm)

            Spacer()

            VStack(spacing: 12) {
                // Done button — filled, inverted colors
                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(theme.text)
                        .cornerRadius(12)
                }

                // Share label
                Button(action: {}) {
                    Text("Share")
                        .font(.system(size: 9))
                        .foregroundColor(theme.textDim)
                }
            }
            .padding(.horizontal, 32)
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
                .font(.system(size: 9))
                .foregroundColor(theme.textDim)
            Text(value)
                .font(.system(size: 13, weight: .ultraLight))
                .foregroundColor(theme.textMid)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 6))
                .foregroundColor(theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(theme.surface)
        .cornerRadius(10)
    }

    private func streakChip(_ vm: SummaryViewModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(vm.streakDays)")
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundColor(theme.accent)
                    .monospacedDigit()
                Text("day streak")
                    .font(.system(size: 9))
                    .foregroundColor(theme.textDim)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(vm.thisWeekDots.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(dotColor(vm.thisWeekDots[i]))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(theme.surface)
        .cornerRadius(12)
        .padding(.horizontal, 32)
    }

    private func dotColor(_ state: DotState) -> Color {
        switch state {
        case .empty:    return theme.bar[0]
        case .partial:  return theme.bar[2]
        case .achieved: return theme.bar[4]
        }
    }
}

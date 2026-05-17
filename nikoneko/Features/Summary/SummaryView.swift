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
        VStack(spacing: 20) {
            Spacer()

            LottieCharacterView(
                characterId: session.characterId,
                color: theme.accentMid,
                bpm: 180,
                isAnimating: true
            )
            .frame(height: 60)

            VStack(spacing: 2) {
                Text("\(Int(session.duration / 60))")
                    .font(.system(size: 46, weight: .ultraLight)).foregroundColor(theme.text)
                Text("min").font(.system(size: 9)).foregroundColor(theme.textDim)
                Text("DURATION").font(.system(size: 7)).tracking(1).foregroundColor(theme.textDim)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                statCell("Avg HR", value: session.avgHR > 0 ? "\(session.avgHR)" : "—")
                statCell("BPM",    value: "\(session.bpm)")
                statCell("Goal",   value: session.duration >= Double(goalMinutes * 60) ? "100%" :
                    "\(Int(session.duration / Double(goalMinutes * 60) * 100))%")
                statCell("Total",  value: String(format: "%.1fh", vm.totalHours))
            }
            .padding(.horizontal, 32)

            streakChip(vm)

            Spacer()

            Button("Done") { dismiss() }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(theme.surface)
                .cornerRadius(12)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
        }
    }

    private func statCell(_ label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 18, weight: .ultraLight)).foregroundColor(theme.textMid)
            Text(label).font(.system(size: 7)).foregroundColor(theme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(theme.surface)
        .cornerRadius(10)
    }

    private func streakChip(_ vm: SummaryViewModel) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text("\(vm.streakDays)")
                    .font(.system(size: 28, weight: .ultraLight)).foregroundColor(theme.accent)
                Text("day streak").font(.system(size: 9)).foregroundColor(theme.textDim)
            }
            HStack(spacing: 4) {
                ForEach(vm.thisWeekDots.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(dotColor(vm.thisWeekDots[i]))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(14)
        .background(theme.surface)
        .cornerRadius(12)
    }

    private func dotColor(_ state: DotState) -> Color {
        switch state {
        case .empty:    return theme.bar[0]
        case .partial:  return theme.bar[2]
        case .achieved: return theme.bar[4]
        }
    }
}

import SwiftUI
import SwiftData

struct DefaultsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var ctx

    private var theme: ThemeTokens { themeManager.current }
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionLabel("Time")
                VStack(spacing: 0) {
                    stepperRow(icon: "◷", name: "Duration",
                               value: profile?.defaultDuration ?? 15,
                               step: 5, range: 5...999) { v in
                        profile?.defaultDuration = v; try? ctx.save()
                    }
                    Divider().background(theme.accentDim).padding(.leading, 44)
                    stepperRow(icon: "◎", name: "Daily Goal",
                               value: profile?.dailyGoalMinutes ?? 15,
                               step: 5, range: 5...999) { v in
                        profile?.dailyGoalMinutes = v; try? ctx.save()
                    }
                }
                .background(theme.surface)
                .cornerRadius(10)
                .padding(.bottom, 4)

                sectionLabel("Beat")
                VStack(spacing: 0) {
                    stepperRow(icon: "♩", name: "BPM",
                               value: profile?.defaultBPM ?? 180,
                               step: 1, range: 140...220) { v in
                        profile?.defaultBPM = v; try? ctx.save()
                    }
                    Divider().background(theme.accentDim).padding(.leading, 44)
                    soundRow
                }
                .background(theme.surface)
                .cornerRadius(10)
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(theme.bg.ignoresSafeArea())
        .navigationTitle("Training Defaults")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 8))
            .tracking(1)
            .foregroundColor(theme.textDim)
            .padding(.top, 12)
            .padding(.bottom, 4)
            .padding(.horizontal, 2)
    }

    private func stepperRow(icon: String, name: String, value: Int,
                             step: Int, range: ClosedRange<Int>,
                             onChange: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 10) {
            Text(icon)
                .font(.system(size: 12))
                .foregroundColor(theme.textDim)
                .frame(width: 16)
            Text(name)
                .font(.system(size: 11))
                .foregroundColor(theme.textMid)
            Spacer()
            HStack(spacing: 6) {
                stepButton("−") {
                    onChange(max(range.lowerBound, value - step))
                }
                Text("\(value)")
                    .font(.system(size: 13, weight: .ultraLight))
                    .foregroundColor(theme.textMid)
                    .monospacedDigit()
                    .frame(minWidth: 28, alignment: .center)
                stepButton("+") {
                    onChange(min(range.upperBound, value + step))
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 46)
    }

    private func stepButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(theme.textMid)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(theme.accentDim, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private var soundRow: some View {
        HStack(spacing: 10) {
            Text("♪")
                .font(.system(size: 12))
                .foregroundColor(theme.textDim)
                .frame(width: 16)
            Text("Sound")
                .font(.system(size: 11))
                .foregroundColor(theme.textMid)
            Spacer()
            soundPicker
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 46)
    }

    private var soundPicker: some View {
        let options: [(SoundType, String)] = [(.tap, "叩"), (.bell, "鈴"), (.drum, "鼓"), (.wood, "木")]
        let current = profile?.soundType ?? .tap
        return HStack(spacing: 2) {
            ForEach(options, id: \.0) { (type, label) in
                Button(action: { profile?.soundType = type; try? ctx.save() }) {
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundColor(current == type ? theme.textMid : theme.textDim)
                        .frame(width: 28, height: 26)
                        .background(current == type ? theme.card : Color.clear)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(theme.surface)
        .cornerRadius(8)
    }
}

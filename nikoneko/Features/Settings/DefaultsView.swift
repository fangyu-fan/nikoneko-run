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
                    Rectangle()
                        .fill(theme.accentDim)
                        .frame(height: 0.5)
                    stepperRow(icon: "◎", name: "Daily Goal",
                               value: profile?.dailyGoalMinutes ?? 15,
                               step: 5, range: 5...999) { v in
                        profile?.dailyGoalMinutes = v; try? ctx.save()
                    }
                }
                .background(theme.surface)
                .cornerRadius(14)
                .padding(.bottom, 4)

                sectionLabel("Beat")
                VStack(spacing: 0) {
                    stepperRow(icon: "♩", name: "BPM",
                               value: profile?.defaultBPM ?? 180,
                               step: 1, range: 140...220,
                               isBPM: true) { v in
                        profile?.defaultBPM = v; try? ctx.save()
                    }
                    Rectangle()
                        .fill(theme.accentDim)
                        .frame(height: 0.5)
                    soundRow
                    Rectangle()
                        .fill(theme.accentDim)
                        .frame(height: 0.5)
                    lockVolumeRow
                }
                .background(theme.surface)
                .cornerRadius(14)
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .background(theme.bg.ignoresSafeArea())
        .navigationTitle("Training Defaults")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10))
            .tracking(1)
            .foregroundColor(theme.textDim)
            .padding(.top, 10)
            .padding(.bottom, 5)
            .padding(.horizontal, 2)
    }

    private func stepperRow(icon: String, name: String, value: Int,
                             step: Int, range: ClosedRange<Int>,
                             isBPM: Bool = false,
                             onChange: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 10) {
            Text(icon)
                .font(.system(size: 16))
                .foregroundColor(theme.textDim)
                .frame(width: 20)
            Text(name)
                .font(.system(size: 14))
                .foregroundColor(theme.textMid)
            Spacer()
            HStack(spacing: 8) {
                stepButton("−") {
                    onChange(max(range.lowerBound, value - step))
                }
                Text("\(value)")
                    .font(.system(size: 16, weight: .ultraLight))
                    .foregroundColor(theme.textMid)
                    .monospacedDigit()
                    .frame(minWidth: isBPM ? 40 : 52, alignment: .center)
                stepButton("+") {
                    onChange(min(range.upperBound, value + step))
                }
            }
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
    }

    private func stepButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(theme.textMid)
                .frame(width: 26, height: 26)
                .overlay(Circle().stroke(theme.accentDim, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private var soundRow: some View {
        HStack(spacing: 10) {
            Text("♪")
                .font(.system(size: 16))
                .foregroundColor(theme.textDim)
                .frame(width: 20)
            Text("Sound")
                .font(.system(size: 14))
                .foregroundColor(theme.textMid)
            Spacer()
            soundPicker
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
    }

    private var lockVolumeRow: some View {
        HStack(spacing: 10) {
            Text("♫")
                .font(.system(size: 16))
                .foregroundColor(theme.textDim)
                .frame(width: 20)
            Text("Lock Volume")
                .font(.system(size: 14))
                .foregroundColor(theme.textMid)
            Spacer()
            Toggle("", isOn: bindBool(\.volumeLockEnabled))
                .tint(theme.accent)
                .labelsHidden()
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
    }

    private var soundPicker: some View {
        let options: [(SoundType, String)] = [(.tap, "叩"), (.bell, "鈴"), (.drum, "鼓"), (.wood, "木")]
        let current = profile?.soundType ?? .tap
        return HStack(spacing: 2) {
            ForEach(options, id: \.0) { (type, label) in
                Button(action: { profile?.soundType = type; try? ctx.save() }) {
                    Text(label)
                        .font(.system(size: 13))
                        .foregroundColor(current == type ? theme.textMid : theme.textDim)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(current == type ? theme.card : Color.clear)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(theme.surface)
        .cornerRadius(10)
    }

    private func bindBool(_ kp: ReferenceWritableKeyPath<UserProfile, Bool>) -> Binding<Bool> {
        Binding(
            get: { profile?[keyPath: kp] ?? false },
            set: { v in profile?[keyPath: kp] = v; try? ctx.save() }
        )
    }
}

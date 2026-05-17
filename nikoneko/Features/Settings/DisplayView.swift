import SwiftUI
import SwiftData

struct DisplayView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var ctx

    private var theme: ThemeTokens { themeManager.current }
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionLabel("Timer Mode")
                radioCard([
                    ("◷", "Countdown",
                     profile?.timerMode == .countdown || profile?.timerMode == nil,
                     { profile?.timerMode = .countdown; try? ctx.save() }),
                    ("◷", "Stopwatch",
                     profile?.timerMode == .stopwatch,
                     { profile?.timerMode = .stopwatch; try? ctx.save() }),
                ])

                sectionLabel("Time Format")
                radioCard([
                    ("1", "Plain min",
                     profile?.timeDisplayFormat == .plainMinutes || profile?.timeDisplayFormat == nil,
                     { profile?.timeDisplayFormat = .plainMinutes; try? ctx.save() }),
                    ("∶", "HH:MM",
                     profile?.timeDisplayFormat == .hhMM,
                     { profile?.timeDisplayFormat = .hhMM; try? ctx.save() }),
                ])

                sectionLabel("During Run")
                toggleCard([
                    ("♥",  "Heart Rate", bindBool(\.showHR)),
                    ("⊙",  "Distance",   bindBool(\.showDistance)),
                    ("△",  "Calories",   bindBool(\.showCalories)),
                    ("⊞",  "Steps",      bindBool(\.showSteps)),
                    ("〜", "Haptic",      bindBool(\.hapticEnabled)),
                ])
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(theme.bg.ignoresSafeArea())
        .navigationTitle("Display")
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

    private func radioCard(_ items: [(String, String, Bool, () -> Void)]) -> some View {
        VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                let (icon, name, isSelected, action) = items[i]
                Button(action: action) {
                    HStack(spacing: 10) {
                        Text(icon)
                            .font(.system(size: 12))
                            .foregroundColor(theme.textDim)
                            .frame(width: 16)
                        Text(name)
                            .font(.system(size: 11))
                            .foregroundColor(theme.textMid)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11))
                                .foregroundColor(theme.accent)
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 46)
                }
                .buttonStyle(.plain)
                if i < items.count - 1 {
                    Divider().background(theme.accentDim).padding(.leading, 44)
                }
            }
        }
        .background(theme.surface)
        .cornerRadius(10)
        .padding(.bottom, 4)
    }

    private func toggleCard(_ items: [(String, String, Binding<Bool>)]) -> some View {
        VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                let (icon, name, binding) = items[i]
                HStack(spacing: 10) {
                    Text(icon)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textDim)
                        .frame(width: 16)
                    Text(name)
                        .font(.system(size: 11))
                        .foregroundColor(theme.textMid)
                    Spacer()
                    Toggle("", isOn: binding)
                        .tint(theme.accent)
                        .labelsHidden()
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 46)
                if i < items.count - 1 {
                    Divider().background(theme.accentDim).padding(.leading, 44)
                }
            }
        }
        .background(theme.surface)
        .cornerRadius(10)
        .padding(.bottom, 4)
    }

    private func bindBool(_ kp: ReferenceWritableKeyPath<UserProfile, Bool>) -> Binding<Bool> {
        Binding(
            get: { profile?[keyPath: kp] ?? false },
            set: { v in profile?[keyPath: kp] = v; try? ctx.save() }
        )
    }
}

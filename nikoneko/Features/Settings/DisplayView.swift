import SwiftUI
import SwiftData

struct DisplayView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    private var theme: ThemeTokens { themeManager.current }
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionLabel(lm.L("display.section.timerMode"))
                radioCard([
                    ("timer",       lm.L("display.timerMode.countdown"),
                     (profile?.timerMode ?? .countdown) == .countdown,
                     { profile?.timerMode = .countdown; try? ctx.save() }),
                    ("stopwatch",   lm.L("display.timerMode.stopwatch"),
                     (profile?.timerMode ?? .countdown) == .stopwatch,
                     { profile?.timerMode = .stopwatch; try? ctx.save() }),
                ])

                sectionLabel(lm.L("display.section.timeFormat"))
                radioCard([
                    ("textformat.123", lm.L("display.timeFormat.plain"),
                     (profile?.timeDisplayFormat ?? .plainMinutes) == .plainMinutes,
                     { profile?.timeDisplayFormat = .plainMinutes; try? ctx.save() }),
                    ("clock",          lm.L("display.timeFormat.hhmm"),
                     (profile?.timeDisplayFormat ?? .plainMinutes) == .hhMM,
                     { profile?.timeDisplayFormat = .hhMM; try? ctx.save() }),
                ])

                sectionLabel(lm.L("display.section.duringRun"))
                toggleCard([
                    ("heart",          lm.L("display.metric.heartRate"), bindBool(\.showHR)),
                    ("location.circle", lm.L("display.metric.distance"),  bindBool(\.showDistance)),
                    ("flame",           lm.L("display.metric.calories"),  bindBool(\.showCalories)),
                    ("shoeprints.fill",     lm.L("display.metric.steps"),     bindBool(\.showSteps)),
                ])
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .background(theme.bg.ignoresSafeArea())
        .navigationTitle(lm.L("display.title"))
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

    private func radioCard(_ items: [(String, String, Bool, () -> Void)]) -> some View {
        VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                let (icon, name, isSelected, action) = items[i]
                Button(action: action) {
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(theme.text)
                            .frame(width: 20)
                        Text(name)
                            .font(.system(size: 16))
                            .foregroundColor(theme.text)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13))
                                .foregroundColor(theme.accent)
                        }
                    }
                    .padding(.vertical, 13)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if i < items.count - 1 {
                    Rectangle()
                        .fill(theme.accentDim)
                        .frame(height: 0.5)
                }
            }
        }
        .background(theme.surface)
        .cornerRadius(14)
        .padding(.bottom, 4)
    }

    private func toggleCard(_ items: [(String, String, Binding<Bool>)]) -> some View {
        VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                let (icon, name, binding) = items[i]
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(theme.text)
                        .frame(width: 20)
                    Text(name)
                        .font(.system(size: 16))
                        .foregroundColor(theme.text)
                    Spacer()
                    Toggle("", isOn: binding)
                        .tint(theme.accent)
                        .labelsHidden()
                }
                .padding(.vertical, 13)
                .padding(.horizontal, 16)
                .frame(minHeight: 50)
                if i < items.count - 1 {
                    Rectangle()
                        .fill(theme.accentDim)
                        .frame(height: 0.5)
                }
            }
        }
        .background(theme.surface)
        .cornerRadius(14)
        .padding(.bottom, 4)
    }

    private func bindBool(_ kp: ReferenceWritableKeyPath<UserProfile, Bool>) -> Binding<Bool> {
        Binding(
            get: { profile?[keyPath: kp] ?? false },
            set: { v in
                guard let p = profile else { return }
                p[keyPath: kp] = v
                try? ctx.save()
            }
        )
    }
}

import SwiftUI
import SwiftData

struct DefaultsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var ctx

    private var theme: ThemeTokens { themeManager.current }
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        List {
            stepper("Default Duration (min)",
                    value: bindInt(\.defaultDuration), range: 5...999, step: 5)
            stepper("Daily Goal (min)",
                    value: bindInt(\.dailyGoalMinutes), range: 5...999, step: 5)
            stepper("Default BPM",
                    value: bindInt(\.defaultBPM), range: 140...220, step: 1)

            Section("Sound") {
                ForEach(SoundType.allCases, id: \.self) { sound in
                    HStack {
                        Text(sound.rawValue.capitalized).foregroundColor(theme.text)
                        Spacer()
                        if profile?.soundType == sound {
                            Image(systemName: "checkmark").foregroundColor(theme.accent)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { profile?.soundType = sound; try? ctx.save() }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(theme.bg)
        .navigationTitle("Defaults")
    }

    private func stepper(_ label: String, value: Binding<Int>,
                          range: ClosedRange<Int>, step: Int) -> some View {
        Stepper("\(label): \(value.wrappedValue)", value: value, in: range, step: step)
            .foregroundColor(theme.text)
    }

    private func bindInt(_ kp: ReferenceWritableKeyPath<UserProfile, Int>) -> Binding<Int> {
        Binding(
            get: { profile?[keyPath: kp] ?? 0 },
            set: { v in profile?[keyPath: kp] = v; try? ctx.save() }
        )
    }
}

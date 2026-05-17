import SwiftUI
import SwiftData

struct DisplayView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var ctx

    private var theme: ThemeTokens { themeManager.current }
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        List {
            toggle("Heart Rate Display", binding: bindBool(\.showHR))
            toggle("Progress Ring",      binding: bindBool(\.showProgressRing))
            toggle("Haptic Feedback",    binding: bindBool(\.hapticEnabled))
            Section("Metrics") {
                toggle("Distance",  binding: bindBool(\.showDistance))
                toggle("Calories",  binding: bindBool(\.showCalories))
                toggle("Steps",     binding: bindBool(\.showSteps))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(theme.bg)
        .navigationTitle("Display")
    }

    private func toggle(_ label: String, binding: Binding<Bool>) -> some View {
        Toggle(label, isOn: binding).tint(theme.accent)
    }

    private func bindBool(_ kp: ReferenceWritableKeyPath<UserProfile, Bool>) -> Binding<Bool> {
        Binding(
            get: { profile?[keyPath: kp] ?? false },
            set: { v in profile?[keyPath: kp] = v; try? ctx.save() }
        )
    }
}

import SwiftUI
import SwiftData

struct NotificationsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var ctx

    private var theme: ThemeTokens { themeManager.current }
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        List {
            Toggle("Daily Reminder", isOn: Binding(
                get: { profile?.notificationsEnabled ?? false },
                set: { v in profile?.notificationsEnabled = v; try? ctx.save() }
            )).tint(theme.accent)

            if profile?.notificationsEnabled == true {
                DatePicker("Time",
                    selection: Binding(
                        get: {
                            var c = Calendar.current.dateComponents([.hour, .minute], from: Date())
                            c.hour = profile?.notificationHour ?? 7
                            c.minute = profile?.notificationMinute ?? 0
                            return Calendar.current.date(from: c) ?? Date()
                        },
                        set: { d in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                            profile?.notificationHour = c.hour ?? 7
                            profile?.notificationMinute = c.minute ?? 0
                            try? ctx.save()
                        }),
                    displayedComponents: .hourAndMinute
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(theme.bg)
        .navigationTitle("Notifications")
    }
}

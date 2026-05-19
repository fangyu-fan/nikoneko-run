import SwiftUI
import SwiftData

struct NotificationsView: View {
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
                sectionLabel(lm.L("notif.section.reminder"))
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "bell")
                            .font(.system(size: 16))
                            .foregroundColor(theme.text)
                            .frame(width: 20)
                        Text(lm.L("notif.row.dailyReminder"))
                            .font(.system(size: 16))
                            .foregroundColor(theme.text)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { profile?.notificationsEnabled ?? false },
                            set: { v in
                                profile?.notificationsEnabled = v
                                try? ctx.save()
                                if v {
                                    Task {
                                        let granted = await NotificationService.requestPermission()
                                        if granted {
                                            NotificationService.scheduleDaily(
                                                hour: profile?.notificationHour ?? 7,
                                                minute: profile?.notificationMinute ?? 0
                                            )
                                        }
                                    }
                                } else {
                                    NotificationService.cancel()
                                }
                            }
                        ))
                        .tint(theme.accent)
                        .labelsHidden()
                    }
                    .padding(.vertical, 13)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 50)

                    if profile?.notificationsEnabled == true {
                        Rectangle().fill(theme.accentDim).frame(height: 0.5)
                        HStack(spacing: 10) {
                            Image(systemName: "clock")
                                .font(.system(size: 16))
                                .foregroundColor(theme.text)
                                .frame(width: 20)
                            Text(lm.L("notif.row.time"))
                                .font(.system(size: 16))
                                .foregroundColor(theme.text)
                            Spacer()
                            DatePicker("", selection: Binding(
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
                                    NotificationService.scheduleDaily(
                                        hour: profile?.notificationHour ?? 7,
                                        minute: profile?.notificationMinute ?? 0
                                    )
                                }),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .tint(theme.accent)
                        }
                        .padding(.vertical, 13)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 50)
                    }
                }
                .background(theme.surface)
                .cornerRadius(14)
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .background(theme.bg.ignoresSafeArea())
        .navigationTitle(lm.L("notif.title.screen"))
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
}

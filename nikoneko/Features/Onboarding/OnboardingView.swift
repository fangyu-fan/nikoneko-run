import SwiftUI
import SwiftData

// MARK: - OnboardingView

struct OnboardingView: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.modelContext) private var context
    let onComplete: () -> Void

    private let totalPages = 3

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $vm.currentPage) {
                LangThemeStepView(language: $vm.language, themeId: $vm.themeId)
                    .tag(0)
                TrainingStepView(
                    dailyGoalMinutes: $vm.dailyGoalMinutes,
                    defaultBPM: $vm.defaultBPM,
                    healthKitEnabled: $vm.healthKitEnabled
                )
                .tag(1)
                NotifCloudStepView(
                    notificationsEnabled: $vm.notificationsEnabled,
                    notificationHour: $vm.notificationHour,
                    notificationMinute: $vm.notificationMinute,
                    iCloudEnabled: $vm.iCloudEnabled
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)

            // Bottom navigation
            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { i in
                        Circle()
                            .fill(i == vm.currentPage ? Color.primary : Color.primary.opacity(0.2))
                            .frame(
                                width: i == vm.currentPage ? 8 : 6,
                                height: i == vm.currentPage ? 8 : 6
                            )
                            .animation(.easeInOut(duration: 0.2), value: vm.currentPage)
                    }
                }

                Button {
                    if vm.currentPage < totalPages - 1 {
                        withAnimation { vm.currentPage += 1 }
                    } else {
                        vm.complete(
                            themeManager: themeManager,
                            languageManager: languageManager,
                            context: context
                        )
                        onComplete()
                    }
                } label: {
                    Text(vm.currentPage < totalPages - 1 ? "Next" : "Get Started")
                        .font(.system(size: 16, weight: .light))
                        .tracking(0.5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.primary.opacity(0.9))
                        .foregroundStyle(Color(UIColor.systemBackground))
                        .cornerRadius(14)
                }
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 40)
            .background(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: Color(UIColor.systemBackground).opacity(0.95), location: 0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            )
        }
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - OnboardingViewModel

@Observable
final class OnboardingViewModel {
    var language: AppLanguage = .english
    var themeId: String = "obsidian"
    var dailyGoalMinutes: Int = 20
    var defaultBPM: Int = 180
    var notificationsEnabled: Bool = false
    var notificationHour: Int = 7
    var notificationMinute: Int = 0
    var healthKitEnabled: Bool = false
    var iCloudEnabled: Bool = false
    var currentPage: Int = 0

    func complete(
        themeManager: ThemeManager,
        languageManager: LanguageManager,
        context: ModelContext
    ) {
        let profile = UserProfile()
        profile.languageRaw = language.rawValue
        profile.activeThemeId = themeId
        profile.dailyGoalMinutes = dailyGoalMinutes
        profile.defaultDuration = dailyGoalMinutes
        profile.defaultBPM = defaultBPM
        profile.notificationsEnabled = notificationsEnabled
        profile.notificationHour = notificationHour
        profile.notificationMinute = notificationMinute
        profile.healthKitEnabled = healthKitEnabled
        profile.iCloudEnabled = iCloudEnabled
        context.insert(profile)
        try? context.save()

        languageManager.apply(language)
        themeManager.apply(themeId)

        UserDefaults.standard.set(language.code, forKey: "activeLanguageCode")
        UserDefaults.standard.set(iCloudEnabled, forKey: "iCloudEnabled")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        if notificationsEnabled {
            NotificationService.scheduleDaily(hour: notificationHour, minute: notificationMinute)
        }
    }
}

// MARK: - LangThemeStepView

private struct LangThemeStepView: View {
    @Binding var language: AppLanguage
    @Binding var themeId: String
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundStyle(Color.primary)
                    Text("Choose your language and appearance.")
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(Color.primary.opacity(0.5))
                }
                .padding(.top, 60)

                // Language section
                VStack(alignment: .leading, spacing: 12) {
                    sectionLabel("Language")

                    VStack(spacing: 0) {
                        languageButton(
                            title: "English",
                            selected: language == .english
                        ) {
                            language = .english
                        }

                        Divider()
                            .padding(.horizontal, 16)

                        languageButton(
                            title: "繁體中文",
                            selected: language == .traditionalChinese
                        ) {
                            language = .traditionalChinese
                        }
                    }
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
                }

                // Theme section
                VStack(alignment: .leading, spacing: 12) {
                    sectionLabel("Theme")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(ThemeLibrary.all, id: \.id) { t in
                                themeSwatchButton(theme: t)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                    }
                    .padding(.horizontal, -16)
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func languageButton(
        title: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(Color.primary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Color.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func themeSwatchButton(theme: ThemeTokens) -> some View {
        let isSelected = themeId == theme.id
        Button {
            themeId = theme.id
            themeManager.apply(theme.id)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.bg)
                    .frame(width: 64, height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                isSelected ? theme.accent : Color.primary.opacity(0.1),
                                lineWidth: isSelected ? 2 : 0.5
                            )
                    )

                // Two-tone accent preview stripe
                VStack(spacing: 0) {
                    theme.accent
                        .frame(height: 20)
                    theme.accentDim
                        .frame(height: 10)
                }
                .clipShape(
                    RoundedRectangle(cornerRadius: 4)
                )
                .frame(width: 32, height: 30)

                if isSelected {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 8, height: 8)
                        .offset(x: 20, y: -20)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - TrainingStepView

private struct TrainingStepView: View {
    @Binding var dailyGoalMinutes: Int
    @Binding var defaultBPM: Int
    @Binding var healthKitEnabled: Bool

    @State private var isRequestingHealth = false
    @State private var healthGranted = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Training")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundStyle(Color.primary)
                    Text("Set your daily goal and default pace.")
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(Color.primary.opacity(0.5))
                }
                .padding(.top, 60)

                // Daily Goal section
                VStack(alignment: .leading, spacing: 12) {
                    sectionLabel("Daily Goal")

                    VStack(spacing: 12) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(dailyGoalMinutes)")
                                .font(.system(size: 56, weight: .ultraLight))
                                .foregroundStyle(Color.primary)
                                .monospacedDigit()
                            Text("min")
                                .font(.system(size: 18, weight: .light))
                                .foregroundStyle(Color.primary.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)

                        HStack(spacing: 12) {
                            nudgeButton(label: "−5") {
                                dailyGoalMinutes = max(5, dailyGoalMinutes - 5)
                            }
                            nudgeButton(label: "+5") {
                                dailyGoalMinutes = min(999, dailyGoalMinutes + 5)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
                }

                // Default BPM section
                VStack(alignment: .leading, spacing: 12) {
                    sectionLabel("Default BPM")

                    VStack(spacing: 12) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(defaultBPM)")
                                .font(.system(size: 56, weight: .ultraLight))
                                .foregroundStyle(Color.primary)
                                .monospacedDigit()
                            Text("bpm")
                                .font(.system(size: 18, weight: .light))
                                .foregroundStyle(Color.primary.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)

                        HStack(spacing: 12) {
                            nudgeButton(label: "−5") {
                                defaultBPM = max(140, defaultBPM - 5)
                            }
                            nudgeButton(label: "+5") {
                                defaultBPM = min(220, defaultBPM + 5)
                            }
                        }

                        HStack(spacing: 12) {
                            nudgeButton(label: "−1") {
                                defaultBPM = max(140, defaultBPM - 1)
                            }
                            nudgeButton(label: "+1") {
                                defaultBPM = min(220, defaultBPM + 1)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
                }

                // Health section
                VStack(alignment: .leading, spacing: 12) {
                    sectionLabel("Health")

                    HStack(spacing: 12) {
                        Image(systemName: "heart")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(Color.primary.opacity(0.6))
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apple Health")
                                .font(.system(size: 15, weight: .light))
                                .foregroundStyle(Color.primary)
                            Text("Save workouts and read heart rate")
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(Color.primary.opacity(0.5))
                        }

                        Spacer()

                        if healthGranted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .light))
                                .foregroundStyle(Color.primary.opacity(0.6))
                        } else {
                            Button {
                                guard !isRequestingHealth else { return }
                                isRequestingHealth = true
                                Task {
                                    await HealthKitService.shared.requestPermissions()
                                    await MainActor.run {
                                        healthKitEnabled = true
                                        healthGranted = true
                                        isRequestingHealth = false
                                    }
                                }
                            } label: {
                                Text(isRequestingHealth ? "..." : "Allow")
                                    .font(.system(size: 13, weight: .light))
                                    .tracking(0.3)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(Color.primary.opacity(0.08))
                                    .foregroundStyle(Color.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                            .disabled(isRequestingHealth)
                        }
                    }
                    .padding(16)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - NotifCloudStepView

private struct NotifCloudStepView: View {
    @Binding var notificationsEnabled: Bool
    @Binding var notificationHour: Int
    @Binding var notificationMinute: Int
    @Binding var iCloudEnabled: Bool

    @State private var notifTime: Date = {
        var c = DateComponents(); c.hour = 7; c.minute = 0
        return Calendar.current.date(from: c) ?? Date()
    }()
    @State private var isRequestingNotif = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reminders")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundStyle(Color.primary)
                    Text("Stay consistent with daily reminders.")
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(Color.primary.opacity(0.5))
                }
                .padding(.top, 60)

                // Notifications section
                VStack(alignment: .leading, spacing: 12) {
                    sectionLabel("Notifications")

                    VStack(spacing: 0) {
                        // Toggle row
                        HStack(spacing: 12) {
                            Image(systemName: "bell")
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(Color.primary.opacity(0.6))
                                .frame(width: 24)

                            Text("Daily Reminder")
                                .font(.system(size: 15, weight: .light))
                                .foregroundStyle(Color.primary)

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { notificationsEnabled },
                                set: { newValue in
                                    guard !isRequestingNotif else { return }
                                    if newValue {
                                        isRequestingNotif = true
                                        Task {
                                            let granted = await NotificationService.requestPermission()
                                            await MainActor.run {
                                                notificationsEnabled = granted
                                                isRequestingNotif = false
                                            }
                                        }
                                    } else {
                                        notificationsEnabled = false
                                    }
                                }
                            ))
                            .labelsHidden()
                            .tint(Color.primary.opacity(0.8))
                            .disabled(isRequestingNotif)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)

                        // Time picker — shown only when enabled
                        if notificationsEnabled {
                            Divider()
                                .padding(.horizontal, 16)

                            HStack(spacing: 12) {
                                Image(systemName: "clock")
                                    .font(.system(size: 16, weight: .light))
                                    .foregroundStyle(Color.primary.opacity(0.6))
                                    .frame(width: 24)

                                Text("Time")
                                    .font(.system(size: 15, weight: .light))
                                    .foregroundStyle(Color.primary)

                                Spacer()

                                DatePicker(
                                    "",
                                    selection: $notifTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                                .onChange(of: notifTime) { _, newValue in
                                    let cal = Calendar.current
                                    notificationHour = cal.component(.hour, from: newValue)
                                    notificationMinute = cal.component(.minute, from: newValue)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                    }
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
                }

                // Sync section
                VStack(alignment: .leading, spacing: 12) {
                    sectionLabel("Sync")

                    HStack(spacing: 12) {
                        Image(systemName: "icloud")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(Color.primary.opacity(0.6))
                            .frame(width: 24)

                        Text("iCloud Sync")
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(Color.primary)

                        Spacer()

                        Toggle("", isOn: $iCloudEnabled)
                            .labelsHidden()
                            .tint(Color.primary.opacity(0.8))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            // Initialize notifTime from bindings
            var comps = DateComponents()
            comps.hour = notificationHour
            comps.minute = notificationMinute
            notifTime = Calendar.current.date(from: comps) ?? Date()
        }
    }
}

// MARK: - Shared helpers (file-private)

private func sectionLabel(_ text: String) -> some View {
    Text(text.uppercased())
        .font(.system(size: 13, weight: .light))
        .tracking(0.04 * 13)
        .foregroundStyle(Color.primary.opacity(0.4))
}

private func nudgeButton(label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(label)
            .font(.system(size: 15, weight: .light))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.06))
            .foregroundStyle(Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .buttonStyle(.plain)
}

// MARK: - Preview

#if DEBUG
#Preview {
    let vm = OnboardingViewModel()
    return OnboardingView(vm: vm) {}
        .environment(ThemeManager())
        .environment(LanguageManager())
        .modelContainer(for: UserProfile.self, inMemory: true)
}
#endif

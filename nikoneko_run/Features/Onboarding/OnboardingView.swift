import SwiftUI
import SwiftData
import HealthKit
import CoreMotion
import UserNotifications

struct OnboardingView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    @Environment(\.modelContext) private var ctx
    @Query private var profiles: [UserProfile]

    let onDismiss: () -> Void

    @State private var page: Int = 0
    @State private var notifEnabled: Bool = true
    @State private var notifTime: Date = {
        var c = DateComponents(); c.hour = 7; c.minute = 0
        return Calendar.current.date(from: c) ?? Date()
    }()
    @State private var healthStatus: PermStatus = .pending
    @State private var motionStatus: PermStatus = .pending
    @State private var notifStatus: PermStatus = .pending
    @State private var isRequesting: Bool = false

    private var theme: ThemeTokens { themeManager.current }
    private var profile: UserProfile? { profiles.first }
    private let totalPages = 4

    enum PermStatus { case pending, granted, denied }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                progressBar
                    .padding(.top, 16)
                    .padding(.horizontal, 32)
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    languagePage.tag(1)
                    notifPage.tag(2)
                    permissionsPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: page)
            }
        }
        .id(lm.version)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(theme.accentDim.opacity(0.3))
                    .frame(height: 2)
                RoundedRectangle(cornerRadius: 1)
                    .fill(theme.accent)
                    .frame(width: geo.size.width * CGFloat(page + 1) / CGFloat(totalPages), height: 2)
                    .animation(.easeInOut(duration: 0.3), value: page)
            }
        }
        .frame(height: 2)
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()
            LottieCharacterView(
                characterId: "loader_cat",
                color: theme.accentMid,
                shadowColor: theme.accentDim,
                bpm: 180,
                isAnimating: true
            )
            .frame(width: 120, height: 88)
            .padding(.bottom, 32)

            Text("Niconeko Run")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(theme.text)
                .padding(.bottom, 8)

            Text("slow jog · smile pace")
                .font(.system(size: 13))
                .tracking(0.5)
                .foregroundColor(theme.textDim)

            Spacer()
            nextButton(label: lm.L("onboarding.next")) { page = 1 }
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
        }
    }

    // MARK: - Page 2: Language

    private var languagePage: some View {
        VStack(spacing: 0) {
            Spacer()
            Text(lm.L("onboarding.lang.title"))
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(theme.text)
                .padding(.bottom, 40)

            HStack(spacing: 16) {
                langOption(label: "English", lang: .english)
                langOption(label: "繁體中文", lang: .traditionalChinese)
            }
            .padding(.horizontal, 32)

            Spacer()
            nextButton(label: lm.L("onboarding.next")) { page = 2 }
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
        }
    }

    private func langOption(label: String, lang: AppLanguage) -> some View {
        let selected = (profile?.language ?? .english) == lang
        return Button {
            profile?.language = lang
            try? ctx.save()
            lm.apply(lang)
        } label: {
            Text(label)
                .font(.system(size: 17))
                .foregroundColor(selected ? theme.accent : theme.textMid)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(selected ? theme.accent : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Page 3: Notifications

    private var notifPage: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "bell")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(theme.accent)
                .padding(.bottom, 24)

            Text(lm.L("onboarding.notif.title"))
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(theme.text)
                .padding(.bottom, 12)

            Text(lm.L("onboarding.notif.body"))
                .font(.system(size: 16))
                .foregroundColor(theme.textMid)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)

            VStack(spacing: 0) {
                HStack {
                    Text(lm.L("notif.row.dailyReminder"))
                        .font(.system(size: 16))
                        .foregroundColor(theme.text)
                    Spacer()
                    Toggle("", isOn: $notifEnabled)
                        .tint(theme.accent)
                        .labelsHidden()
                }
                .padding(.vertical, 13)
                .padding(.horizontal, 16)

                if notifEnabled {
                    Rectangle().fill(theme.accentDim).frame(height: 0.5)
                    DatePicker("", selection: $notifTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .tint(theme.accent)
                        .padding(.horizontal, 16)
                }
            }
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 32)

            Spacer()
            nextButton(label: lm.L("onboarding.next")) {
                let c = Calendar.current.dateComponents([.hour, .minute], from: notifTime)
                profile?.notificationsEnabled = notifEnabled
                profile?.notificationHour = c.hour ?? 7
                profile?.notificationMinute = c.minute ?? 0
                try? ctx.save()
                page = 3
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
        }
    }

    // MARK: - Page 4: Permissions

    private var permissionsPage: some View {
        VStack(spacing: 0) {
            Spacer()
            Text(lm.L("onboarding.perms.title"))
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(theme.text)
                .padding(.bottom, 12)

            Text(lm.L("onboarding.perms.body"))
                .font(.system(size: 16))
                .foregroundColor(theme.textMid)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)

            VStack(spacing: 0) {
                permRow(
                    icon: "heart",
                    name: lm.L("onboarding.perms.health.name"),
                    desc: lm.L("onboarding.perms.health.desc"),
                    status: healthStatus
                )
                Rectangle().fill(theme.accentDim).frame(height: 0.5)
                permRow(
                    icon: "figure.walk",
                    name: lm.L("onboarding.perms.motion.name"),
                    desc: lm.L("onboarding.perms.motion.desc"),
                    status: motionStatus
                )
                Rectangle().fill(theme.accentDim).frame(height: 0.5)
                permRow(
                    icon: "bell",
                    name: lm.L("onboarding.perms.notif.name"),
                    desc: notifEnabled
                        ? lm.L("onboarding.perms.notif.desc")
                        : lm.L("onboarding.perms.notif.skipped"),
                    status: notifEnabled ? notifStatus : .granted
                )
            }
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 32)
            .padding(.bottom, 32)

            if healthStatus == .pending || motionStatus == .pending || (notifEnabled && notifStatus == .pending) {
                allowButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
            }

            nextButton(
                label: lm.L("onboarding.cta.start"),
                enabled: !isRequesting
            ) {
                finish()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
        }
    }

    private func permRow(icon: String, name: String, desc: String, status: PermStatus) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(theme.text)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15))
                    .foregroundColor(theme.text)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(theme.textDim)
            }
            Spacer()
            statusBadge(status)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }

    private func statusBadge(_ status: PermStatus) -> some View {
        let (label, color): (String, Color) = {
            switch status {
            case .pending: return (lm.L("onboarding.perms.status.pending"), theme.textDim)
            case .granted: return ("✓ " + lm.L("onboarding.perms.status.granted"), theme.accent)
            case .denied:  return (lm.L("onboarding.perms.status.denied"), Color.orange)
            }
        }()
        return Text(label)
            .font(.system(size: 12))
            .foregroundColor(color)
    }

    private var allowButton: some View {
        Button {
            Task { await requestAllPermissions() }
        } label: {
            Text(isRequesting ? "..." : lm.L("onboarding.perms.cta"))
                .font(.system(size: 16))
                .foregroundColor(theme.bg)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(isRequesting)
        .buttonStyle(.plain)
    }

    // MARK: - Permission Requests

    @MainActor
    private func requestAllPermissions() async {
        isRequesting = true

        // 1. HealthKit
        await HealthKitService.shared.requestPermissions()
        let hkStore = HKHealthStore()
        let hkStatus = hkStore.authorizationStatus(for: HKQuantityType(.heartRate))
        healthStatus = hkStatus == .sharingAuthorized ? .granted : .denied

        // 2. Motion
        await requestMotionPermission()

        // 3. Notifications (only if enabled on page 3)
        if notifEnabled {
            let granted = await NotificationService.requestPermission()
            notifStatus = granted ? .granted : .denied
            if granted {
                let c = Calendar.current.dateComponents([.hour, .minute], from: notifTime)
                NotificationService.scheduleDaily(hour: c.hour ?? 7, minute: c.minute ?? 0)
            }
        }

        isRequesting = false
    }

    private func requestMotionPermission() async {
        await withCheckedContinuation { continuation in
            let manager = CMMotionActivityManager()
            manager.queryActivityStarting(from: Date(), to: Date(), to: .main) { _, error in
                if error == nil {
                    self.motionStatus = .granted
                } else {
                    let nsError = error as NSError?
                    if nsError?.code == Int(CMErrorMotionActivityNotAuthorized.rawValue) {
                        self.motionStatus = .denied
                    } else {
                        self.motionStatus = .granted
                    }
                }
                manager.stopActivityUpdates()
                continuation.resume()
            }
        }
    }

    // MARK: - Finish

    private func finish() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        onDismiss()
    }

    // MARK: - Shared Button

    private func nextButton(label: String, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(theme.bg)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(enabled ? theme.accent : theme.accentDim)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}

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
    // Page 4 state
    @State private var notifEnabled: Bool = false
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
                    languagePage.tag(0)
                    themePage.tag(1)
                    pacePage.tag(2)
                    notifPermsPage.tag(3)
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
                    .fill(theme.accentDim)
                    .frame(height: 2)
                RoundedRectangle(cornerRadius: 1)
                    .fill(theme.accent)
                    .frame(width: geo.size.width * CGFloat(page + 1) / CGFloat(totalPages), height: 2)
                    .animation(.easeInOut(duration: 0.3), value: page)
            }
        }
        .frame(height: 2)
    }

    // MARK: - Page 1: Language

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
            nextButton(label: lm.L("onboarding.next")) { page = 1 }
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

    // MARK: - Placeholders (filled in subsequent tasks)

    private var themePage: some View { Color.clear }
    private var pacePage: some View { Color.clear }
    private var notifPermsPage: some View { Color.clear }

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

    // MARK: - Permission helpers (used by page 4)

    @MainActor
    private func requestAllPermissions() async {
        isRequesting = true
        await HealthKitService.shared.requestPermissions()
        let hkStatus = HKHealthStore().authorizationStatus(for: HKQuantityType(.heartRate))
        healthStatus = hkStatus == .sharingAuthorized ? .granted : .denied

        await withCheckedContinuation { cont in
            let manager = CMMotionActivityManager()
            manager.queryActivityStarting(from: Date(), to: Date(), to: .main) { _, error in
                let nsError = error as NSError?
                self.motionStatus = (nsError?.code == Int(CMErrorMotionActivityNotAuthorized.rawValue)) ? .denied : .granted
                manager.stopActivityUpdates()
                cont.resume()
            }
        }

        if notifEnabled {
            let granted = await NotificationService.requestPermission()
            notifStatus = granted ? .granted : .denied
            if granted {
                let c = Calendar.current.dateComponents([.hour, .minute], from: notifTime)
                NotificationService.scheduleDaily(hour: c.hour ?? 7, minute: c.minute ?? 0)
            } else {
                notifEnabled = false
                profile?.notificationsEnabled = false
                try? ctx.save()
            }
        }
        isRequesting = false
    }

    private func permRow(icon: String, name: String, desc: String, status: PermStatus) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(theme.text)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 15)).foregroundColor(theme.text)
                Text(desc).font(.system(size: 12)).foregroundColor(theme.textDim)
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
        return Text(label).font(.system(size: 12)).foregroundColor(color)
    }
}

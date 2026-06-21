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

    // MARK: - Page 2: Theme

    @State private var selectedThemeIndex: Int = {
        let saved = UserDefaults.standard.string(forKey: "activeThemeId") ?? "moss"
        return ThemeLibrary.all.firstIndex(where: { $0.id == saved }) ?? 0
    }()

    private var themePage: some View {
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
            .padding(.bottom, 28)

            Text(lm.L("onboarding.theme.title"))
                .font(.system(size: 28, weight: .ultraLight))
                .tracking(-0.5)
                .foregroundColor(theme.text)
                .padding(.bottom, 6)

            Text(lm.L("onboarding.theme.subtitle"))
                .font(.system(size: 13))
                .tracking(0.04)
                .foregroundColor(theme.textDim)
                .padding(.bottom, 32)

            themeCarousel
                .padding(.bottom, 12)

            themeDots

            Spacer()
            nextButton(label: lm.L("onboarding.next")) { page = 2 }
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
        }
    }

    private var themeCarousel: some View {
        let slots: [(offset: Int, scale: CGFloat, opacity: Double, width: CGFloat)] = [
            (-2, 0.72, 0.25, 52),
            (-1, 0.84, 0.55, 68),
            ( 0, 1.00, 1.00, 88),
            ( 1, 0.84, 0.55, 68),
            ( 2, 0.72, 0.25, 52),
        ]
        return HStack(spacing: 6) {
            ForEach(slots, id: \.offset) { slot in
                let idx = ((selectedThemeIndex + slot.offset) % ThemeLibrary.all.count + ThemeLibrary.all.count) % ThemeLibrary.all.count
                let t = ThemeLibrary.all[idx]
                themeCard(t, isCenter: slot.offset == 0, width: slot.width)
                    .scaleEffect(slot.scale)
                    .opacity(slot.opacity)
                    .onTapGesture {
                        if slot.offset != 0 {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectTheme(at: idx)
                            }
                        }
                    }
            }
        }
        .frame(height: 100)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.width < -20 {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectTheme(at: (selectedThemeIndex + 1) % ThemeLibrary.all.count)
                        }
                    } else if value.translation.width > 20 {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectTheme(at: (selectedThemeIndex - 1 + ThemeLibrary.all.count) % ThemeLibrary.all.count)
                        }
                    }
                }
        )
    }

    private func themeCard(_ t: ThemeTokens, isCenter: Bool, width: CGFloat) -> some View {
        let barHeight: CGFloat = isCenter ? 9 : 7
        return VStack(spacing: 0) {
            Rectangle()
                .fill(t.bg)
                .frame(width: width, height: isCenter ? 60 : 48)
                .overlay(alignment: .bottom) {
                    HStack(spacing: 1.5) {
                        ForEach(t.bar.indices, id: \.self) { i in
                            Rectangle().fill(t.bar[i]).frame(height: barHeight)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 6)
                }
            Rectangle()
                .fill(t.bg)
                .frame(width: width, height: isCenter ? 22 : 18)
                .overlay {
                    Text(themeDisplayName(t.id))
                        .font(.system(size: isCenter ? 9 : 8, weight: .medium))
                        .foregroundColor(t.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isCenter ? Color.white.opacity(0.55) : Color.clear, lineWidth: 1.5)
        )
    }

    private var themeDots: some View {
        HStack(spacing: 3) {
            ForEach(ThemeLibrary.all.indices, id: \.self) { i in
                let dist = abs(i - selectedThemeIndex)
                RoundedRectangle(cornerRadius: 2)
                    .fill(i == selectedThemeIndex ? theme.accent : theme.text.opacity(0.2))
                    .frame(width: i == selectedThemeIndex ? 14 : (dist == 1 ? 5 : 3), height: 3)
                    .animation(.easeInOut(duration: 0.2), value: selectedThemeIndex)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) { selectTheme(at: i) }
                    }
            }
        }
    }

    private func selectTheme(at index: Int) {
        selectedThemeIndex = index
        let t = ThemeLibrary.all[index]
        themeManager.apply(t.id)
        profile?.activeThemeId = t.id
        try? ctx.save()
    }

    private func themeDisplayName(_ id: String) -> String {
        let map: [String: String] = [
            "obsidian": "Obsidian", "paper": "Paper", "limestone": "Limestone",
            "grove": "Grove", "moss": "Moss & Amber", "mocha": "Mocha",
            "seafloor": "Seafloor", "skyline": "Skyline", "navy": "Deep Navy",
            "lavender": "Lavender Fog", "midnight": "Midnight Mauve",
            "teal": "Teal & Coral", "blush": "Blush Garden",
            "slateRose": "Slate & Rose", "sapphireGold": "Sapphire & Gold",
        ]
        let mapZh: [String: String] = [
            "obsidian": "黑曜", "paper": "白紙", "limestone": "石灰岩",
            "grove": "林間", "moss": "苔蘚琥珀", "mocha": "摩卡",
            "seafloor": "海床", "skyline": "天際", "navy": "深海藍",
            "lavender": "薰衣草霧", "midnight": "午夜藕色",
            "teal": "青與珊瑚", "blush": "胭脂花園",
            "slateRose": "石板玫瑰", "sapphireGold": "藍寶石與金",
        ]
        return lm.language == .traditionalChinese
            ? (mapZh[id] ?? id)
            : (map[id] ?? id.capitalized)
    }

    // MARK: - Placeholders (filled in subsequent tasks)

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

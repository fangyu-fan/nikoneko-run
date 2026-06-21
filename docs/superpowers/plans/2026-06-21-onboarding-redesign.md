# Onboarding Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild onboarding into 4 pages (language → theme → running defaults → notifications+permissions) and extract the welcome animation into a standalone `LaunchScreenView` shown on every cold start.

**Architecture:** `LaunchScreenView` sits at the top of the app in `JogApp.swift`, fading out after 0.8 s before handing off to `ContentView`. `OnboardingView` is rewritten in place — same file, same `onDismiss` contract — with a new `ThemeCarouselPage` and `RunningDefaultsPage` as private sub-views inside the file. No new files except `LaunchScreenView.swift`.

**Tech Stack:** SwiftUI, SwiftData, Lottie (via `LottieCharacterView`), `MetronomeService` (existing), `ThemeManager` (existing), `NotificationService` (existing)

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `nikoneko_run/Features/Launch/LaunchScreenView.swift` | Cold-start animation screen |
| Modify | `nikoneko_run/App/JogApp.swift` | Show `LaunchScreenView` on startup |
| Modify | `nikoneko_run/Features/Onboarding/OnboardingView.swift` | Full rewrite: 4-page flow |
| Modify | `nikoneko_run/Resources/en.lproj/Localizable.strings` | Add new string keys |
| Modify | `nikoneko_run/Resources/zh-Hant.lproj/Localizable.strings` | Add new string keys (zh-Hant) |

---

## Task 1: LaunchScreenView

**Files:**
- Create: `nikoneko_run/Features/Launch/LaunchScreenView.swift`
- Modify: `nikoneko_run/App/JogApp.swift`

- [ ] **Step 1: Create LaunchScreenView.swift**

```swift
import SwiftUI

struct LaunchScreenView: View {
    @Environment(ThemeManager.self) private var themeManager
    let onComplete: () -> Void

    @State private var opacity: Double = 1

    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()
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

                Text("Niko Neko")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundColor(theme.text)
                    .padding(.bottom, 8)

                Text("slow jog · smile pace")
                    .font(.system(size: 13))
                    .tracking(0.5)
                    .foregroundColor(theme.textDim)

                Spacer()
            }
        }
        .opacity(opacity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.3)) { opacity = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onComplete() }
            }
        }
    }
}
```

- [ ] **Step 2: Wire LaunchScreenView into JogApp.swift**

Replace `JogApp.swift` body:

```swift
@State private var showLaunch: Bool = true

var body: some Scene {
    WindowGroup {
        ZStack {
            ContentView()
                .environment(themeManager)
                .environment(languageManager)

            if showLaunch {
                LaunchScreenView { showLaunch = false }
                    .environment(themeManager)
                    .environment(languageManager)
                    .zIndex(1)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.25), value: showLaunch)
    }
    .modelContainer(makeContainer())
}
```

- [ ] **Step 3: Build and run on simulator — verify launch animation plays then fades**

```bash
xcodebuild -project nikoneko_run.xcodeproj -scheme nikoneko_run \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add nikoneko_run/Features/Launch/LaunchScreenView.swift \
        nikoneko_run/App/JogApp.swift
git commit -m "feat(launch): add LaunchScreenView shown on every cold start"
```

---

## Task 2: Add Localizable String Keys

**Files:**
- Modify: `nikoneko_run/Resources/en.lproj/Localizable.strings`
- Modify: `nikoneko_run/Resources/zh-Hant.lproj/Localizable.strings`

- [ ] **Step 1: Add new keys to en.lproj/Localizable.strings**

Add after the existing `onboarding.*` block (after line with `onboarding.perms.cta`):

```
"onboarding.theme.title"             = "your vibe.";
"onboarding.theme.subtitle"          = "pick a colour to run with";
"onboarding.pace.title"              = "set your pace.";
"onboarding.pace.bpm.label"          = "BEATS PER MINUTE";
"onboarding.pace.goal.label"         = "DAILY GOAL";
"onboarding.pace.goal.unit"          = "min";
"onboarding.pace.sound.label"        = "METRONOME SOUND";
"onboarding.notif2.title"            = "stay on track.";
"onboarding.notif2.subtitle"         = "we'll remind you";
"onboarding.notif2.reminder"         = "daily reminder";
"onboarding.notif2.enableInSettings" = "enable in Settings";
"onboarding.perms2.label"            = "APP PERMISSIONS";
```

- [ ] **Step 2: Add new keys to zh-Hant.lproj/Localizable.strings**

Add after the existing `onboarding.*` block:

```
"onboarding.theme.title"             = "選你的風格";
"onboarding.theme.subtitle"          = "選一個顏色一起跑";
"onboarding.pace.title"              = "調整節奏";
"onboarding.pace.bpm.label"          = "每分鐘節拍";
"onboarding.pace.goal.label"         = "每日目標";
"onboarding.pace.goal.unit"          = "分鐘";
"onboarding.pace.sound.label"        = "節拍器音效";
"onboarding.notif2.title"            = "保持節奏";
"onboarding.notif2.subtitle"         = "我們會提醒你";
"onboarding.notif2.reminder"         = "每日提醒";
"onboarding.notif2.enableInSettings" = "請至設定開啟";
"onboarding.perms2.label"            = "應用程式權限";
```

- [ ] **Step 3: Commit**

```bash
git add nikoneko_run/Resources/en.lproj/Localizable.strings \
        nikoneko_run/Resources/zh-Hant.lproj/Localizable.strings
git commit -m "feat(onboarding): add localizable string keys for redesigned pages"
```

---

## Task 3: Rewrite OnboardingView — skeleton + page 1 (Language)

**Files:**
- Modify: `nikoneko_run/Features/Onboarding/OnboardingView.swift`

The existing file is fully replaced. Pages are: `0=language`, `1=theme`, `2=pace`, `3=notif+perms`.

- [ ] **Step 1: Replace OnboardingView.swift with new skeleton + language page**

```swift
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
    // Page 3 state
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
```

- [ ] **Step 2: Build to confirm skeleton compiles**

```bash
xcodebuild -project nikoneko_run.xcodeproj -scheme nikoneko_run \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add nikoneko_run/Features/Onboarding/OnboardingView.swift
git commit -m "feat(onboarding): skeleton 4-page structure + language page"
```

---

## Task 4: Theme Carousel Page

**Files:**
- Modify: `nikoneko_run/Features/Onboarding/OnboardingView.swift` — replace `themePage` placeholder

- [ ] **Step 1: Replace `themePage` placeholder with full implementation**

Replace the line `private var themePage: some View { Color.clear }` with:

```swift
// MARK: - Page 2: Theme

@State private var selectedThemeIndex: Int = {
    let saved = UserDefaults.standard.string(forKey: "activeThemeId") ?? "moss"
    return ThemeLibrary.all.firstIndex(where: { $0.id == saved }) ?? 0
}()

private var themePage: some View {
    VStack(spacing: 0) {
        Spacer()
        // Cat animated in current theme colour
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

        // Half-carousel
        themeCarousel
            .padding(.bottom, 12)

        // 15-dot strip
        themeDots
            .padding(.bottom, 0)

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
    // zh-Hant names
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
```

- [ ] **Step 2: Build and verify**

```bash
xcodebuild -project nikoneko_run.xcodeproj -scheme nikoneko_run \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Run on simulator — swipe carousel, confirm whole page bg + cat colour change**

Launch app on simulator. Skip launch screen, tap through to page 2. Swipe left/right — background, cat colour, and progress bar should all transition with the theme.

- [ ] **Step 4: Commit**

```bash
git add nikoneko_run/Features/Onboarding/OnboardingView.swift
git commit -m "feat(onboarding): add theme carousel page with live full-page preview"
```

---

## Task 5: Running Defaults Page

**Files:**
- Modify: `nikoneko_run/Features/Onboarding/OnboardingView.swift` — replace `pacePage` placeholder

- [ ] **Step 1: Replace `pacePage` placeholder**

Replace `private var pacePage: some View { Color.clear }` with:

```swift
// MARK: - Page 3: Running Defaults

@State private var bpm: Int = 180
@State private var goalMinutes: Int = 20
@State private var selectedSound: SoundType = .wood
@State private var isDraggingBPM: Bool = false

private let previewMetronome = MetronomeService()

private var pacePage: some View {
    VStack(spacing: 0) {
        Spacer()

        Text(lm.L("onboarding.pace.title"))
            .font(.system(size: 28, weight: .ultraLight))
            .tracking(-0.5)
            .foregroundColor(theme.text)
            .padding(.bottom, 32)

        // Cat speed preview
        LottieCharacterView(
            characterId: "loader_cat",
            color: theme.accentMid,
            shadowColor: theme.accentDim,
            bpm: bpm,
            isAnimating: true
        )
        .frame(width: 100, height: 72)
        .padding(.bottom, 24)

        // BPM
        VStack(spacing: 8) {
            Text(lm.L("onboarding.pace.bpm.label"))
                .font(.system(size: 10))
                .tracking(1)
                .foregroundColor(theme.textDim)

            Text("\(bpm)")
                .font(.system(size: 52, weight: .ultraLight))
                .tracking(-2)
                .foregroundColor(theme.text)
                .monospacedDigit()

            bpmSlider
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 28)

        // Goal + Sound side by side
        HStack(alignment: .top, spacing: 24) {
            // Daily goal
            VStack(spacing: 8) {
                Text(lm.L("onboarding.pace.goal.label"))
                    .font(.system(size: 10))
                    .tracking(1)
                    .foregroundColor(theme.textDim)
                HStack(spacing: 12) {
                    stepButton("−") {
                        goalMinutes = max(5, goalMinutes - 5)
                        profile?.dailyGoalMinutes = goalMinutes
                        profile?.defaultDuration = goalMinutes
                        try? ctx.save()
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(goalMinutes)")
                            .font(.system(size: 28, weight: .ultraLight))
                            .foregroundColor(theme.text)
                            .monospacedDigit()
                        Text(lm.L("onboarding.pace.goal.unit"))
                            .font(.system(size: 12))
                            .foregroundColor(theme.textMid)
                    }
                    stepButton("+") {
                        goalMinutes = min(120, goalMinutes + 5)
                        profile?.dailyGoalMinutes = goalMinutes
                        profile?.defaultDuration = goalMinutes
                        try? ctx.save()
                    }
                }
            }

            // Sound
            VStack(spacing: 8) {
                Text(lm.L("onboarding.pace.sound.label"))
                    .font(.system(size: 10))
                    .tracking(1)
                    .foregroundColor(theme.textDim)
                soundSegment
            }
        }
        .padding(.horizontal, 32)

        Spacer()
        nextButton(label: lm.L("onboarding.next")) { page = 3 }
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
    }
    .onAppear {
        bpm = profile?.defaultBPM ?? 180
        goalMinutes = profile?.dailyGoalMinutes ?? 20
        selectedSound = profile?.soundType ?? .wood
    }
}

private var bpmSlider: some View {
    GeometryReader { geo in
        let range: Double = 220 - 140
        let fraction = Double(bpm - 140) / range
        ZStack(alignment: .leading) {
            // track
            Capsule().fill(theme.accentDim).frame(height: 3)
            // fill
            Capsule().fill(theme.accent)
                .frame(width: geo.size.width * CGFloat(fraction), height: 3)
            // thumb
            Circle()
                .fill(theme.text)
                .frame(width: 22, height: 22)
                .offset(x: geo.size.width * CGFloat(fraction) - 11)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let newFraction = min(1, max(0, value.location.x / geo.size.width))
                    bpm = 140 + Int(newFraction * range)
                }
                .onEnded { _ in
                    profile?.defaultBPM = bpm
                    try? ctx.save()
                }
        )
    }
    .frame(height: 22)
}

private var soundSegment: some View {
    let options: [(SoundType, String)] = [
        (.woodLo, lm.L("defaults.sound.woodLo")),
        (.wood,   lm.L("defaults.sound.wood")),
        (.woodHi, lm.L("defaults.sound.woodHi")),
    ]
    return HStack(spacing: 2) {
        ForEach(options, id: \.0) { (type, label) in
            Button {
                selectedSound = type
                profile?.soundType = type
                try? ctx.save()
                // play one-shot preview
                previewMetronome.updateSoundType(type)
                previewMetronome.updateBPM(bpm)
                previewMetronome.start()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    previewMetronome.stop()
                }
            } label: {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(selectedSound == type ? theme.text : theme.textMid)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(selectedSound == type ? theme.card : Color.clear)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }
    .padding(3)
    .background(theme.surface)
    .cornerRadius(10)
    .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.accentDim, lineWidth: 0.5))
}

private func stepButton(_ label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(label)
            .font(.system(size: 18))
            .foregroundColor(theme.text)
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .overlay(Circle().stroke(theme.accentDim, lineWidth: 0.5).frame(width: 32, height: 32))
}
```

- [ ] **Step 2: Build and verify**

```bash
xcodebuild -project nikoneko_run.xcodeproj -scheme nikoneko_run \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Run on simulator — drag BPM slider, confirm cat animates faster/slower**

Navigate to page 3. Drag BPM slider — cat animation speed should visibly change.

- [ ] **Step 4: Commit**

```bash
git add nikoneko_run/Features/Onboarding/OnboardingView.swift
git commit -m "feat(onboarding): add running defaults page with BPM cat-speed feedback"
```

---

## Task 6: Notifications + Permissions Page

**Files:**
- Modify: `nikoneko_run/Features/Onboarding/OnboardingView.swift` — replace `notifPermsPage` placeholder

- [ ] **Step 1: Replace `notifPermsPage` placeholder**

Replace `private var notifPermsPage: some View { Color.clear }` with:

```swift
// MARK: - Page 4: Notifications + Permissions

private var notifPermsPage: some View {
    ScrollView {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

            Text(lm.L("onboarding.notif2.title"))
                .font(.system(size: 28, weight: .ultraLight))
                .tracking(-0.5)
                .foregroundColor(theme.text)
                .padding(.bottom, 6)

            if notifEnabled {
                Text(lm.L("onboarding.notif2.subtitle"))
                    .font(.system(size: 13))
                    .tracking(0.04)
                    .foregroundColor(theme.textDim)
                    .transition(.opacity)
            }

            Spacer().frame(height: 32)

            // Notification card
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "bell")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(theme.text)
                        .frame(width: 24)
                    Text(lm.L("onboarding.notif2.reminder"))
                        .font(.system(size: 16))
                        .foregroundColor(theme.text)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { notifEnabled },
                        set: { newVal in
                            if newVal {
                                Task {
                                    let granted = await NotificationService.requestPermission()
                                    await MainActor.run {
                                        if granted {
                                            notifEnabled = true
                                            notifStatus = .granted
                                            profile?.notificationsEnabled = true
                                            try? ctx.save()
                                        } else {
                                            notifEnabled = false
                                            notifStatus = .denied
                                        }
                                    }
                                }
                            } else {
                                notifEnabled = false
                                notifStatus = .pending
                                profile?.notificationsEnabled = false
                                try? ctx.save()
                            }
                        }
                    ))
                    .tint(theme.accent)
                    .labelsHidden()
                }
                .padding(.vertical, 13)
                .padding(.horizontal, 16)

                if notifEnabled && notifStatus == .granted {
                    Rectangle().fill(theme.accentDim).frame(height: 0.5)
                    DatePicker("", selection: $notifTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .tint(theme.accent)
                        .padding(.horizontal, 16)
                        .onChange(of: notifTime) { _, newTime in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                            profile?.notificationHour = c.hour ?? 7
                            profile?.notificationMinute = c.minute ?? 0
                            try? ctx.save()
                            NotificationService.scheduleDaily(hour: c.hour ?? 7, minute: c.minute ?? 0)
                        }
                }

                if notifStatus == .denied {
                    Rectangle().fill(theme.accentDim).frame(height: 0.5)
                    HStack {
                        Text(lm.L("onboarding.notif2.enableInSettings"))
                            .font(.system(size: 13))
                            .foregroundColor(theme.textDim)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                }
            }
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 32)
            .animation(.easeInOut(duration: 0.25), value: notifEnabled)
            .animation(.easeInOut(duration: 0.25), value: notifStatus)

            Spacer().frame(height: 24)

            // Permissions card
            VStack(spacing: 0) {
                Text(lm.L("onboarding.perms2.label"))
                    .font(.system(size: 10))
                    .tracking(1)
                    .foregroundColor(theme.textDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

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
            }
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 32)

            Spacer().frame(height: 16)

            if healthStatus == .pending || motionStatus == .pending {
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
                .padding(.horizontal, 32)
                .padding(.bottom, 12)
            }

            nextButton(
                label: lm.L("onboarding.cta.start"),
                enabled: !isRequesting
            ) { finish() }
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
        }
    }
}
```

- [ ] **Step 2: Build and verify**

```bash
xcodebuild -project nikoneko_run.xcodeproj -scheme nikoneko_run \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Run on simulator — toggle notification, verify system prompt fires, verify time picker appears**

Navigate to page 4. Tap notification toggle — system permission alert should appear. After granting, wheel date picker should animate in. Tap "Allow All" for HealthKit + Motion.

- [ ] **Step 4: Commit**

```bash
git add nikoneko_run/Features/Onboarding/OnboardingView.swift
git commit -m "feat(onboarding): add notifications + permissions page"
```

---

## Task 7: Remove old Welcome Page wiring + final cleanup

**Files:**
- Modify: `nikoneko_run/Features/Onboarding/OnboardingView.swift` — remove `selectedThemeIndex` initialiser warning if any; confirm `totalPages = 4`
- Modify: `nikoneko_run/App/ContentView.swift` — no changes needed (onDismiss contract unchanged)

- [ ] **Step 1: Verify `totalPages` is 4 and progress bar computes correctly**

In `OnboardingView.swift` confirm:
```swift
private let totalPages = 4
```
Page 0 → 1/4, Page 3 → 4/4. No change needed if already set in Task 3.

- [ ] **Step 2: Build clean + run full onboarding flow on simulator**

```bash
xcodebuild -project nikoneko_run.xcodeproj -scheme nikoneko_run \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  clean build 2>&1 | grep -E "error:|BUILD"
```

Manual check:
1. Fresh install (or reset `hasSeenOnboarding` key) → launch screen plays → fades to onboarding page 1 (Language)
2. Select language → page 2 (Theme) → swipe carousel, background changes
3. Page 3 (Pace) → drag BPM → cat speed changes → tap sound segment → hear preview
4. Page 4 (Notif+Perms) → toggle notification → system prompt → time picker shows
5. Tap "Start running" → main Timer screen appears

- [ ] **Step 3: Commit**

```bash
git add nikoneko_run/Features/Onboarding/OnboardingView.swift \
        nikoneko_run/App/JogApp.swift
git commit -m "feat(onboarding): complete redesign — 4-page flow + LaunchScreenView"
```

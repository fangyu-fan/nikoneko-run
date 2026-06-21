# Onboarding Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 重寫 Onboarding 為 5 頁流程（歡迎→語言→通知→權限→完成），首次啟動直接顯示，同時移除 BLE 功能並修正 Settings 的重新請求邏輯。

**Architecture:** OnboardingView 完全重寫為 5 頁 TabView，ContentView 改成 if/else 而非 fullScreenCover 避免底層首頁閃現。Settings 裡的 HealthKit/Notifications toggle 改為偵測目前授權狀態再決定直接請求或跳系統設定。

**Tech Stack:** SwiftUI, HealthKit, CoreMotion (CMMotionActivityManager), UserNotifications, ActivityKit

---

## 檔案變更清單

| 動作 | 檔案 |
|---|---|
| **完全重寫** | `nikoneko_run/Features/Onboarding/OnboardingView.swift` |
| **修改** | `nikoneko_run/App/ContentView.swift` |
| **修改** | `nikoneko_run/Features/Settings/DataSyncView.swift` |
| **修改** | `nikoneko_run/Features/Settings/NotificationsView.swift` |
| **修改** | `nikoneko_run/Services/HeartRateService.swift` |
| **刪除** | `nikoneko_run/Services/BLEHeartRateManager.swift` |
| **修改** | `nikoneko_run/Core/Models/RunSession.swift`（HRSource enum 移除 `.ble`）|
| **修改** | `nikoneko_run/Resources/en.lproj/Localizable.strings` |
| **修改** | `nikoneko_run/Resources/zh-Hant.lproj/Localizable.strings` |
| **修改** | `nikoneko_run/App/Info.plist` |
| **修改** | `project.yml` |

---

## Task 1：移除 BLE

**Files:**
- Delete: `nikoneko_run/Services/BLEHeartRateManager.swift`
- Modify: `nikoneko_run/Services/HeartRateService.swift`
- Modify: `nikoneko_run/Core/Models/RunSession.swift`
- Modify: `nikoneko_run/App/Info.plist`
- Modify: `project.yml`

- [ ] **Step 1: 刪除 BLEHeartRateManager.swift**

```bash
rm /Users/yvonne_f_fan/fangyu/nikoneko/nikoneko_run/Services/BLEHeartRateManager.swift
```

- [ ] **Step 2: 修改 HeartRateService.swift — 移除 BLE，只保留 HealthKit 路徑**

將 `nikoneko_run/Services/HeartRateService.swift` 中：
- `HRSource` enum 改為只有 `case watch, none`（移除 `case ble`）
- 刪除所有 `BLEHeartRateManager` 相關屬性和呼叫
- `startMonitoring()` 只保留 `startHealthKitQuery()` 路徑
- 若 HealthKit 不可用，`source = .none`

最終的 `HeartRateService.swift`：

```swift
import Foundation
import HealthKit

@Observable
@MainActor
final class HeartRateService {
    enum HRSource: Equatable { case watch, none }

    private(set) var currentHR: Int = 0
    private(set) var avgHR: Int = 0
    private(set) var maxHR: Int = 0
    private(set) var source: HRSource = .none

    private var samples: [Int] = []
    private var anchoredQuery: HKAnchoredObjectQuery?
    private var queryAnchor: HKQueryAnchor?
    private let store = HKHealthStore()

    func startMonitoring() {
        samples = []
        currentHR = 0; avgHR = 0; maxHR = 0; source = .none
        guard HKHealthStore.isHealthDataAvailable() else { return }
        startHealthKitQuery()
    }

    func stopMonitoring() {
        if let q = anchoredQuery { store.stop(q) }
        anchoredQuery = nil
        source = .none
    }

    private func startHealthKitQuery() {
        let type = HKQuantityType(.heartRate)
        let query = HKAnchoredObjectQuery(
            type: type,
            predicate: HKQuery.predicateForSamples(withStart: Date(), end: nil),
            anchor: queryAnchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, newSamples, _, newAnchor, _ in
            Task { @MainActor [weak self] in
                self?.queryAnchor = newAnchor
                self?.processHKSamples(newSamples as? [HKQuantitySample])
            }
        }
        query.updateHandler = { [weak self] _, newSamples, _, newAnchor, _ in
            Task { @MainActor [weak self] in
                self?.queryAnchor = newAnchor
                self?.processHKSamples(newSamples as? [HKQuantitySample])
            }
        }
        anchoredQuery = query
        store.execute(query)
        source = .watch
    }

    private func processHKSamples(_ hkSamples: [HKQuantitySample]?) {
        guard let hkSamples, !hkSamples.isEmpty else { return }
        let unit = HKUnit(from: "count/min")
        hkSamples.map { Int($0.quantity.doubleValue(for: unit)) }.forEach { hr in
            samples.append(hr)
            currentHR = hr
            if hr > maxHR { maxHR = hr }
            avgHR = samples.reduce(0, +) / samples.count
        }
    }
}
```

- [ ] **Step 3: 移除 Info.plist 的 NSBluetoothAlwaysUsageDescription**

編輯 `nikoneko_run/App/Info.plist`，刪除這兩行：
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Niconeko Run connects to heart rate monitors.</string>
```

- [ ] **Step 4: 移除 project.yml 的 NSBluetoothAlwaysUsageDescription**

編輯 `project.yml`，刪除：
```yaml
NSBluetoothAlwaysUsageDescription: "Niconeko Run connects to heart rate monitors."
```

- [ ] **Step 5: xcodegen 重新產生 + build 確認**

```bash
cd /Users/yvonne_f_fan/fangyu/nikoneko
xcodegen generate
xcodebuild -project nikoneko-run.xcodeproj -scheme nikoneko \
  -destination 'generic/platform=iOS' -configuration Debug \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | grep -v "provisioning\|signing\|team\|certificate\|profile\|entitlement\|account"
```

預期輸出：`** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "refactor(ble): remove BLEHeartRateManager, HeartRateService now HK-only"
```

---

## Task 2：新增 Localizable 字串

**Files:**
- Modify: `nikoneko_run/Resources/en.lproj/Localizable.strings`
- Modify: `nikoneko_run/Resources/zh-Hant.lproj/Localizable.strings`

- [ ] **Step 1: 在 en.lproj/Localizable.strings 加入新字串**

在檔案末尾加入（替換現有 `onboarding.*` 區塊）：

```
/* Onboarding */
"onboarding.next"                    = "Next";
"onboarding.cta.start"               = "Start running";

"onboarding.lang.title"              = "Language";

"onboarding.notif.title"             = "Daily reminder";
"onboarding.notif.body"              = "Pick a time and we'll nudge you.";

"onboarding.perms.title"             = "A few permissions";
"onboarding.perms.body"              = "These help us track your runs accurately.";
"onboarding.perms.health.name"       = "Apple Health";
"onboarding.perms.health.desc"       = "Heart rate and workout data";
"onboarding.perms.motion.name"       = "Motion";
"onboarding.perms.motion.desc"       = "Steps and distance";
"onboarding.perms.notif.name"        = "Notifications";
"onboarding.perms.notif.desc"        = "Daily reminder";
"onboarding.perms.notif.skipped"     = "Skipped";
"onboarding.perms.status.pending"    = "Allow";
"onboarding.perms.status.granted"    = "Allowed";
"onboarding.perms.status.denied"     = "Denied";
"onboarding.perms.cta"               = "Allow All";

/* DataSync — HealthKit disabled warning */
"dataSync.healthkit.disabled"        = "Heart rate and workout data won't appear in reports.";
```

- [ ] **Step 2: 在 zh-Hant.lproj/Localizable.strings 加入對應字串**

```
/* Onboarding */
"onboarding.next"                    = "下一步";
"onboarding.cta.start"               = "開始跑步";

"onboarding.lang.title"              = "語言";

"onboarding.notif.title"             = "每日提醒";
"onboarding.notif.body"              = "選一個時間，我們會提醒你。";

"onboarding.perms.title"             = "需要幾個權限";
"onboarding.perms.body"              = "讓記錄更完整。";
"onboarding.perms.health.name"       = "Apple 健康";
"onboarding.perms.health.desc"       = "心率與運動記錄";
"onboarding.perms.motion.name"       = "動作與健身";
"onboarding.perms.motion.desc"       = "步數與距離";
"onboarding.perms.notif.name"        = "通知";
"onboarding.perms.notif.desc"        = "每日提醒";
"onboarding.perms.notif.skipped"     = "已略過";
"onboarding.perms.status.pending"    = "允許";
"onboarding.perms.status.granted"    = "已允許";
"onboarding.perms.status.denied"     = "已拒絕";
"onboarding.perms.cta"               = "允許所有";

/* DataSync — HealthKit disabled warning */
"dataSync.healthkit.disabled"        = "報表將缺少心率與運動資料。";
```

- [ ] **Step 3: Commit**

```bash
git add nikoneko_run/Resources/en.lproj/Localizable.strings \
        nikoneko_run/Resources/zh-Hant.lproj/Localizable.strings
git commit -m "feat(i18n): add onboarding and healthkit-disabled localization strings"
```

---

## Task 3：重寫 OnboardingView

**Files:**
- Rewrite: `nikoneko_run/Features/Onboarding/OnboardingView.swift`

- [ ] **Step 1: 完全重寫 OnboardingView.swift**

```swift
import SwiftUI
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
                // Save notification preference
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

        // 2. Motion (CMMotionActivityManager triggers the system dialog)
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
```

- [ ] **Step 2: Build 確認**

```bash
cd /Users/yvonne_f_fan/fangyu/nikoneko
xcodebuild -project nikoneko-run.xcodeproj -scheme nikoneko \
  -destination 'generic/platform=iOS' -configuration Debug \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | grep -v "provisioning\|signing\|team\|certificate\|profile\|entitlement\|account"
```

預期：`** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add nikoneko_run/Features/Onboarding/OnboardingView.swift
git commit -m "feat(onboarding): rewrite as 5-page flow with language, notif, permissions"
```

---

## Task 4：修改 ContentView — 消除首頁閃現

**Files:**
- Modify: `nikoneko_run/App/ContentView.swift`

- [ ] **Step 1: 修改 ContentView.swift**

將 `fullScreenCover` 改為 if/else render：

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.modelContext) private var ctx
    @Query private var profiles: [UserProfile]
    @State private var timerVM = TimerViewModel()
    @State private var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        if showOnboarding {
            OnboardingView {
                showOnboarding = false
            }
            .environment(themeManager)
            .environment(languageManager)
        } else {
            mainView
        }
    }

    private var mainView: some View {
        NavigationStack {
            ZStack {
                theme.bg.ignoresSafeArea()
                TimerView(vm: timerVM)
                if timerVM.state == .idle {
                    VStack {
                        HStack {
                            NavigationLink {
                                ReportView()
                            } label: {
                                Image(systemName: "chart.bar")
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundColor(theme.text)
                                    .frame(width: 44, height: 44)
                            }
                            Spacer()
                            NavigationLink {
                                SettingsView()
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundColor(theme.text)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 56)
                        Spacer()
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: timerVM.state == .idle)
            .navigationBarHidden(true)
        }
        .onAppear { ensureProfile() }
    }

    private func ensureProfile() {
        guard profiles.isEmpty else {
            if let lang = profiles.first?.language {
                languageManager.apply(lang)
            }
            return
        }
        let profile = UserProfile()
        ctx.insert(profile)
        try? ctx.save()
    }
}
```

- [ ] **Step 2: Build 確認**

```bash
xcodebuild -project nikoneko-run.xcodeproj -scheme nikoneko \
  -destination 'generic/platform=iOS' -configuration Debug \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | grep -v "provisioning\|signing\|team\|certificate\|profile\|entitlement\|account"
```

- [ ] **Step 3: Commit**

```bash
git add nikoneko_run/App/ContentView.swift
git commit -m "fix(onboarding): render as if/else instead of fullScreenCover to prevent main view flash"
```

---

## Task 5：修改 Settings — HealthKit 重新請求邏輯

**Files:**
- Modify: `nikoneko_run/Features/Settings/DataSyncView.swift`

- [ ] **Step 1: 更新 DataSyncView.swift 的 HealthKit toggle**

找到 `DataSyncView` 中 HealthKit toggle 的 `set:` 閉包，替換為：

```swift
actionRow(icon: "arrow.up.doc", label: lm.L("dataSync.row.exportCSV"), color: theme.text) { ... }
// HealthKit toggle set: 改為以下
set: { v in
    if v {
        // 開啟時：偵測目前授權狀態
        Task {
            let store = HKHealthStore()
            guard HKHealthStore.isHealthDataAvailable() else { return }
            let status = store.authorizationStatus(for: HKQuantityType(.heartRate))
            switch status {
            case .notDetermined:
                await HealthKitService.shared.requestPermissions()
                // 讀取最新狀態更新 profile
                let newStatus = store.authorizationStatus(for: HKQuantityType(.heartRate))
                profile?.healthKitEnabled = (newStatus == .sharingAuthorized)
                try? ctx.save()
            case .sharingDenied:
                // 已拒絕 → 跳系統設定
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    await UIApplication.shared.open(url)
                }
            case .sharingAuthorized:
                profile?.healthKitEnabled = true
                try? ctx.save()
            @unknown default:
                break
            }
        }
    } else {
        // 關閉
        profile?.healthKitEnabled = false
        try? ctx.save()
    }
}
```

關閉時在 toggle 下方顯示說明文字。在 `toggleRow` 呼叫後，在同一個 `VStack` 中加入：

```swift
if profile?.healthKitEnabled == false {
    Text(lm.L("dataSync.healthkit.disabled"))
        .font(.system(size: 12))
        .foregroundColor(theme.textDim)
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
}
```

- [ ] **Step 2: Build 確認**

```bash
xcodebuild -project nikoneko-run.xcodeproj -scheme nikoneko \
  -destination 'generic/platform=iOS' -configuration Debug \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | grep -v "provisioning\|signing\|team\|certificate\|profile\|entitlement\|account"
```

- [ ] **Step 3: Commit**

```bash
git add nikoneko_run/Features/Settings/DataSyncView.swift
git commit -m "fix(settings): HealthKit toggle detects auth status before re-requesting, shows warning when disabled"
```

---

## Task 6：修改 Settings — Notifications 重新請求邏輯

**Files:**
- Modify: `nikoneko_run/Features/Settings/NotificationsView.swift`

- [ ] **Step 1: 更新 NotificationsView.swift 的 toggle set:**

```swift
set: { v in
    profile?.notificationsEnabled = v
    try? ctx.save()
    if v {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            switch settings.authorizationStatus {
            case .notDetermined:
                let granted = await NotificationService.requestPermission()
                if granted {
                    NotificationService.scheduleDaily(
                        hour: profile?.notificationHour ?? 7,
                        minute: profile?.notificationMinute ?? 0
                    )
                } else {
                    profile?.notificationsEnabled = false
                    try? ctx.save()
                }
            case .denied:
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    await UIApplication.shared.open(url)
                }
                profile?.notificationsEnabled = false
                try? ctx.save()
            default:
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
```

- [ ] **Step 2: Build + Commit**

```bash
xcodebuild -project nikoneko-run.xcodeproj -scheme nikoneko \
  -destination 'generic/platform=iOS' -configuration Debug \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | grep -v "provisioning\|signing\|team\|certificate\|profile\|entitlement\|account"

git add nikoneko_run/Features/Settings/NotificationsView.swift
git commit -m "fix(settings): notifications toggle detects auth status, opens system settings if denied"
```

---

## Task 7：移除 Location 說明文字（不再使用）

**Files:**
- Modify: `nikoneko_run/App/Info.plist`
- Modify: `project.yml`

- [ ] **Step 1: 從 Info.plist 移除 NSLocationWhenInUseUsageDescription**

```xml
<!-- 刪除這兩行 -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Niconeko Run uses location to track distance.</string>
```

- [ ] **Step 2: 從 project.yml 移除同一行**

刪除：
```yaml
NSLocationWhenInUseUsageDescription: "Niconeko Run uses location to track distance."
```

- [ ] **Step 3: xcodegen + Build + Commit**

```bash
xcodegen generate
xcodebuild -project nikoneko-run.xcodeproj -scheme nikoneko \
  -destination 'generic/platform=iOS' -configuration Debug \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | grep -v "provisioning\|signing\|team\|certificate\|profile\|entitlement\|account"

git add nikoneko_run/App/Info.plist project.yml nikoneko-run.xcodeproj/project.pbxproj
git commit -m "chore: remove unused NSLocationWhenInUseUsageDescription"
```

---

## Self-Review Checklist

- [x] BLE 移除：BLEHeartRateManager.swift 刪除，HeartRateService 只剩 HealthKit，HRSource.ble 移除
- [x] Onboarding 5 頁：歡迎 / 語言 / 通知 / 權限 / 完成按鈕
- [x] ContentView if/else：無 fullScreenCover，不閃現首頁
- [x] 語言選擇：立即套用 lm.apply()
- [x] 通知設定：wheel DatePicker，開關，存入 UserProfile
- [x] 三個權限：HealthKit、Motion（CMMotionActivityManager）、Notifications（若開啟）
- [x] 每個請求完成後更新 badge 狀態
- [x] Settings HealthKit toggle：notDetermined→請求 / denied→系統設定
- [x] Settings Notifications toggle：notDetermined→請求 / denied→系統設定
- [x] HealthKit 關閉說明文字
- [x] 所有新字串有 en + zh-Hant 版本
- [x] Location 不使用移除

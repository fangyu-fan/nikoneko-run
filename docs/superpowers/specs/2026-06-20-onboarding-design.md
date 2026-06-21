# Onboarding Redesign — Spec

Date: 2026-06-20

---

## 目標

- 首次啟動直接顯示 Onboarding，不閃現首頁
- 語言、通知時間在 Onboarding 中設定
- 必要權限在 Onboarding 中一次請求完畢
- 拒絕權限後，Settings 裡再開才重新請求
- 移除 BLE 心率計功能
- 視覺風格：深色 + accent + 角色動畫，有設計感

---

## 畫面結構（5 頁）

### 畫面 1 — 歡迎

- 背景：`theme.bg`
- 中央：`LottieCharacterView(characterId: "loader_cat", color: theme.accentMid, shadowColor: theme.accentDim, bpm: 180, isAnimating: true)` 尺寸 120×88
- 動畫下方：`"Niconeko Run"` — SF Pro，size 32，weight `.ultraLight`，`theme.text`
- 再下方：`"slow jog · smile pace"` — size 13，`theme.textDim`，tracking +0.04em
- 底部：「下一步」按鈕

### 畫面 2 — 語言

- 標題：`"Language / 語言"`，size 22，`theme.text`
- 兩個選項卡：`English` / `繁體中文`
  - 選中：`theme.accent` border + `theme.accent` 文字
  - 未選：`theme.surface` 背景 + `theme.textMid` 文字
- 選擇後立即套用（呼叫 `languageManager.apply()`，同時寫 UserDefaults `activeLanguageCode`）
- 底部：「下一步」

### 畫面 3 — 通知

- Icon：`bell` SF Symbol，size 36，`theme.accent`
- 標題：`"onboarding.notif.title"`（EN: "Daily reminder" / ZH: "每日提醒"）
- 說明：`"onboarding.notif.body"`（EN: "Pick a time and we'll nudge you." / ZH: "選一個時間，我們會提醒你。"）
- `DatePicker` — `.graphical` 風格，只顯示 hour/minute，`theme.accent` tint
  - 預設值：07:00
  - 寫入 `UserProfile.notificationHour` / `notificationMinute`
- Toggle：開/關通知（預設開）
  - 關閉時 DatePicker 變灰 disabled
- 底部：「下一步」（不論開關都可繼續，之後可在 Settings 更改）

### 畫面 4 — 權限

- 標題：`"onboarding.perms.title"`（EN: "A few permissions" / ZH: "需要幾個權限"）
- 說明：`"onboarding.perms.body"`（EN: "These help us track your runs accurately." / ZH: "讓記錄更完整。"）
- 三個權限列（每列：icon + 名稱 + 說明 + 狀態 badge）：
  1. **Health** — `heart` icon — EN: "Heart rate & workouts" / ZH: "心率與運動記錄"
  2. **Motion** — `figure.walk` icon — EN: "Steps & distance" / ZH: "步數與距離"
  3. **Notifications** — `bell` icon — EN: "Daily reminder" / ZH: "每日提醒"（若畫面 3 已關閉通知則顯示為「已略過」）
- 狀態 badge：`未請求` → `已允許 ✓` → `已拒絕`（顏色：`theme.textDim` / `theme.accent` / `Color.orange`）
- 按下「允許」按鈕：**依序**觸發三個系統彈窗（HealthKit → Motion → Notifications）
  - Notifications：若畫面 3 已關閉通知則略過
  - 每個請求完成後更新對應 badge 狀態
- 底部：「開始跑步」— 不論狀態都可按，進入 app

### 進度條

- 畫面頂部固定位置，4 segment 細線（高 2pt，圓角），`theme.accent` 填滿已完成段
- 畫面 1 = 1/4 filled，畫面 2 = 2/4，依此類推

---

## 啟動流程

**修改 `ContentView`：**

```swift
// 改成 if/else render，不用 fullScreenCover
if showOnboarding {
    OnboardingView { showOnboarding = false }
        .environment(themeManager)
        .environment(languageManager)
} else {
    // 現有的 NavigationStack 內容
}
```

`showOnboarding` 初始值：`!UserDefaults.standard.bool(forKey: "hasSeenOnboarding")`

完成 Onboarding 時：寫 `hasSeenOnboarding = true`，並根據通知設定呼叫 `NotificationService.scheduleDaily` 或 `cancel()`。

---

## Settings 裡的重新請求邏輯

### HealthKit Toggle（`DataSyncView`）

- **開啟時的行為：**
  1. 檢查 `HKHealthStore.authorizationStatus(for: HKQuantityType(.heartRate))`
  2. `.notDetermined` → 直接 `requestPermissions()`
  3. `.sharingDenied` → `UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)`
  4. `.sharingAuthorized` → 直接更新 toggle，無需再請求
- **關閉時：** 顯示說明文字（在 toggle 下方）：
  - EN: "Heart rate and workout data won't appear in reports."
  - ZH: "報表將缺少心率與運動資料。"

### Notifications Toggle（`NotificationsView`）

- **開啟時的行為：**
  1. `UNUserNotificationCenter.current().getNotificationSettings`
  2. `.notDetermined` → `requestAuthorization()`
  3. `.denied` → `UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)`
  4. `.authorized` → 直接 schedule，無需再請求
- **關閉時：** 靜默取消，無說明文字

---

## BLE 移除範圍

- 刪除 `nikoneko_run/Services/BLEHeartRateManager.swift`
- 刪除 `HeartRateService` 中所有 BLE 相關程式碼（保留 HealthKit 路徑）
- 移除 `Info.plist` 的 `NSBluetoothAlwaysUsageDescription`
- 移除 `project.yml` 的 `NSBluetoothAlwaysUsageDescription`
- 移除 entitlements 中若有 Bluetooth 相關 capability

---

## 本地化字串（新增）

```
onboarding.notif.title
onboarding.notif.body
onboarding.perms.title
onboarding.perms.body
onboarding.perms.health.name
onboarding.perms.health.desc
onboarding.perms.motion.name
onboarding.perms.motion.desc
onboarding.perms.notif.name
onboarding.perms.notif.skipped
onboarding.perms.status.pending
onboarding.perms.status.granted
onboarding.perms.status.denied
onboarding.perms.cta           （= "Allow"  / "允許"）
onboarding.cta.start           （= "Start"  / "開始跑步"）
dataSync.healthkit.disabled    （HealthKit 關閉說明）
```

---

## 不在此次範圍內

- Location 權限（`NSLocationWhenInUseUsageDescription` 目前沒有實際使用，保留 plist key 但不請求）
- Onboarding 的 skip 功能（沒有 skip，只有「下一步」）
- 重新觀看 Onboarding 的入口

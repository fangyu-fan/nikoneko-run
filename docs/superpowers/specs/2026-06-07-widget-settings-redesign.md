# Widget Settings 頁面重設計

**日期：** 2026-06-07

## 目標

將 Settings > Widget 頁面從「每個 widget 個別選主題色」改為「畫廊預覽 + 參數設定」。Widget 顏色統一跟隨 app 主題，不再個別設定。

---

## 架構

### 整體布局

頁面分兩區（垂直 VStack，不可滾動）：

1. **上半部：水平畫廊**
   - `TabView` with `.page` style，每頁一個 widget preview card
   - 順序：Stat → Heatmap → Bar Chart → Calendar → All Stats（共 5 頁）
   - 底部有系統頁碼指示點（`.indexViewStyle(.page)`）
   - Preview card 使用現有 `widgetPreview()` 邏輯，尺寸放大：Small ~140pt 高，Medium ~110pt 高，Large ~180pt 高
   - Preview 顏色使用 `themeManager.current`（不再讀個別 widget theme key）

2. **下半部：參數設定 + 按鈕**
   - 固定高度區域，內容跟著 TabView 選中頁切換（動畫：`.easeInOut`）
   - Widget 名稱 + size badge
   - 參數 picker（見下方各 widget 說明）
   - 「＋ 加入主畫面」按鈕

---

## 各 Widget 的可設定參數

| Widget | 參數 |
|--------|------|
| StatWidget | Metric（Streak / Duration / Distance / Calories / Steps / Runs）+ Period（Today / Week / Month / Year） |
| HeatmapWidget | 無參數，顯示說明：「顯示本年度每日活動熱力圖」 |
| BarChartWidget | 無參數，顯示說明：「顯示近期活動長條圖」 |
| CalendarWidget | Metric（同 StatWidget，6 選 1） |
| AllStatsWidget | Period（Today / Week / Month / Year） |

---

## 資料流

### 寫入（app → App Group）

用戶在設定頁調整參數後，立即寫入 App Group UserDefaults：

```
widget.stat.metric     → StatMetric.rawValue (String)
widget.stat.period     → TimePeriod.rawValue (String)
widget.calendar.metric → StatMetric.rawValue (String)
widget.allStats.period → TimePeriod.rawValue (String)
```

寫入後呼叫 `WidgetCenter.shared.reloadAllTimelines()`。

### 讀取（Widget Provider）

各 widget provider 在 `makeEntry` 時，讀取 App Group 對應 key 作為預設值：

```swift
// 例：StatProvider.makeEntry
let metric = AppGroupDefaults.shared.string(forKey: "widget.stat.metric")
    .flatMap { StatMetric(rawValue: $0) } ?? .streak
```

> WidgetKit AppIntentConfiguration 的用戶設定優先於 App Group 預設值，這是系統行為，不需要額外處理。

### 主題色

移除所有 widget-specific theme key（`widget.streak.themeId`、`widget.allStats.themeId` 等）。

Widget provider 改為讀取 `activeThemeId`（與 app 主題同步）：

```swift
let themeId = AppGroupDefaults.shared.string(forKey: "activeThemeId") ?? "obsidian"
let theme = ThemeLibrary.all.first { $0.id == themeId } ?? ThemeLibrary.obsidian
```

---

## 「加入主畫面」按鈕

1. 嘗試開啟 `widgetkit://` URL scheme（跳轉系統 widget 選擇器）
2. 若 `openURL` 失敗（模擬器或系統不支援），fallback 顯示說明 sheet：
   - 文字引導：「長按主畫面空白處 → 點右上角 ＋ → 搜尋 Nikoneko RUN」
   - 一個「知道了」關閉按鈕

---

## 需要修改的檔案

| 檔案 | 變更 |
|------|------|
| `WidgetSettingsView.swift` | 完整重寫：移除主題選擇器，改為畫廊 + 參數設定布局 |
| `StatProvider` (StatWidget.swift) | `makeEntry` 讀取 `widget.stat.metric` / `widget.stat.period` 作為預設 |
| `CalendarProvider` (CalendarWidget.swift) | `entry(for:)` 讀取 `widget.calendar.metric` 作為預設；移除個別 themeId 讀取 |
| `AllStatsProvider` (AllStatsWidget.swift) | `entry(for:)` 讀取 `widget.allStats.period` 作為預設；移除 `WidgetTheme.load(for:)` |
| `HeatmapWidget.swift` | 移除個別 themeId，改讀 `activeThemeId` |
| `BarChartWidget.swift` | 同上 |
| `AppGroupDefaults.swift` | （可選）新增讀取 helper，減少重複程式碼 |

---

## 不在範圍內

- StreakWidget、TodayDurationWidget、TodayDistanceWidget、TodayStepsWidget 已被 StatWidget 取代，WidgetSettingsView 中的這些舊 entry 一併移除
- Widget 個別主題 key（`widget.streak.themeId` 等）從 App Group 讀取端移除，但不主動清除已存在的舊值

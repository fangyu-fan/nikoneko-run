# NIKO NEKO — Widget System PRD

> Widget spec v3.0 · iOS 17+ · WidgetKit + AppIntent
> UI 外觀以 `NikoNeko_Widgets_All.html` 為實作參考基準

---

## Widget 總覽

| # | Widget | Size | 長按設定 |
|---|--------|------|----------|
| 1 | Stat | Small (2×2) | Metric + Period |
| 2 | Heatmap | Medium (4×2) | Metric |
| 3 | Bar Chart | Medium (4×2) | Metric |
| 4 | Calendar Heatmap | Large (4×4) | Metric |
| 5 | All Stats | Large (4×4) | Period |

---

## 1. Stat Widget — Small

### 外觀（參考 NikoNeko_Widgets_All.html → Small Widgets 區塊）

```
┌─────────────────────┐
│                [ico]│  ← 右上 SF Symbol 26pt light stroke #c8c8c8
│                     │
│  3.5       hrs      │  ← 數字 ultralight + 單位 14pt，baseline 對齊，gap 5pt
│                     │
│  Duration per week  │  ← 10pt #bbb
└─────────────────────┘
```

字體縮放規則：
- 預設：48pt
- 4 位數以上（3.9k、14.4）：44pt
- 5 位數以上（23.6k）：36pt，minimumScaleFactor(0.5)
- 數字與單位中間空格 5pt

SF Symbol 對應：

| Metric | SF Symbol |
|--------|-----------|
| Streak | `flame` |
| Duration | `clock` |
| Distance | `location` |
| Calories | `flame` |
| Steps | `figure.walk` |
| Runs | `figure.run` |

底部標籤：Streak → "Streak"，其他 → "{Metric} per {period}"

### AppIntent

```swift
struct StatWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Stat"

    @Parameter(title: "Metric", default: .duration)
    var metric: StatMetric

    @Parameter(title: "Period", default: .week)
    var period: TimePeriod

    static var parameterSummary: some ParameterSummary {
        When(\.$metric, .equalTo, .streak) {
            Summary("Show \(\.$metric)")
        } otherwise: {
            Summary("Show \(\.$metric) for \(\.$period)")
        }
    }
}
```

---

## 2. Heatmap Widget — Medium

### 外觀（參考 NikoNeko_Widgets_All.html → Medium Widgets 左）

- 標題：`"HEATMAP · {METRIC}"` 9pt uppercase
- 日期標籤欄：Mon–Sun，7pt，固定寬 22pt
- 月份標籤列：每欄第一週顯示月份縮寫
- 格子：aspect-ratio 1:1，圓角 2pt，gap 1.5pt
- 欄數：18（最近 4 個月，永遠是 Current）
- 色階：5 段，來自 active theme bar[0]–bar[4]

Long-press 設定：Metric（Duration / Distance / Calories / Steps / Runs）

---

## 3. Bar Chart Widget — Medium

### 外觀（參考 NikoNeko_Widgets_All.html → Medium Widgets 右）

- 標題：`"CHART · {METRIC}"` 9pt uppercase
- Bar 寬：4pt，圓角 top 2pt
- Bar 顏色：無資料 #e0e0e0，一般 #888，今天 #111
- Y 軸：3 個標籤，7pt，自動縮放
- X 軸：S M T W T F S，右下角 "day" 單位
- 顯示：本週 7 天

Long-press 設定：Metric（Duration / Distance / Calories / Steps / Runs）

---

## 4. Calendar Heatmap Widget — Large

### 外觀（參考 NikoNeko_Widgets_All.html → Large Widgets 左）

- 標題：`"CHART · {METRIC}"` 9pt uppercase
- 7 欄（Mon–Sun），每格 aspect-ratio 1:1，圓角 8pt，gap 5pt
- 左上：日期數字 9pt
- 中下：metric 數值 12pt weight 200
- 無資料格：#ebebeb，日期 #d0d0d0
- 未來日期：#ebebeb，無數值顯示
- 色階 5 段配合 theme

Long-press 設定：Metric（Duration / Distance / Calories / Steps / Runs）

---

## 5. All Stats Widget — Large

### 外觀（參考 NikoNeko_Widgets_All.html → Large Widgets 右）

Hero 區：
- Label："DURATION" 10pt uppercase #bbb
- "total" prefix：16pt weight 300 #aaa
- 數字：64pt weight 200 #111，letter-spacing -3pt
- 單位：18pt weight 300 #aaa

Summary 3×2 格（固定，不可設定）：
Distance / Calories / Steps / Avg HR / Max HR / Runs

每格：
- 背景：#ebebeb，圓角 12pt
- 數值：20pt weight 200 #111
- 單位：11pt weight 300 #aaa（inline）
- 底部：SVG icon 12pt + 標籤 9pt #bbb

Long-press 設定：Period（Day / Week / Month / Year）

---

## 共用 Data Layer

App Group：`group.com.yourname.nikoneko`

寫入時機：跑步結束後、App 前台時 → `WidgetCenter.shared.reloadAllTimelines()`
背景定期刷新：`.after(nextHour)`

---

## 主題色同步

```swift
let themeId = AppGroupDefaults.shared.string(forKey: "activeThemeId") ?? "obsidian"
let theme = ThemeLibrary.all.first { $0.id == themeId } ?? ThemeLibrary.obsidian
let color = theme.bar[level]
```

---

## Localization

| 元素 | EN | 繁中 |
|------|----|------|
| Streak | Streak | 連勝 |
| Duration | Duration | 時長 |
| Distance | Distance | 距離 |
| Calories | Calories | 熱量 |
| Steps | Steps | 步數 |
| Runs | Runs | 次數 |
| per day | per day | 每日 |
| per week | per week | 每週 |
| per month | per month | 每月 |
| per year | per year | 每年 |
| total | total | 總計 |
| Summary | Summary | 摘要 |

# Widget Settings 頁面重設計 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 將 Settings > Widget 頁面改為水平畫廊 + 參數設定，移除每個 widget 的獨立主題選擇器，統一跟隨 app 主題色。

**Architecture:** `WidgetSettingsView` 完整重寫為兩區布局：上方 TabView 水平畫廊（5 個 widget preview），下方固定區域顯示選中 widget 的 metric/period picker 和「加入主畫面」按鈕。參數偏好寫入 App Group UserDefaults；各 widget provider 讀取這些 key 作為預設值。

**Tech Stack:** SwiftUI, WidgetKit, AppIntents, App Group UserDefaults（suite `group.com.fangyu.nikoneko-run`）

---

## 檔案變更總覽

| 檔案 | 動作 | 說明 |
|------|------|------|
| `nikoneko/Features/Settings/WidgetSettingsView.swift` | 重寫 | 移除主題選擇器，改為畫廊 + 參數設定布局 |
| `nikoneko/Widgets/StatWidget.swift` | 修改 | `StatProvider.makeEntry` 讀取 `widget.stat.metric` / `widget.stat.period` |
| `nikoneko/Widgets/CalendarWidget.swift` | 修改 | `CalendarProvider.entry(for:)` 讀取 `widget.calendar.metric`；移除個別 themeId |
| `nikoneko/Widgets/AllStatsWidget.swift` | 修改 | `AllStatsProvider.entry(for:)` 讀取 `widget.allStats.period`；移除 `WidgetTheme.load` |
| `nikoneko/Widgets/HeatmapWidget.swift` | 修改 | `makeEntry` 改用 `WidgetSharedData.loadTheme()` 取代 `WidgetTheme.load(for:)` |
| `nikoneko/Widgets/BarChartWidget.swift` | 修改 | `build(metric:)` 改用 `WidgetSharedData.loadTheme()` 取代 `WidgetTheme.load(for:)` |

---

## Task 1: Widget Provider — 統一主題讀取

**目的：** 讓 HeatmapWidget 和 BarChartWidget 的 provider 改用 `activeThemeId`（透過現有的 `WidgetSharedData.loadTheme()`），移除個別 `widget.*.themeId` 的依賴。

**Files:**
- Modify: `nikoneko/Widgets/HeatmapWidget.swift:43-51`
- Modify: `nikoneko/Widgets/BarChartWidget.swift:62-100`

- [ ] **Step 1: 修改 HeatmapProvider.makeEntry — 移除 WidgetTheme.load(for:)**

在 `HeatmapWidget.swift` 的 `makeEntry(for:)` 函式，將 theme 讀取改為：

```swift
private func makeEntry(for configuration: HeatmapWidgetIntent) -> HeatmapEntry {
    let theme = WidgetSharedData.loadTheme()
    return HeatmapEntry(
        date: Date(),
        summaries: AppGroupDefaults.loadSummaries(),
        metric: configuration.metric,
        theme: theme
    )
}
```

- [ ] **Step 2: 修改 BarChartProvider.build — 移除 WidgetTheme.load(for:)**

在 `BarChartWidget.swift` 的 `build(metric:)` 函式，第一行改為：

```swift
let theme = WidgetSharedData.loadTheme()
```

（刪除原本的 `let theme = WidgetTheme.load(for: "widget.barChart.themeId")`）

- [ ] **Step 3: 確認 build 成功（不需執行 test，只確認 Xcode 無編譯錯誤）**

在終端機執行：
```bash
cd /Users/yvonne_f_fan/fangyu/nikoneko
xcodebuild -scheme nikoneko -destination "platform=iOS Simulator,name=iPhone 16" build 2>&1 | tail -20
```

預期最後幾行有 `BUILD SUCCEEDED`，無新增錯誤。

- [ ] **Step 4: Commit**

```bash
git add nikoneko/Widgets/HeatmapWidget.swift nikoneko/Widgets/BarChartWidget.swift
git commit -m "refactor(widgets): use activeThemeId for Heatmap and BarChart providers"
```

---

## Task 2: Widget Provider — StatWidget 讀取 App Group 偏好

**目的：** `StatProvider.makeEntry` 在用戶未透過 WidgetKit 設定 AppIntent 時，從 App Group 讀取偏好的 metric 和 period。

**Files:**
- Modify: `nikoneko/Widgets/StatWidget.swift:43-62`

背景知識：WidgetKit `AppIntentConfiguration` 的 `configuration` 參數是用戶在主畫面長按 widget 後設定的值，優先於任何 App Group 預設值。因此 `configuration.metric` 和 `configuration.period` 永遠是正確的顯示值。我們要做的是：讓 intent 的 **default** 反映 App Group 的偏好，但 AppIntent 本身的預設值是靜態的，所以我們不在 provider 層改預設——而是在 UI 層寫入，讓 provider 的 `configuration` 參數自然帶入用戶選的值。

實際上，AppIntentConfiguration 的 configuration 永遠是最新的用戶選擇（包含 WidgetKit 在長按時讀到的 intent 值）。我們只需要讓 `WidgetSettingsView` 寫入 App Group，然後在 `StatProvider.timeline` 裡，當 provider 被 app 主動呼叫 `reloadAllTimelines()` 時，使用 App Group 的值 rebuild entry。

修改方式：`makeEntry` 忽略 `configuration` 的 metric/period，直接從 App Group 讀取（因為 WidgetSettingsView 會負責寫入）。但 AppIntentConfiguration 本身的 widget-level 設定（用戶長按 widget 設定的）依然優先——方法是：優先用 configuration 的值，如果 intent 的 period 是預設的 `.week` 且 App Group 有值，則用 App Group。

更簡單的設計（避免優先級衝突）：**provider 直接從 App Group 讀取 metric/period，不用 configuration 的值**。長按 widget 設定的 AppIntent 仍然由 iOS 系統管理，那是個別 widget 實例的設定，不影響我們在 app 內的全局偏好設定。兩者各自獨立。

- [ ] **Step 1: 修改 StatProvider.makeEntry**

在 `StatWidget.swift` 的 `makeEntry(metric:period:theme:)` 調用端（`snapshot` 和 `timeline`），改為從 App Group 讀取：

```swift
func snapshot(for configuration: StatWidgetIntent, in context: Context) async -> StatEntry {
    let theme = WidgetSharedData.loadTheme()
    let metric = AppGroupDefaults.shared.string(forKey: "widget.stat.metric")
        .flatMap { StatMetric(rawValue: $0) } ?? configuration.metric
    let period = AppGroupDefaults.shared.string(forKey: "widget.stat.period")
        .flatMap { TimePeriod(rawValue: $0) } ?? configuration.period
    return makeEntry(metric: metric, period: period, theme: theme)
}

func timeline(for configuration: StatWidgetIntent, in context: Context) async -> Timeline<StatEntry> {
    let theme = WidgetSharedData.loadTheme()
    let metric = AppGroupDefaults.shared.string(forKey: "widget.stat.metric")
        .flatMap { StatMetric(rawValue: $0) } ?? configuration.metric
    let period = AppGroupDefaults.shared.string(forKey: "widget.stat.period")
        .flatMap { TimePeriod(rawValue: $0) } ?? configuration.period
    let entry = makeEntry(metric: metric, period: period, theme: theme)
    let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
    return Timeline(entries: [entry], policy: .after(nextRefresh))
}
```

- [ ] **Step 2: Commit**

```bash
git add nikoneko/Widgets/StatWidget.swift
git commit -m "feat(stat-widget): read metric/period from App Group defaults"
```

---

## Task 3: Widget Provider — CalendarWidget 讀取 App Group 偏好 + 統一主題

**Files:**
- Modify: `nikoneko/Widgets/CalendarWidget.swift:34-39`

- [ ] **Step 1: 修改 CalendarProvider.entry(for:)**

```swift
private func entry(for config: CalendarWidgetIntent) -> CalendarEntry {
    let theme = WidgetSharedData.loadTheme()
    let metric = AppGroupDefaults.shared.string(forKey: "widget.calendar.metric")
        .flatMap { StatMetric(rawValue: $0) } ?? config.metric
    return CalendarEntry(date: Date(), summaries: AppGroupDefaults.loadSummaries(),
                         metric: metric, theme: theme)
}
```

- [ ] **Step 2: Commit**

```bash
git add nikoneko/Widgets/CalendarWidget.swift
git commit -m "feat(calendar-widget): read metric from App Group defaults, use activeThemeId"
```

---

## Task 4: Widget Provider — AllStatsWidget 讀取 App Group 偏好 + 統一主題

**Files:**
- Modify: `nikoneko/Widgets/AllStatsWidget.swift:52-119`

- [ ] **Step 1: 修改 AllStatsProvider.entry(for:)**

在 `entry(for:)` 函式開頭兩行改為：

```swift
private func entry(for configuration: AllStatsWidgetIntent) -> AllStatsEntry {
    let theme = WidgetSharedData.loadTheme()
    let period = AppGroupDefaults.shared.string(forKey: "widget.allStats.period")
        .flatMap { TimePeriod(rawValue: $0) } ?? configuration.period
    let summaries = AppGroupDefaults.loadSummaries()
    let filtered = Self.filter(summaries, for: period)
    // ... 以下其餘計算不變，只是 configuration.period 全部換成 period ...
```

注意：`entry` 回傳時 `period: period`（不是 `configuration.period`）。

- [ ] **Step 2: Commit**

```bash
git add nikoneko/Widgets/AllStatsWidget.swift
git commit -m "feat(allstats-widget): read period from App Group defaults, use activeThemeId"
```

---

## Task 5: WidgetSettingsView — 完整重寫

**目的：** 移除主題選擇器，改為水平畫廊（TabView）+ 參數設定區 + 加入主畫面按鈕。

**Files:**
- Modify: `nikoneko/Features/Settings/WidgetSettingsView.swift` (完整重寫)

- [ ] **Step 1: 重寫 WidgetSettingsView.swift**

以下為完整新版程式碼，替換整個檔案：

```swift
import SwiftUI
import WidgetKit

struct WidgetSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    private var theme: ThemeTokens { themeManager.current }

    // Gallery selection
    @State private var selectedIndex: Int = 0

    // Per-widget settings stored in App Group
    @State private var statMetric: StatMetric = {
        AppGroupDefaults.shared.string(forKey: "widget.stat.metric")
            .flatMap { StatMetric(rawValue: $0) } ?? .streak
    }()
    @State private var statPeriod: TimePeriod = {
        AppGroupDefaults.shared.string(forKey: "widget.stat.period")
            .flatMap { TimePeriod(rawValue: $0) } ?? .week
    }()
    @State private var calendarMetric: StatMetric = {
        AppGroupDefaults.shared.string(forKey: "widget.calendar.metric")
            .flatMap { StatMetric(rawValue: $0) } ?? .duration
    }()
    @State private var allStatsPeriod: TimePeriod = {
        AppGroupDefaults.shared.string(forKey: "widget.allStats.period")
            .flatMap { TimePeriod(rawValue: $0) } ?? .week
    }()

    @State private var showAddInstructions: Bool = false

    private let widgetDefs: [(name: String, nameZh: String, size: String, kind: String)] = [
        ("Stat",        "數據",     "Small",  "StatWidget"),
        ("Heatmap",     "熱力圖",   "Medium", "HeatmapWidget"),
        ("Bar Chart",   "長條圖",   "Medium", "BarChartWidget"),
        ("Calendar",    "月曆",     "Large",  "CalendarWidget"),
        ("All Stats",   "所有數據", "Large",  "AllStatsWidget"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Gallery
            TabView(selection: $selectedIndex) {
                ForEach(widgetDefs.indices, id: \.self) { i in
                    let w = widgetDefs[i]
                    galleryCard(w, index: i)
                        .tag(i)
                        .padding(.horizontal, 18)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: galleryHeight)
            .animation(.easeInOut, value: selectedIndex)

            Divider()
                .background(theme.surface)
                .padding(.top, 8)

            // MARK: Settings area
            VStack(alignment: .leading, spacing: 16) {
                parameterSection
                addToHomeButton
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 24)

            Spacer()
        }
        .background(theme.bg.ignoresSafeArea())
        .id(lm.version)
        .navigationTitle(lm.L("widget.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddInstructions) {
            addInstructionsSheet
        }
    }

    // MARK: - Gallery Card

    private func galleryCard(
        _ w: (name: String, nameZh: String, size: String, kind: String),
        index: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(lm.language == .traditionalChinese ? w.nameZh : w.name)
                    .font(.system(size: 15))
                    .foregroundColor(theme.text)
                Text(w.size)
                    .font(.system(size: 11))
                    .foregroundColor(theme.textMid)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(theme.card).cornerRadius(6)
                Spacer()
            }
            widgetPreview(kind: w.kind, widgetTheme: theme)
                .frame(height: previewHeight(size: w.size))
                .cornerRadius(12)
                .clipped()
        }
        .padding(14)
        .background(theme.surface)
        .cornerRadius(14)
    }

    private func previewHeight(size: String) -> CGFloat {
        switch size {
        case "Large":  return 180
        case "Medium": return 110
        default:       return 140
        }
    }

    private var galleryHeight: CGFloat {
        let current = widgetDefs[selectedIndex]
        return previewHeight(size: current.size) + 80 // card padding + label
    }

    // MARK: - Parameter Section

    @ViewBuilder
    private var parameterSection: some View {
        switch selectedIndex {
        case 0: // StatWidget
            VStack(alignment: .leading, spacing: 10) {
                pickerRow(
                    label: lm.language == .traditionalChinese ? "指標" : "Metric",
                    options: StatMetric.allCases,
                    selected: $statMetric,
                    label: { metricLabel($0) }
                ) { value in
                    AppGroupDefaults.shared.set(value.rawValue, forKey: "widget.stat.metric")
                    WidgetCenter.shared.reloadAllTimelines()
                }
                pickerRow(
                    label: lm.language == .traditionalChinese ? "時間範圍" : "Period",
                    options: TimePeriod.allCases,
                    selected: $statPeriod,
                    label: { periodLabel($0) }
                ) { value in
                    AppGroupDefaults.shared.set(value.rawValue, forKey: "widget.stat.period")
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        case 1: // HeatmapWidget
            infoText(lm.language == .traditionalChinese
                ? "顯示近 18 週每日活動熱力圖"
                : "Shows 18-week daily activity heatmap")
        case 2: // BarChartWidget
            infoText(lm.language == .traditionalChinese
                ? "顯示本週每日活動長條圖"
                : "Shows this week's daily activity bar chart")
        case 3: // CalendarWidget
            pickerRow(
                label: lm.language == .traditionalChinese ? "指標" : "Metric",
                options: StatMetric.allCases,
                selected: $calendarMetric,
                label: { metricLabel($0) }
            ) { value in
                AppGroupDefaults.shared.set(value.rawValue, forKey: "widget.calendar.metric")
                WidgetCenter.shared.reloadAllTimelines()
            }
        case 4: // AllStatsWidget
            pickerRow(
                label: lm.language == .traditionalChinese ? "時間範圍" : "Period",
                options: TimePeriod.allCases,
                selected: $allStatsPeriod,
                label: { periodLabel($0) }
            ) { value in
                AppGroupDefaults.shared.set(value.rawValue, forKey: "widget.allStats.period")
                WidgetCenter.shared.reloadAllTimelines()
            }
        default:
            EmptyView()
        }
    }

    private func infoText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(theme.textMid)
    }

    // MARK: - Picker Row

    private func pickerRow<T: Hashable>(
        label: String,
        options: [T],
        selected: Binding<T>,
        label labelFn: @escaping (T) -> String,
        onChange: @escaping (T) -> Void
    ) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(theme.textMid)
            Spacer()
            Menu {
                ForEach(options, id: \.self) { opt in
                    Button(labelFn(opt)) {
                        selected.wrappedValue = opt
                        onChange(opt)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(labelFn(selected.wrappedValue))
                        .font(.system(size: 14))
                        .foregroundColor(theme.text)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(theme.textMid)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(theme.card)
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Add to Home Button

    private var addToHomeButton: some View {
        Button {
            if let url = URL(string: "widgetkit://") {
                UIApplication.shared.open(url) { success in
                    if !success {
                        showAddInstructions = true
                    }
                }
            } else {
                showAddInstructions = true
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle")
                Text(lm.language == .traditionalChinese ? "加入主畫面" : "Add to Home Screen")
                    .font(.system(size: 15))
            }
            .foregroundColor(theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(theme.surface)
            .cornerRadius(10)
        }
    }

    // MARK: - Instructions Sheet

    private var addInstructionsSheet: some View {
        VStack(spacing: 20) {
            Text(lm.language == .traditionalChinese ? "加入主畫面" : "Add to Home Screen")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(theme.text)

            VStack(alignment: .leading, spacing: 12) {
                instructionStep("1", lm.language == .traditionalChinese
                    ? "長按主畫面空白處"
                    : "Long-press an empty area on your Home Screen")
                instructionStep("2", lm.language == .traditionalChinese
                    ? "點右上角「＋」"
                    : "Tap the + button in the top-right corner")
                instructionStep("3", lm.language == .traditionalChinese
                    ? "搜尋「Nikoneko Run」"
                    : "Search for \"Nikoneko Run\"")
                instructionStep("4", lm.language == .traditionalChinese
                    ? "選擇你要的 widget 尺寸"
                    : "Choose your preferred widget size")
            }
            .padding(.horizontal, 24)

            Button(lm.language == .traditionalChinese ? "知道了" : "Got it") {
                showAddInstructions = false
            }
            .foregroundColor(theme.accent)
            .padding(.top, 8)
        }
        .padding(.vertical, 32)
        .presentationDetents([.medium])
        .background(theme.bg)
    }

    private func instructionStep(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.accent)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(theme.text)
        }
    }

    // MARK: - Label Helpers

    private func metricLabel(_ m: StatMetric) -> String {
        let isZh = lm.language == .traditionalChinese
        switch m {
        case .streak:   return isZh ? "連勝天數" : "Streak"
        case .duration: return isZh ? "時長" : "Duration"
        case .distance: return isZh ? "距離" : "Distance"
        case .calories: return isZh ? "卡路里" : "Calories"
        case .steps:    return isZh ? "步數" : "Steps"
        case .runs:     return isZh ? "次數" : "Runs"
        }
    }

    private func periodLabel(_ p: TimePeriod) -> String {
        let isZh = lm.language == .traditionalChinese
        switch p {
        case .today: return isZh ? "今天" : "Today"
        case .week:  return isZh ? "本週" : "This Week"
        case .month: return isZh ? "本月" : "This Month"
        case .year:  return isZh ? "本年" : "This Year"
        }
    }

    // MARK: - Widget Previews (unchanged from original, adapted to use theme param)

    @ViewBuilder
    private func widgetPreview(kind: String, widgetTheme: ThemeTokens) -> some View {
        switch kind {
        case "StatWidget":
            statPreview(widgetTheme: widgetTheme)
        case "HeatmapWidget":
            heatmapPreview(widgetTheme: widgetTheme)
        case "BarChartWidget":
            barChartPreview(widgetTheme: widgetTheme)
        case "CalendarWidget":
            calendarPreview(widgetTheme: widgetTheme)
        default: // AllStatsWidget
            allStatsPreview(widgetTheme: widgetTheme)
        }
    }

    private func statPreview(widgetTheme: ThemeTokens) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("NIKONEKO RUN")
                        .font(.system(size: 7)).tracking(0.8)
                        .foregroundColor(widgetTheme.textMid)
                    Spacer()
                    Image(systemName: "flame")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(widgetTheme.textMid)
                }
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text("12")
                        .font(.system(size: 44, weight: .ultraLight))
                        .foregroundColor(widgetTheme.text)
                    Text("days")
                        .font(.system(size: 9, weight: .light))
                        .foregroundColor(widgetTheme.textMid)
                }
                Text("Streak")
                    .font(.system(size: 9))
                    .foregroundColor(widgetTheme.textMid)
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(widgetTheme.bg)
    }

    private func heatmapPreview(widgetTheme: ThemeTokens) -> some View {
        ZStack(alignment: .topLeading) {
            widgetTheme.bg
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("NIKONEKO RUN")
                        .font(.system(size: 6)).tracking(0.8)
                        .foregroundColor(widgetTheme.textMid)
                    Spacer()
                    Text("2026")
                        .font(.system(size: 6)).tracking(0.8)
                        .foregroundColor(widgetTheme.textMid)
                }
                let cols = 18, rows = 7
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: cols),
                    spacing: 2
                ) {
                    ForEach(0..<cols * rows, id: \.self) { i in
                        let tier = previewTier(index: i, total: cols * rows)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(widgetTheme.bar[tier])
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            .padding(10)
        }
    }

    private func barChartPreview(widgetTheme: ThemeTokens) -> some View {
        ZStack(alignment: .topLeading) {
            widgetTheme.bg
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("NIKONEKO RUN")
                        .font(.system(size: 6)).tracking(0.8)
                        .foregroundColor(widgetTheme.textMid)
                    Spacer()
                    Text("JUN 1 – 7")
                        .font(.system(size: 6)).tracking(0.8)
                        .foregroundColor(widgetTheme.textMid)
                }
                let bars: [Double] = [0.4, 0, 0.7, 0.5, 1.0, 0, 0.6]
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(bars.indices, id: \.self) { i in
                        let h = max(CGFloat(bars[i]) * 50, 3)
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: 1)
                                .fill(i == 4 ? widgetTheme.bar[4] : (bars[i] > 0 ? widgetTheme.bar[2] : widgetTheme.bar[0]))
                                .frame(maxWidth: .infinity)
                                .frame(height: h)
                        }
                        .frame(height: 50)
                    }
                }
            }
            .padding(10)
        }
    }

    private func allStatsPreview(widgetTheme: ThemeTokens) -> some View {
        ZStack(alignment: .topLeading) {
            widgetTheme.bg
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("NIKONEKO RUN")
                        .font(.system(size: 6)).tracking(0.8)
                        .foregroundColor(widgetTheme.textMid)
                    Spacer()
                    Text("THIS WEEK")
                        .font(.system(size: 6)).tracking(0.8)
                        .foregroundColor(widgetTheme.textMid)
                }
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("total")
                        .font(.system(size: 9, weight: .ultraLight))
                        .foregroundColor(widgetTheme.accent)
                    Text("3.5")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundColor(widgetTheme.accent)
                    Text("hrs")
                        .font(.system(size: 10, weight: .ultraLight))
                        .foregroundColor(widgetTheme.accent)
                }
                let stats = [("14.2","km"),("1.4k","kcal"),("21.3k","steps"),("142","avg HR"),("168","max HR"),("5","runs")]
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                    ForEach(Array(stats.enumerated()), id: \.offset) { _, s in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(s.0)
                                .font(.system(size: 12, weight: .ultraLight))
                                .foregroundColor(widgetTheme.text)
                            Text(s.1)
                                .font(.system(size: 6))
                                .foregroundColor(widgetTheme.textDim)
                        }
                        .padding(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(widgetTheme.card)
                        .cornerRadius(6)
                    }
                }
            }
            .padding(10)
        }
    }

    private func calendarPreview(widgetTheme: ThemeTokens) -> some View {
        ZStack(alignment: .topLeading) {
            widgetTheme.bg
            VStack(spacing: 2) {
                HStack {
                    Text("NIKONEKO RUN")
                        .font(.system(size: 5)).tracking(0.8)
                        .foregroundColor(widgetTheme.textMid)
                    Spacer()
                    Text("June 2026")
                        .font(.system(size: 5)).tracking(0.8)
                        .foregroundColor(widgetTheme.textMid)
                }
                .padding(.bottom, 2)
                HStack {
                    ForEach(["M","T","W","T","F","S","S"], id: \.self) { d in
                        Text(d)
                            .font(.system(size: 5))
                            .foregroundColor(widgetTheme.textDim)
                            .frame(maxWidth: .infinity)
                    }
                }
                ForEach(0..<4) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<7) { col in
                            let n = row * 7 + col + 1
                            ZStack {
                                if n <= 30 {
                                    let tier = previewTier(index: n, total: 30)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(widgetTheme.cal[tier])
                                    Text("\(n)")
                                        .font(.system(size: 4))
                                        .foregroundColor(widgetTheme.text.opacity(tier > 0 ? 0.8 : 0.4))
                                } else {
                                    Color.clear
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
            .padding(8)
        }
    }

    private func previewTier(index: Int, total: Int) -> Int {
        let wave = sin(Double(index) / Double(total) * .pi * 4 + 1.0)
        let mapped = (wave + 1.0) / 2.0
        return min(4, Int(mapped * 5))
    }
}
```

- [ ] **Step 2: 確認 build 成功**

```bash
xcodebuild -scheme nikoneko -destination "platform=iOS Simulator,name=iPhone 16" build 2>&1 | tail -20
```

預期：`BUILD SUCCEEDED`。若有 compile error，修正後再繼續。

常見問題：
- `pickerRow` 的 `label:` 參數標籤重複 → 第一個是外部 label，第二個是 closure 的 `label:` 參數，需改為不同的外部名稱（見下方修正）

若出現 `error: argument labels '(label:options:selected:label:onChange:)' do not match`，將兩個 `pickerRow` 呼叫的第二個 `label:` 改為 `display:`，並修改函式簽名：

```swift
private func pickerRow<T: Hashable>(
    label: String,
    options: [T],
    selected: Binding<T>,
    display: @escaping (T) -> String,
    onChange: @escaping (T) -> Void
) -> some View {
    HStack {
        Text(label)
            .font(.system(size: 14))
            .foregroundColor(theme.textMid)
        Spacer()
        Menu {
            ForEach(options, id: \.self) { opt in
                Button(display(opt)) {
                    selected.wrappedValue = opt
                    onChange(opt)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(display(selected.wrappedValue))
                    .font(.system(size: 14))
                    .foregroundColor(theme.text)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(theme.textMid)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(theme.card)
            .cornerRadius(8)
        }
    }
}
```

並更新所有呼叫端的 `label:` → `display:`。

- [ ] **Step 3: Commit**

```bash
git add nikoneko/Features/Settings/WidgetSettingsView.swift
git commit -m "feat(widget-settings): gallery layout with per-widget params and add-to-home button"
```

---

## Task 6: 動態畫廊高度修正

**目的：** `galleryHeight` 需要在 TabView page 切換時動態更新，避免不同尺寸 widget 切換時畫廊高度固定不變。

**Files:**
- Modify: `nikoneko/Features/Settings/WidgetSettingsView.swift`

- [ ] **Step 1: 確認切換不同 widget 時畫廊高度是否正確**

在模擬器上執行 app，進入 Settings > Widget，左右滑動 TabView，確認：
- Small widget（Stat）顯示時高度 ~220pt
- Medium widget（Heatmap / Bar Chart）顯示時高度 ~190pt
- Large widget（Calendar / All Stats）顯示時高度 ~260pt

若高度切換時有跳動或裁切，調整 `galleryHeight` 計算方式：改為固定最大高度 270pt，讓 preview card 自行對齊頂部。

- [ ] **Step 2（如需調整）: 修改 galleryHeight 為固定值**

```swift
private var galleryHeight: CGFloat { 270 }
```

並在 `galleryCard` 的 preview frame 改為 `maxHeight: .infinity`、card 使用 `frame(minHeight: ..., maxHeight: ...)` 讓不同尺寸的 preview 自然填滿。

- [ ] **Step 3: Commit（如有改動）**

```bash
git add nikoneko/Features/Settings/WidgetSettingsView.swift
git commit -m "fix(widget-settings): stabilize gallery height across widget sizes"
```

---

## Task 7: .gitignore — 新增 .superpowers

**Files:**
- Modify: `.gitignore`（如果 `.superpowers/` 尚未在 ignore 清單）

- [ ] **Step 1: 確認 .gitignore**

```bash
grep -n "superpowers" /Users/yvonne_f_fan/fangyu/nikoneko/.gitignore
```

若無輸出，執行 Step 2；若已有，跳過。

- [ ] **Step 2: 加入 .superpowers/**

在 `.gitignore` 末尾加一行：

```
.superpowers/
```

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore: ignore .superpowers brainstorm artifacts"
```

---

## 自我審查（已完成）

**Spec coverage:**
- ✅ 主題色跟隨 app 主題（Tasks 1–4 移除個別 widget theme key）
- ✅ 全部 5 個 widget 顯示（Task 5 widgetDefs 陣列）
- ✅ 水平畫廊布局（Task 5 TabView .page）
- ✅ StatWidget metric + period 設定（Task 5 parameterSection case 0）
- ✅ CalendarWidget metric 設定（Task 5 case 3）
- ✅ AllStatsWidget period 設定（Task 5 case 4）
- ✅ Heatmap / BarChart 無參數，顯示說明文字（Task 5 cases 1–2）
- ✅ 加入主畫面按鈕（Task 5 addToHomeButton）
- ✅ widgetkit:// fallback sheet（Task 5 addInstructionsSheet）
- ✅ App Group 寫入 widget.stat.metric 等 key（Task 5 pickerRow onChange）
- ✅ Widget provider 讀取 App Group 偏好（Tasks 2–4）

**Placeholder scan:** 無 TBD / TODO。

**Type consistency:** `StatMetric`、`TimePeriod`、`AppGroupDefaults`、`WidgetSharedData.loadTheme()` 全程一致。

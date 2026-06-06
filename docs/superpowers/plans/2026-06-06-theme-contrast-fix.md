# Theme Contrast Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修正所有主題在 widget 和 app 內，當文字放在 bar/cal 色塊上顏色相近導致看不見的問題。

**Architecture:** 在 `ThemeTokens` 加入 `onBar` / `onCal` 兩個 token（代表「放在 bar/cal 格子上的文字顏色」），每個主題各自定義正確的對比色。Widget 和 app 中所有 hardcoded `Color(white:)` 文字顏色全部改用 `theme.onBar` / `theme.onCal`，消除 hardcode。

**Tech Stack:** Swift / SwiftUI，無新依賴。

---

## 問題根源

| 問題 | 位置 | 影響主題 |
|------|------|---------|
| `CalendarWidget` 文字用 `Color.white.opacity(0.9)` 放在淺色 cal 格子上 | `CalendarWidget.swift:91` | paper, limestone, grove, moss, skyline, lavender, teal, blush, slateRose, sapphireGold |
| 同上，`level < 3` 時用 `Color(white: 0.733)` 放在深色 cal 格子上 | `CalendarWidget.swift:90` | obsidian, mocha, navy, midnight |
| `HeatmapWidget` 星期/月份標籤用 `Color(white: 0.8)` — 在淺色背景看不清 | `HeatmapWidget.swift:79,89,100` | 所有淺色主題 |
| `AllStatsWidget` 全部用 hardcoded `Color(white: 0.7xx)` | `AllStatsWidget.swift:153,156,161...` | 所有淺色主題 |
| `BarChartWidget` 用 hardcoded `Color(white: 0.8xx)` | `BarChartWidget.swift:151,164...` | 所有淺色主題 |
| `StatWidget` 用 hardcoded `Color(white: 0.7xx)` | `StatWidget.swift:181,196,205` | 所有淺色主題 |

## 解法

加入兩個新 token：
- `onBar: [Color]` — 5 個，對應 `bar[0..4]` 格子上應用的文字/圖標顏色
- `onCal: [Color]` — 5 個，對應 `cal[0..4]` 格子上應用的文字顏色

規則：深色格子用淺色文字，淺色格子用深色文字。

---

## File Map

| 檔案 | 動作 |
|------|------|
| `nikoneko/Core/Theme/ThemeTokens.swift` | 加入 `onBar: [Color]`、`onCal: [Color]` 兩個屬性 |
| `nikoneko/Core/Theme/ThemeLibrary.swift` | 14 個主題各自加入 `onBar` / `onCal` 陣列 |
| `nikoneko/Widgets/CalendarWidget.swift` | `dateColor` / `valColor` 改用 `theme.onCal[level]` |
| `nikoneko/Widgets/HeatmapWidget.swift` | 標籤顏色改用 `theme.textDim` / `theme.textMid` |
| `nikoneko/Widgets/AllStatsWidget.swift` | hardcoded `Color(white:)` 改用 `theme.text` / `theme.textDim` |
| `nikoneko/Widgets/BarChartWidget.swift` | hardcoded `Color(white:)` 改用 `theme.text` / `theme.textDim` / `theme.bar` |
| `nikoneko/Widgets/StatWidget.swift` | hardcoded `Color(white:)` 改用 `theme.text` / `theme.textDim` |

---

## Task 1：在 ThemeTokens 加入 onBar / onCal token

**Files:**
- Modify: `nikoneko/Core/Theme/ThemeTokens.swift`

- [ ] **Step 1: 加入兩個新屬性**

將 `ThemeTokens.swift` 改為：

```swift
import SwiftUI

struct ThemeTokens {
    let id: String
    let bg: Color
    let surface: Color
    let card: Color
    let text: Color
    let textDim: Color
    let textMid: Color
    let accent: Color
    let accentMid: Color
    let accentDim: Color
    let bar: [Color]    // exactly 5: [0]=empty [1]=low [2]=mid [3]=high [4]=peak
    let onBar: [Color]  // exactly 5: text color to use ON bar[i] background
    let cal: [Color]    // exactly 5, same semantics
    let onCal: [Color]  // exactly 5: text color to use ON cal[i] background
    let isDark: Bool
}
```

- [ ] **Step 2: Commit**

```bash
git add nikoneko/Core/Theme/ThemeTokens.swift
git commit -m "feat: add onBar/onCal contrast tokens to ThemeTokens"
```

---

## Task 2：更新 ThemeLibrary — 14 個主題加入 onBar / onCal

**原則：**
- 格子顏色亮度 > 0.5 → 用深色文字（`#1a1a1a`）
- 格子顏色亮度 ≤ 0.5 → 用淺色文字（`#f0ede8` 或白）
- peak（index 4）通常最深或最亮，最需要正確配對

**Files:**
- Modify: `nikoneko/Core/Theme/ThemeLibrary.swift`

- [ ] **Step 1: 更新所有 14 個主題**

用以下完整內容替換 `ThemeLibrary.swift`：

```swift
import SwiftUI

enum ThemeLibrary {
    static let all: [ThemeTokens] = [
        obsidian, paper, limestone,
        grove, moss, mocha, seafloor,
        skyline, navy, lavender, midnight, teal, blush,
        slateRose, sapphireGold
    ]

    // onBar/onCal 對比原則：
    //   bar[i] 深色 → onBar[i] 用淺色 (#f0ede8 或 #ffffff)
    //   bar[i] 淺色 → onBar[i] 用深色 (#1a1a1a 或 theme.text)

    static let obsidian = ThemeTokens(
        id: "obsidian",
        bg:         Color(hex: "0a0a0a"),
        surface:    Color(hex: "141414"),
        card:       Color(hex: "111111"),
        text:       Color(hex: "f0ede8"),
        textDim:    Color(hex: "2e2e2e"),
        textMid:    Color(hex: "666666"),
        accent:     Color(hex: "f0ede8"),
        accentMid:  Color(hex: "888888"),
        accentDim:  Color(hex: "1e1e1e"),
        bar:   [Color(hex:"1a1a1a"), Color(hex:"2e2e2e"), Color(hex:"4a4a4a"), Color(hex:"888888"), Color(hex:"f0ede8")],
        onBar: [Color(hex:"666666"), Color(hex:"888888"), Color(hex:"cccccc"), Color(hex:"1a1a1a"), Color(hex:"1a1a1a")],
        cal:   [Color(hex:"1a1a1a"), Color(hex:"2e2e2e"), Color(hex:"4a4a4a"), Color(hex:"888888"), Color(hex:"f0ede8")],
        onCal: [Color(hex:"666666"), Color(hex:"888888"), Color(hex:"cccccc"), Color(hex:"1a1a1a"), Color(hex:"1a1a1a")],
        isDark: true
    )

    static let paper = ThemeTokens(
        id: "paper",
        bg:         Color(hex: "ffffff"),
        surface:    Color(hex: "f5f5f5"),
        card:       Color(hex: "ebebeb"),
        text:       Color(hex: "111111"),
        textDim:    Color(hex: "aaaaaa"),
        textMid:    Color(hex: "555555"),
        accent:     Color(hex: "111111"),
        accentMid:  Color(hex: "555555"),
        accentDim:  Color(hex: "dddddd"),
        bar:   [Color(hex:"e8e8e8"), Color(hex:"cccccc"), Color(hex:"aaaaaa"), Color(hex:"555555"), Color(hex:"111111")],
        onBar: [Color(hex:"555555"), Color(hex:"333333"), Color(hex:"111111"), Color(hex:"f0f0f0"), Color(hex:"f0f0f0")],
        cal:   [Color(hex:"e8e8e8"), Color(hex:"cccccc"), Color(hex:"aaaaaa"), Color(hex:"555555"), Color(hex:"111111")],
        onCal: [Color(hex:"555555"), Color(hex:"333333"), Color(hex:"111111"), Color(hex:"f0f0f0"), Color(hex:"f0f0f0")],
        isDark: false
    )

    static let limestone = ThemeTokens(
        id: "limestone",
        bg:         Color(hex: "f4f0ea"),
        surface:    Color(hex: "ece8e0"),
        card:       Color(hex: "e4dfd6"),
        text:       Color(hex: "1c1a16"),
        textDim:    Color(hex: "b8b0a0"),
        textMid:    Color(hex: "888070"),
        accent:     Color(hex: "3c3830"),
        accentMid:  Color(hex: "908070"),
        accentDim:  Color(hex: "d0c8b8"),
        bar:   [Color(hex:"e4dfd6"), Color(hex:"ccc4b4"), Color(hex:"a89880"), Color(hex:"806850"), Color(hex:"3c3830")],
        onBar: [Color(hex:"888070"), Color(hex:"555048"), Color(hex:"1c1a16"), Color(hex:"f0ede8"), Color(hex:"f0ede8")],
        cal:   [Color(hex:"e4dfd6"), Color(hex:"ccc4b4"), Color(hex:"a89880"), Color(hex:"806850"), Color(hex:"3c3830")],
        onCal: [Color(hex:"888070"), Color(hex:"555048"), Color(hex:"1c1a16"), Color(hex:"f0ede8"), Color(hex:"f0ede8")],
        isDark: false
    )

    static let grove = ThemeTokens(
        id: "grove",
        bg:         Color(hex: "F5ECD7"),
        surface:    Color(hex: "ebe2cd"),
        card:       Color(hex: "ddd4bc"),
        text:       Color(hex: "353535"),
        textDim:    Color(hex: "5f5f5f"),
        textMid:    Color(hex: "68a67d"),
        accent:     Color(hex: "8FBF9F"),
        accentMid:  Color(hex: "24613b"),
        accentDim:  Color(hex: "c8ddd0"),
        bar:   [Color(hex:"c8ddd0"), Color(hex:"98c8a8"), Color(hex:"68a67d"), Color(hex:"24613b"), Color(hex:"F18F01")],
        onBar: [Color(hex:"353535"), Color(hex:"1a3a28"), Color(hex:"f0ede8"), Color(hex:"f0ede8"), Color(hex:"1a1a1a")],
        cal:   [Color(hex:"c8ddd0"), Color(hex:"98c8a8"), Color(hex:"68a67d"), Color(hex:"24613b"), Color(hex:"F18F01")],
        onCal: [Color(hex:"353535"), Color(hex:"1a3a28"), Color(hex:"f0ede8"), Color(hex:"f0ede8"), Color(hex:"1a1a1a")],
        isDark: false
    )

    static let moss = ThemeTokens(
        id: "moss",
        bg:         Color(hex: "DDDDDD"),
        surface:    Color(hex: "EEEEEE"),
        card:       Color(hex: "e4e4e4"),
        text:       Color(hex: "292524"),
        textDim:    Color(hex: "78716c"),
        textMid:    Color(hex: "658864"),
        accent:     Color(hex: "658864"),
        accentMid:  Color(hex: "4a6848"),
        accentDim:  Color(hex: "B7B78A"),
        bar:   [Color(hex:"B7B78A"), Color(hex:"9aaa70"), Color(hex:"658864"), Color(hex:"4a6848"), Color(hex:"bc6c25")],
        onBar: [Color(hex:"292524"), Color(hex:"1a2a18"), Color(hex:"f0ede8"), Color(hex:"f0ede8"), Color(hex:"f0ede8")],
        cal:   [Color(hex:"B7B78A"), Color(hex:"9aaa70"), Color(hex:"658864"), Color(hex:"4a6848"), Color(hex:"bc6c25")],
        onCal: [Color(hex:"292524"), Color(hex:"1a2a18"), Color(hex:"f0ede8"), Color(hex:"f0ede8"), Color(hex:"f0ede8")],
        isDark: false
    )

    static let mocha = ThemeTokens(
        id: "mocha",
        bg:         Color(hex: "1a1210"),
        surface:    Color(hex: "241a14"),
        card:       Color(hex: "1e1510"),
        text:       Color(hex: "e8d5c0"),
        textDim:    Color(hex: "4a3020"),
        textMid:    Color(hex: "b08060"),
        accent:     Color(hex: "c8956a"),
        accentMid:  Color(hex: "a07048"),
        accentDim:  Color(hex: "301e10"),
        bar:   [Color(hex:"241a14"), Color(hex:"4a2c18"), Color(hex:"7a4828"), Color(hex:"b07040"), Color(hex:"c8956a")],
        onBar: [Color(hex:"b08060"), Color(hex:"e8d5c0"), Color(hex:"e8d5c0"), Color(hex:"1a1210"), Color(hex:"1a1210")],
        cal:   [Color(hex:"241a14"), Color(hex:"4a2c18"), Color(hex:"7a4828"), Color(hex:"b07040"), Color(hex:"c8956a")],
        onCal: [Color(hex:"b08060"), Color(hex:"e8d5c0"), Color(hex:"e8d5c0"), Color(hex:"1a1210"), Color(hex:"1a1210")],
        isDark: true
    )

    static let seafloor = ThemeTokens(
        id: "seafloor",
        bg:         Color(hex: "567189"),
        surface:    Color(hex: "7B8FA1"),
        card:       Color(hex: "6a8098"),
        text:       Color(hex: "F9F9F9"),
        textDim:    Color(hex: "DCDCDC"),
        textMid:    Color(hex: "CFB997"),
        accent:     Color(hex: "f7bf7a"),
        accentMid:  Color(hex: "e8a050"),
        accentDim:  Color(hex: "3E5975"),
        bar:   [Color(hex:"3E5975"), Color(hex:"5a7898"), Color(hex:"7B8FA1"), Color(hex:"f7bf7a"), Color(hex:"CFB997")],
        onBar: [Color(hex:"F9F9F9"), Color(hex:"F9F9F9"), Color(hex:"1a1a1a"), Color(hex:"1a1a1a"), Color(hex:"1a1a1a")],
        cal:   [Color(hex:"3E5975"), Color(hex:"5a7898"), Color(hex:"7B8FA1"), Color(hex:"f7bf7a"), Color(hex:"CFB997")],
        onCal: [Color(hex:"F9F9F9"), Color(hex:"F9F9F9"), Color(hex:"1a1a1a"), Color(hex:"1a1a1a"), Color(hex:"1a1a1a")],
        isDark: true
    )

    static let skyline = ThemeTokens(
        id: "skyline",
        bg:         Color(hex: "fffefb"),
        surface:    Color(hex: "f5f4f1"),
        card:       Color(hex: "e8e6e2"),
        text:       Color(hex: "1d1c1c"),
        textDim:    Color(hex: "313d44"),
        textMid:    Color(hex: "3b3c3d"),
        accent:     Color(hex: "71c4ef"),
        accentMid:  Color(hex: "00668c"),
        accentDim:  Color(hex: "d4eaf7"),
        bar:   [Color(hex:"d4eaf7"), Color(hex:"b6ccd8"), Color(hex:"71c4ef"), Color(hex:"00668c"), Color(hex:"1d1c1c")],
        onBar: [Color(hex:"3b3c3d"), Color(hex:"1d1c1c"), Color(hex:"1d1c1c"), Color(hex:"f0f8ff"), Color(hex:"f0f8ff")],
        cal:   [Color(hex:"d4eaf7"), Color(hex:"b6ccd8"), Color(hex:"71c4ef"), Color(hex:"00668c"), Color(hex:"1d1c1c")],
        onCal: [Color(hex:"3b3c3d"), Color(hex:"1d1c1c"), Color(hex:"1d1c1c"), Color(hex:"f0f8ff"), Color(hex:"f0f8ff")],
        isDark: false
    )

    static let navy = ThemeTokens(
        id: "navy",
        bg:         Color(hex: "0F1C2E"),
        surface:    Color(hex: "1f2b3e"),
        card:       Color(hex: "2a3650"),
        text:       Color(hex: "FFFFFF"),
        textDim:    Color(hex: "e0e0e0"),
        textMid:    Color(hex: "4d648d"),
        accent:     Color(hex: "acc2ef"),
        accentMid:  Color(hex: "3D5A80"),
        accentDim:  Color(hex: "1F3A5F"),
        bar:   [Color(hex:"1F3A5F"), Color(hex:"2e5080"), Color(hex:"4d648d"), Color(hex:"acc2ef"), Color(hex:"cee8ff")],
        onBar: [Color(hex:"e0e0e0"), Color(hex:"e0e0e0"), Color(hex:"ffffff"), Color(hex:"0F1C2E"), Color(hex:"0F1C2E")],
        cal:   [Color(hex:"1F3A5F"), Color(hex:"2e5080"), Color(hex:"4d648d"), Color(hex:"acc2ef"), Color(hex:"cee8ff")],
        onCal: [Color(hex:"e0e0e0"), Color(hex:"e0e0e0"), Color(hex:"ffffff"), Color(hex:"0F1C2E"), Color(hex:"0F1C2E")],
        isDark: true
    )

    static let lavender = ThemeTokens(
        id: "lavender",
        bg:         Color(hex: "F5F3F7"),
        surface:    Color(hex: "E9E4ED"),
        card:       Color(hex: "ddd6e4"),
        text:       Color(hex: "4A4A4A"),
        textDim:    Color(hex: "878787"),
        textMid:    Color(hex: "9A73B5"),
        accent:     Color(hex: "8B5FBF"),
        accentMid:  Color(hex: "61398F"),
        accentDim:  Color(hex: "D6C6E1"),
        bar:   [Color(hex:"D6C6E1"), Color(hex:"c4a8d8"), Color(hex:"9A73B5"), Color(hex:"8B5FBF"), Color(hex:"61398F")],
        onBar: [Color(hex:"4A4A4A"), Color(hex:"2a1a3a"), Color(hex:"ffffff"), Color(hex:"ffffff"), Color(hex:"ffffff")],
        cal:   [Color(hex:"D6C6E1"), Color(hex:"c4a8d8"), Color(hex:"9A73B5"), Color(hex:"8B5FBF"), Color(hex:"61398F")],
        onCal: [Color(hex:"4A4A4A"), Color(hex:"2a1a3a"), Color(hex:"ffffff"), Color(hex:"ffffff"), Color(hex:"ffffff")],
        isDark: false
    )

    static let midnight = ThemeTokens(
        id: "midnight",
        bg:         Color(hex: "151931"),
        surface:    Color(hex: "252841"),
        card:       Color(hex: "2e3150"),
        text:       Color(hex: "E7D1BB"),
        textDim:    Color(hex: "847a86"),
        textMid:    Color(hex: "A096A5"),
        accent:     Color(hex: "A096A5"),
        accentMid:  Color(hex: "c8b4c0"),
        accentDim:  Color(hex: "463e4b"),
        bar:   [Color(hex:"2e3150"), Color(hex:"463e4b"), Color(hex:"706070"), Color(hex:"A096A2"), Color(hex:"E7D1BB")],
        onBar: [Color(hex:"A096A5"), Color(hex:"E7D1BB"), Color(hex:"E7D1BB"), Color(hex:"151931"), Color(hex:"151931")],
        cal:   [Color(hex:"2e3150"), Color(hex:"463e4b"), Color(hex:"706070"), Color(hex:"A096A2"), Color(hex:"E7D1BB")],
        onCal: [Color(hex:"A096A5"), Color(hex:"E7D1BB"), Color(hex:"E7D1BB"), Color(hex:"151931"), Color(hex:"151931")],
        isDark: true
    )

    static let teal = ThemeTokens(
        id: "teal",
        bg:         Color(hex: "F2EFE9"),
        surface:    Color(hex: "e8e5df"),
        card:       Color(hex: "dddad4"),
        text:       Color(hex: "333333"),
        textDim:    Color(hex: "5c5c5c"),
        textMid:    Color(hex: "008b7a"),
        accent:     Color(hex: "00A896"),
        accentMid:  Color(hex: "006b60"),
        accentDim:  Color(hex: "a0d8d0"),
        bar:   [Color(hex:"a0d8d0"), Color(hex:"50c0b0"), Color(hex:"00A896"), Color(hex:"006b60"), Color(hex:"FF6B6B")],
        onBar: [Color(hex:"333333"), Color(hex:"003a34"), Color(hex:"f0f8f7"), Color(hex:"f0f8f7"), Color(hex:"1a1a1a")],
        cal:   [Color(hex:"a0d8d0"), Color(hex:"50c0b0"), Color(hex:"00A896"), Color(hex:"006b60"), Color(hex:"FF6B6B")],
        onCal: [Color(hex:"333333"), Color(hex:"003a34"), Color(hex:"f0f8f7"), Color(hex:"f0f8f7"), Color(hex:"1a1a1a")],
        isDark: false
    )

    static let blush = ThemeTokens(
        id: "blush",
        bg:         Color(hex: "FCEEF5"),
        surface:    Color(hex: "ffffff"),
        card:       Color(hex: "FAD9E6"),
        text:       Color(hex: "292524"),
        textDim:    Color(hex: "78716c"),
        textMid:    Color(hex: "61C0BF"),
        accent:     Color(hex: "61C0BF"),
        accentMid:  Color(hex: "3a9898"),
        accentDim:  Color(hex: "BBDED6"),
        bar:   [Color(hex:"FAD9E6"), Color(hex:"FFB6B9"), Color(hex:"e89090"), Color(hex:"61C0BF"), Color(hex:"3a9898")],
        onBar: [Color(hex:"292524"), Color(hex:"292524"), Color(hex:"292524"), Color(hex:"1a1a1a"), Color(hex:"f0fafa")],
        cal:   [Color(hex:"FAD9E6"), Color(hex:"FFB6B9"), Color(hex:"e89090"), Color(hex:"61C0BF"), Color(hex:"3a9898")],
        onCal: [Color(hex:"292524"), Color(hex:"292524"), Color(hex:"292524"), Color(hex:"1a1a1a"), Color(hex:"f0fafa")],
        isDark: false
    )

    static let slateRose = ThemeTokens(
        id: "slateRose",
        bg:         Color(hex: "F2F2F2"),
        surface:    Color(hex: "e8e8e8"),
        card:       Color(hex: "dcdcdc"),
        text:       Color(hex: "333333"),
        textDim:    Color(hex: "5c5c5c"),
        textMid:    Color(hex: "57687c"),
        accent:     Color(hex: "2C3E50"),
        accentMid:  Color(hex: "57687c"),
        accentDim:  Color(hex: "F7CAC9"),
        bar:   [Color(hex:"F7CAC9"), Color(hex:"e0a8a8"), Color(hex:"b07878"), Color(hex:"926b6a"), Color(hex:"2C3E50")],
        onBar: [Color(hex:"333333"), Color(hex:"333333"), Color(hex:"f0ede8"), Color(hex:"f0ede8"), Color(hex:"f0ede8")],
        cal:   [Color(hex:"F7CAC9"), Color(hex:"e0a8a8"), Color(hex:"b07878"), Color(hex:"926b6a"), Color(hex:"2C3E50")],
        onCal: [Color(hex:"333333"), Color(hex:"333333"), Color(hex:"f0ede8"), Color(hex:"f0ede8"), Color(hex:"f0ede8")],
        isDark: false
    )

    static let sapphireGold = ThemeTokens(
        id: "sapphireGold",
        bg:         Color(hex: "F5F5F5"),
        surface:    Color(hex: "ebebeb"),
        card:       Color(hex: "e0e0e0"),
        text:       Color(hex: "333333"),
        textDim:    Color(hex: "5c5c5c"),
        textMid:    Color(hex: "4e88ca"),
        accent:     Color(hex: "005B99"),
        accentMid:  Color(hex: "003d6b"),
        accentDim:  Color(hex: "b7e9ff"),
        bar:   [Color(hex:"b7e9ff"), Color(hex:"6eb8f0"), Color(hex:"4e88ca"), Color(hex:"005B99"), Color(hex:"FFD700")],
        onBar: [Color(hex:"333333"), Color(hex:"003d6b"), Color(hex:"ffffff"), Color(hex:"ffffff"), Color(hex:"1a1a1a")],
        cal:   [Color(hex:"b7e9ff"), Color(hex:"6eb8f0"), Color(hex:"4e88ca"), Color(hex:"005B99"), Color(hex:"FFD700")],
        onCal: [Color(hex:"333333"), Color(hex:"003d6b"), Color(hex:"ffffff"), Color(hex:"ffffff"), Color(hex:"1a1a1a")],
        isDark: false
    )
}
```

- [ ] **Step 2: Build 確認無編譯錯誤**

在 Xcode 按 `⌘B`，確認 build 成功（ThemeTokens 新增欄位後所有初始化都要補上）。

- [ ] **Step 3: Commit**

```bash
git add nikoneko/Core/Theme/ThemeLibrary.swift
git commit -m "feat: add onBar/onCal contrast tokens to all 14 themes"
```

---

## Task 3：修正 CalendarWidget 文字顏色

**Files:**
- Modify: `nikoneko/Widgets/CalendarWidget.swift:90-91`

**問題：** `dateColor` 和 `valColor` 用 hardcoded `Color.white` / `Color(white:)`，在淺色主題格子上不可見。

- [ ] **Step 1: 改用 `theme.onCal[level]`**

找到 `CalendarWidget.swift` 中這兩行：

```swift
let dateColor: Color = isFuture ? Color(white: 0.4) : (level >= 3 ? Color.white.opacity(0.65) : Color(white: 0.733))
let valColor: Color = level >= 3 ? Color.white.opacity(0.9) : Color(white: 0.533)
```

改為：

```swift
let dateColor: Color = isFuture ? entry.theme.textDim : entry.theme.onCal[level].opacity(0.65)
let valColor: Color = entry.theme.onCal[level]
```

- [ ] **Step 2: 同時修正 day header 和 title 顏色**

找到：
```swift
Text("CHART · \(entry.metric.localizedStringResource.key.uppercased())")
    .font(.system(size: 9)).tracking(0.8)
    .foregroundColor(Color(white: 0.733))
```
改為：
```swift
Text("CHART · \(entry.metric.localizedStringResource.key.uppercased())")
    .font(.system(size: 9)).tracking(0.8)
    .foregroundColor(entry.theme.textMid)
```

找到：
```swift
Text(d).font(.system(size: 10)).foregroundColor(Color(white: 0.8))
```
改為：
```swift
Text(d).font(.system(size: 10)).foregroundColor(entry.theme.textMid)
```

- [ ] **Step 3: Commit**

```bash
git add nikoneko/Widgets/CalendarWidget.swift
git commit -m "fix: calendar widget text uses theme onCal contrast tokens"
```

---

## Task 4：修正 HeatmapWidget 文字顏色

**Files:**
- Modify: `nikoneko/Widgets/HeatmapWidget.swift:79,89,100`

**問題：** 標題、月份、星期標籤全用 `Color(white: 0.733/0.8)`，在淺色背景（limestone、paper 等）對比不足。

- [ ] **Step 1: 改用 theme tokens**

找到：
```swift
Text("HEATMAP · \(entry.metric.rawValue.uppercased())")
    .font(.system(size: 9))
    .tracking(0.7)
    .foregroundColor(Color(white: 0.733))
```
改為：
```swift
Text("HEATMAP · \(entry.metric.rawValue.uppercased())")
    .font(.system(size: 9))
    .tracking(0.7)
    .foregroundColor(entry.theme.textMid)
```

找到月份標籤：
```swift
Text(monthHeaders[col])
    .font(.system(size: 7))
    .lineLimit(1)
    .minimumScaleFactor(0.5)
    .foregroundColor(Color(white: 0.733))
```
改為：
```swift
Text(monthHeaders[col])
    .font(.system(size: 7))
    .lineLimit(1)
    .minimumScaleFactor(0.5)
    .foregroundColor(entry.theme.textMid)
```

找到星期標籤：
```swift
Text(dayLabels[row])
    .font(.system(size: 7))
    .foregroundColor(Color(white: 0.8))
```
改為：
```swift
Text(dayLabels[row])
    .font(.system(size: 7))
    .foregroundColor(entry.theme.textMid)
```

- [ ] **Step 2: Commit**

```bash
git add nikoneko/Widgets/HeatmapWidget.swift
git commit -m "fix: heatmap widget labels use theme textMid token"
```

---

## Task 5：修正 AllStatsWidget、StatWidget、BarChartWidget

**Files:**
- Modify: `nikoneko/Widgets/AllStatsWidget.swift`
- Modify: `nikoneko/Widgets/StatWidget.swift`
- Modify: `nikoneko/Widgets/BarChartWidget.swift`

這三個 widget 中所有 hardcoded `Color(white: 0.xxx)` 文字顏色改用 theme tokens。

**對應關係：**
- `Color(white: 0.667)` ~ 淡文字 → `theme.textDim`
- `Color(white: 0.733)` ~ 次要文字 → `theme.textMid`
- `Color(white: 0.784)` ~ 次要文字 → `theme.textMid`
- `Color(white: 0.8)` ~ 標籤文字 → `theme.textMid`

- [ ] **Step 1: 修正 AllStatsWidget**

在 `AllStatsWidget.swift` 中：
- 將 `foregroundColor(Color(white: 0.733))` 全部改為 `foregroundColor(entry.theme.textMid)`
- 將 `foregroundColor(Color(white: 0.667))` 全部改為 `foregroundColor(entry.theme.textDim)`
- 將 `Color(white: 0.922)` 背景色（hardcoded 淺灰）改為 `entry.theme.surface`

- [ ] **Step 2: 修正 StatWidget**

在 `StatWidget.swift` 中：
- 將 `foregroundColor(Color(white: 0.784))` 改為 `foregroundColor(entry.theme.textMid)`
- 將 `foregroundColor(Color(white: 0.667))` 改為 `foregroundColor(entry.theme.textDim)`
- 將 `foregroundColor(Color(white: 0.733))` 改為 `foregroundColor(entry.theme.textMid)`

- [ ] **Step 3: 修正 BarChartWidget**

在 `BarChartWidget.swift` 中：
- `foregroundColor(Color(white: 0.733))` → `foregroundColor(entry.theme.textMid)`
- `foregroundColor(Color(white: 0.8))` → `foregroundColor(entry.theme.textMid)`
- `Color(white: 0.875).opacity(0.5)` （grid line）→ `entry.theme.textDim.opacity(0.15)`
- `Color(white: 0.875)` （empty bar）→ `entry.theme.bar[0]`
- `Color(white: 0.067)` （today bar）→ `entry.theme.bar[4]`
- `Color(white: 0.533)` （normal bar）→ `entry.theme.bar[2]`
- `foregroundColor(Color(white: 0.8))` （x-axis label）→ `foregroundColor(entry.theme.textMid)`

- [ ] **Step 4: Commit**

```bash
git add nikoneko/Widgets/AllStatsWidget.swift nikoneko/Widgets/StatWidget.swift nikoneko/Widgets/BarChartWidget.swift
git commit -m "fix: widget text and bar colors use theme tokens instead of hardcoded grays"
```

---

## Self-Review

**Spec coverage:**
- ✅ `ThemeTokens` 加入 `onBar` / `onCal`
- ✅ 14 個主題都補上對比色
- ✅ `CalendarWidget` 文字改用 `onCal`
- ✅ `HeatmapWidget` 標籤改用 `textMid`
- ✅ `AllStatsWidget` / `StatWidget` / `BarChartWidget` 改用 theme tokens
- ✅ app 主畫面（Report、Timer、Settings）已使用 `theme.text` / `theme.textMid` 等 token，不需修改

**Placeholder scan:** 無 TBD，所有步驟含具體代碼。

**Type consistency:**
- `onBar` / `onCal` 在 Task 1 定義，Task 2 填值，Task 3-5 使用 — 一致。
- `entry.theme.onCal[level]` — `level` 範圍 0-4，`onCal` 有 5 個元素 — 安全。

import SwiftUI
import WidgetKit

struct WidgetSharedData {
    static func barColor(ratio: Double, theme: ThemeTokens, t1: Int, t2: Int, t3: Int) -> Color {
        let pct = Int(ratio * 100)
        if pct == 0   { return theme.cal[0] }
        if pct <= t1  { return theme.cal[1] }
        if pct < t2   { return theme.cal[2] }
        if pct <= t3  { return theme.cal[3] }
        return theme.cal[4]
    }

    static func loadTheme() -> ThemeTokens {
        let id = AppGroupDefaults.shared.string(forKey: "activeThemeId") ?? "obsidian"
        return ThemeLibrary.all.first { $0.id == id } ?? ThemeLibrary.obsidian
    }
}

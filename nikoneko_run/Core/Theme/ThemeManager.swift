import SwiftUI
import WidgetKit

@Observable
@MainActor
final class ThemeManager {
    private(set) var current: ThemeTokens = ThemeLibrary.moss

    init() {
        let appGroup = AppGroupDefaults.shared
        let savedId = appGroup.string(forKey: "activeThemeId")
            ?? UserDefaults.standard.string(forKey: "activeThemeId")
            ?? "moss"
        if let saved = ThemeLibrary.all.first(where: { $0.id == savedId }) {
            current = saved
        }
        // Ensure both stores agree on launch
        UserDefaults.standard.set(current.id, forKey: "activeThemeId")
        appGroup.set(current.id, forKey: "activeThemeId")
    }

    func apply(_ id: String) {
        guard let theme = ThemeLibrary.all.first(where: { $0.id == id }) else { return }
        current = theme
        UserDefaults.standard.set(id, forKey: "activeThemeId")
        AppGroupDefaults.shared.set(id, forKey: "activeThemeId")
        WidgetCenter.shared.reloadAllTimelines()
    }
}

import SwiftUI
import SwiftData

@main
struct NikoNekoApp: App {
    @State private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(themeManager)
        }
        .modelContainer(for: [RunSession.self, UserProfile.self, ThresholdConfig.self])
    }
}

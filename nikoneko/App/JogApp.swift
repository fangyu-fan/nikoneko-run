import SwiftUI
import SwiftData

@main
struct NikoNekoApp: App {
    @State private var themeManager = ThemeManager()
    @State private var languageManager = LanguageManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(themeManager)
                .environment(languageManager)
        }
        .modelContainer(makeContainer())
    }

    private func makeContainer() -> ModelContainer {
        let schema = Schema([RunSession.self, UserProfile.self, ThresholdConfig.self])
        let iCloudEnabled = UserDefaults.standard.bool(forKey: "iCloudEnabled")

        if iCloudEnabled {
            let cloudConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            if let container = try? ModelContainer(for: schema, configurations: [cloudConfig]) {
                return container
            }
            // Fallback to local if CloudKit setup fails (e.g., missing entitlements in tests)
        }

        let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let container = try? ModelContainer(for: schema, configurations: [localConfig]) {
            return container
        }
        // Last resort: in-memory container (no persistence, avoids schema migration crashes)
        let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [memConfig])
    }
}

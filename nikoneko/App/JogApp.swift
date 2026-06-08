import SwiftUI
import SwiftData

@main
struct NikoNekoApp: App {
    @State private var themeManager = ThemeManager()
    @State private var languageManager = LanguageManager()

    init() {
        let savedCode = UserDefaults.standard.string(forKey: "activeLanguageCode") ?? "en"
        LanguageBundle.languageCode = savedCode
        object_setClass(Bundle.main, LanguageBundle.self)
    }

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
        let iCloudOn = UserDefaults.standard.object(forKey: "iCloudEnabled") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "iCloudEnabled")

        if iCloudOn {
            let cloudConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            if let container = try? ModelContainer(for: schema, configurations: [cloudConfig]) {
                return container
            }
        }

        let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let container = try? ModelContainer(for: schema, configurations: [localConfig]) {
            return container
        }
        let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [memConfig])
    }
}

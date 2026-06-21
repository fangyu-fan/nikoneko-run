import SwiftUI
import SwiftData

@main
struct NikoNekoApp: App {
    @State private var themeManager = ThemeManager()
    @State private var languageManager = LanguageManager()
    @State private var showLaunch: Bool = true

    init() {
        let savedCode = UserDefaults.standard.string(forKey: "activeLanguageCode") ?? "en"
        LanguageBundle.languageCode = savedCode
        object_setClass(Bundle.main, LanguageBundle.self)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(themeManager)
                    .environment(languageManager)

                if showLaunch {
                    LaunchScreenView { showLaunch = false }
                        .environment(themeManager)
                        .environment(languageManager)
                        .zIndex(1)
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.3), value: showLaunch)
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

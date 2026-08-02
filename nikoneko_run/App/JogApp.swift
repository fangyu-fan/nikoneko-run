import SwiftUI
import SwiftData

@main
struct NikoNekoApp: App {
    @State private var themeManager = ThemeManager()
    @State private var languageManager = LanguageManager()
    @State private var showLaunch: Bool = true
    private let container: ModelContainer

    init() {
        let savedCode = UserDefaults.standard.string(forKey: "activeLanguageCode") ?? "en"
        LanguageBundle.languageCode = savedCode
        object_setClass(Bundle.main, LanguageBundle.self)
        container = Self.makeContainer()
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
        .modelContainer(container)
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([RunSession.self, UserProfile.self, ThresholdConfig.self])
        let storeURL = URL.applicationSupportDirectory.appending(path: "nikoneko.store")
        let localConfig = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [localConfig])
        } catch {
            print("⚠️ [Store] persistent store failed: \(error). Deleting and retrying…")
            let related = ["nikoneko.store", "nikoneko.store-shm", "nikoneko.store-wal"]
            for name in related {
                let url = URL.applicationSupportDirectory.appending(path: name)
                try? FileManager.default.removeItem(at: url)
            }
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                print("⚠️ [Store] retry failed: \(error). Falling back to in-memory store.")
                return try! ModelContainer(
                    for: schema,
                    configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
                )
            }
        }
    }
}

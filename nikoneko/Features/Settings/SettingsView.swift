import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager

    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Appearance",     destination: AppearanceView())
                NavigationLink("Display",        destination: DisplayView())
                NavigationLink("Defaults",       destination: DefaultsView())
                NavigationLink("Widget",         destination: WidgetSettingsView())
                NavigationLink("Notifications",  destination: NotificationsView())
                NavigationLink("Data & Sync",    destination: DataSyncView())
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(theme.bg)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

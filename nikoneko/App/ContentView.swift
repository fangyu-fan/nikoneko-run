import SwiftUI

struct ContentView: View {
    @Environment(ThemeManager.self) private var themeManager
    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        TabView {
            TimerView()
                .tabItem { Label("Run", systemImage: "figure.run") }

            ReportView()
                .tabItem { Label("Report", systemImage: "chart.bar") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(theme.accent)
    }
}

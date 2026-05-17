import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Text("Timer")
                .tabItem { Label("Timer", systemImage: "figure.run") }
            Text("Report")
                .tabItem { Label("Report", systemImage: "chart.bar") }
            Text("Settings")
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

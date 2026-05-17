import SwiftUI

struct WidgetSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    var body: some View {
        Text("Widget settings — wired in W-04")
            .foregroundColor(themeManager.current.textDim)
            .navigationTitle("Widget")
    }
}

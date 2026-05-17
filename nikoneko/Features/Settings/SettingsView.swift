import SwiftUI

struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sectionLabel("Appearance")
                    settingsCard {
                        settingsRow(icon: "◑", name: "Theme",
                                    value: themeManager.current.id.capitalized,
                                    destination: AppearanceView())
                        Rectangle()
                            .fill(theme.accentDim)
                            .frame(height: 0.5)
                            .padding(.leading, 44)
                        // Language picker lives inside AppearanceView alongside Theme —
                        // both settings share the same destination screen by design.
                        settingsRow(icon: "1", name: "Language", value: "English",
                                    destination: AppearanceView())
                    }

                    sectionLabel("Display")
                    settingsCard {
                        settingsRow(icon: "◷", name: "Display", value: "plain min",
                                    destination: DisplayView())
                    }

                    sectionLabel("Defaults")
                    settingsCard {
                        settingsRow(icon: "◎", name: "Training", value: "15 min · 180 bpm",
                                    destination: DefaultsView())
                    }

                    sectionLabel("Widget")
                    settingsCard {
                        settingsRow(icon: "▦", name: "Widget", value: "10 · 50 · 90",
                                    destination: WidgetSettingsView())
                    }

                    sectionLabel("System")
                    settingsCard {
                        settingsRow(icon: "◷", name: "Notifications", value: "Off",
                                    destination: NotificationsView())
                        Rectangle()
                            .fill(theme.accentDim)
                            .frame(height: 0.5)
                            .padding(.leading, 44)
                        settingsRow(icon: "☁", name: "Data & Sync", value: "",
                                    destination: DataSyncView())
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
            }
            .background(theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10))
            .tracking(1)
            .foregroundColor(theme.textDim)
            .padding(.top, 10)
            .padding(.bottom, 5)
            .padding(.horizontal, 2)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(theme.surface)
        .cornerRadius(14)
        .padding(.bottom, 4)
    }

    private func settingsRow<D: View>(icon: String, name: String, value: String,
                                       destination: D) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 0) {
                Text(icon)
                    .font(.system(size: 16))
                    .foregroundColor(theme.textDim)
                    .frame(width: 20, alignment: .center)
                    .padding(.trailing, 10)
                Text(name)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMid)
                Spacer()
                if !value.isEmpty {
                    Text(value)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textDim)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(theme.textDim)
                    .padding(.leading, 4)
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .frame(minHeight: 50)
        }
        .buttonStyle(.plain)
    }
}

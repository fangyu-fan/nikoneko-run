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
                                    destination: AnyView(AppearanceView()))
                        Divider().background(theme.accentDim).padding(.leading, 44)
                        settingsRow(icon: "1", name: "Language", value: "EN",
                                    destination: AnyView(AppearanceView()))
                    }

                    sectionLabel("Display")
                    settingsCard {
                        settingsRow(icon: "◷", name: "Display", value: "plain min",
                                    destination: AnyView(DisplayView()))
                    }

                    sectionLabel("Defaults")
                    settingsCard {
                        settingsRow(icon: "◎", name: "Training", value: "15 min · 180 bpm",
                                    destination: AnyView(DefaultsView()))
                    }

                    sectionLabel("Widget")
                    settingsCard {
                        settingsRow(icon: "▦", name: "Widget", value: "10 · 50 · 90",
                                    destination: AnyView(WidgetSettingsView()))
                    }

                    sectionLabel("System")
                    settingsCard {
                        settingsRow(icon: "◷", name: "Notifications", value: "Off",
                                    destination: AnyView(NotificationsView()))
                        Divider().background(theme.accentDim).padding(.leading, 44)
                        settingsRow(icon: "☁", name: "Data & Sync", value: "",
                                    destination: AnyView(DataSyncView()))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 8))
            .tracking(1)
            .foregroundColor(theme.textDim)
            .padding(.top, 12)
            .padding(.bottom, 4)
            .padding(.horizontal, 2)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(theme.surface)
        .cornerRadius(10)
        .padding(.bottom, 4)
    }

    private func settingsRow(icon: String, name: String, value: String,
                              destination: AnyView) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 0) {
                Text(icon)
                    .font(.system(size: 12))
                    .foregroundColor(theme.textDim)
                    .frame(width: 16, alignment: .center)
                    .padding(.trailing, 10)
                Text(name)
                    .font(.system(size: 11))
                    .foregroundColor(theme.textMid)
                Spacer()
                if !value.isEmpty {
                    Text(value)
                        .font(.system(size: 10))
                        .foregroundColor(theme.textDim)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(theme.textDim)
                    .padding(.leading, 4)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 46)
        }
        .buttonStyle(.plain)
    }
}

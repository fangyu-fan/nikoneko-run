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
                        settingsRow(icon: "paintpalette", name: "Theme",
                                    value: themeManager.current.id.capitalized,
                                    destination: AppearanceView())
                        Rectangle()
                            .fill(theme.accentDim)
                            .frame(height: 0.5)
                            .padding(.leading, 44)
                        settingsRow(icon: "globe", name: "Language", value: "English",
                                    destination: AppearanceView())
                    }

                    sectionLabel("Display")
                    settingsCard {
                        settingsRow(icon: "eye", name: "Display", value: "plain min",
                                    destination: DisplayView())
                    }

                    sectionLabel("Defaults")
                    settingsCard {
                        settingsRow(icon: "slider.horizontal.3", name: "Training", value: "15 min · 180 bpm",
                                    destination: DefaultsView())
                    }

                    sectionLabel("Widget")
                    settingsCard {
                        settingsRow(icon: "rectangle.3.group", name: "Widget", value: "10 · 50 · 90",
                                    destination: WidgetSettingsView())
                    }

                    sectionLabel("System")
                    settingsCard {
                        settingsRow(icon: "bell", name: "Notifications", value: "Off",
                                    destination: NotificationsView())
                        Rectangle()
                            .fill(theme.accentDim)
                            .frame(height: 0.5)
                            .padding(.leading, 44)
                        settingsRow(icon: "icloud", name: "Data & Sync", value: "",
                                    destination: DataSyncView())
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
            }
            .background(theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    backButton
                }
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(theme.textMid)
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
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(theme.text)
                    .frame(width: 20, alignment: .center)
                    .padding(.trailing, 10)
                Text(name)
                    .font(.system(size: 16))
                    .foregroundColor(theme.text)
                Spacer()
                if !value.isEmpty {
                    Text(value)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textMid)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(theme.textMid)
                    .padding(.leading, 4)
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .frame(minHeight: 50)
        }
        .buttonStyle(.plain)
    }
}

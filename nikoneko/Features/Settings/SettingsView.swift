import SwiftUI

struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionLabel(lm.L("settings.section.appearance"))
                settingsCard {
                    settingsRow(icon: "paintpalette", name: lm.L("settings.row.theme"),
                                value: themeManager.current.id.capitalized.replacingOccurrences(of: "_", with: " "),
                                destination: AppearanceView())
                    divider
                    settingsRow(icon: "globe", name: lm.L("settings.row.language"),
                                value: "",
                                destination: LanguageView())
                }

                sectionLabel(lm.L("settings.section.display"))
                settingsCard {
                    settingsRow(icon: "iphone", name: lm.L("settings.row.display"),
                                value: "",
                                destination: DisplayView())
                }

                sectionLabel(lm.L("settings.section.defaults"))
                settingsCard {
                    settingsRow(icon: "slider.horizontal.3", name: lm.L("settings.row.training"),
                                value: "",
                                destination: DefaultsView())
                }

                sectionLabel(lm.L("settings.section.widget"))
                settingsCard {
                    settingsRow(icon: "rectangle.3.group", name: lm.L("settings.row.widget"),
                                value: "",
                                destination: WidgetSettingsView())
                }

                sectionLabel(lm.L("settings.section.system"))
                settingsCard {
                    settingsRow(icon: "bell", name: lm.L("settings.row.notifications"),
                                value: "",
                                destination: NotificationsView())
                    divider
                    settingsRow(icon: "icloud", name: lm.L("settings.row.dataSync"),
                                value: "",
                                destination: DataSyncView())
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(theme.bg.ignoresSafeArea())
        .navigationTitle(lm.L("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
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

    private var divider: some View {
        Rectangle()
            .fill(theme.accentDim)
            .frame(height: 0.5)
            .padding(.leading, 44)
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
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

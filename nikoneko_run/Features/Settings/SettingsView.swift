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

                sectionLabel(lm.L("settings.section.about"))
                settingsCard {
                    settingsRow(icon: "person.crop.circle", name: lm.L("settings.row.aboutMe"),
                                value: "",
                                destination: AboutMeView())
                }
            }
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(theme.bg.ignoresSafeArea())
        .id(lm.version)
        .navigationTitle(lm.L("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .themedNavigationBar(theme)
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

struct AboutMeView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    private var theme: ThemeTokens { themeManager.current }

    private let instagramURL = URL(string: "https://www.instagram.com/with._.kiri/")!
    private let threadsURL = URL(string: "https://www.threads.com/@with._.kiri")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(lm.L("about.heading"))
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(theme.text)

                    Text(lm.L("about.body"))
                        .font(.system(size: 15))
                        .foregroundColor(theme.textMid)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(lm.L("about.contact"))
                        .font(.system(size: 15))
                        .foregroundColor(theme.textMid)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 2)
                .padding(.top, 18)
                .padding(.bottom, 22)

                sectionLabel(lm.L("about.section.social"))

                VStack(spacing: 0) {
                    socialLink(
                        icon: "InstagramIcon",
                        name: lm.L("about.instagram"),
                        handle: "@with._.kiri",
                        destination: instagramURL
                    )

                    Rectangle()
                        .fill(theme.accentDim)
                        .frame(height: 0.5)
                        .padding(.leading, 44)

                    socialLink(
                        icon: "ThreadsIcon",
                        name: lm.L("about.threads"),
                        handle: "@with._.kiri",
                        destination: threadsURL
                    )
                }
                .background(theme.surface)
                .cornerRadius(14)
            }
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(theme.bg.ignoresSafeArea())
        .id(lm.version)
        .navigationTitle(lm.L("about.title"))
        .navigationBarTitleDisplayMode(.inline)
        .themedNavigationBar(theme)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10))
            .tracking(1)
            .foregroundColor(theme.textDim)
            .padding(.bottom, 5)
            .padding(.horizontal, 2)
    }

    private func socialLink(icon: String, name: String, handle: String, destination: URL) -> some View {
        Link(destination: destination) {
            HStack(spacing: 0) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(theme.text)
                    .frame(width: 18, height: 18)
                    .frame(width: 20)
                    .padding(.trailing, 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 16))
                        .foregroundColor(theme.text)
                    Text(handle)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textMid)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13))
                    .foregroundColor(theme.textMid)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

import SwiftUI
import SwiftData

struct AppearanceView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var ctx

    private var theme: ThemeTokens { themeManager.current }
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        List {
            Section("Theme") {
                ForEach(ThemeLibrary.all, id: \.id) { t in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(t.bg)
                            .frame(width: 24, height: 24)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(t.accent, lineWidth: 1))
                        Text(t.id.capitalized)
                            .foregroundColor(theme.text)
                        Spacer()
                        if themeManager.current.id == t.id {
                            Image(systemName: "checkmark").foregroundColor(theme.accent)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        themeManager.apply(t.id)
                        profile?.activeThemeId = t.id
                        try? ctx.save()
                    }
                }
            }

            Section("Language") {
                ForEach([AppLanguage.english, .traditionalChinese], id: \.self) { lang in
                    HStack {
                        Text(lang == .english ? "English" : "繁體中文")
                            .foregroundColor(theme.text)
                        Spacer()
                        if profile?.language == lang {
                            Image(systemName: "checkmark").foregroundColor(theme.accent)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        profile?.language = lang
                        try? ctx.save()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(theme.bg)
        .navigationTitle("Appearance")
    }
}

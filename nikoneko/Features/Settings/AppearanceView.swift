import SwiftUI
import SwiftData

struct AppearanceView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    private var theme: ThemeTokens { themeManager.current }
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(ThemeLibrary.all, id: \.id) { t in
                    themeRow(t)
                        .background(t.bg)
                        .cornerRadius(12)
                        .padding(.bottom, 6)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            themeManager.apply(t.id)
                            profile?.activeThemeId = t.id
                            try? ctx.save()
                        }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(theme.bg.ignoresSafeArea())
        .navigationTitle(lm.L("theme.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func themeRow(_ t: ThemeTokens) -> some View {
        HStack(spacing: 10) {
            // 5-color square swatch strip
            HStack(spacing: 3) {
                ForEach(t.bar.indices, id: \.self) { i in
                    Rectangle()
                        .fill(t.bar[i])
                        .frame(width: 20, height: 28)
                        .cornerRadius(3)
                }
            }
            .padding(.leading, 14)

            if lm.language == .traditionalChinese {
                Text(themeZhName(t.id))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(t.text)
            } else {
                Text(themeEnName(t.id))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(t.text)
            }

            Spacer()

            if themeManager.current.id == t.id {
                Circle()
                    .fill(t.accent)
                    .frame(width: 7, height: 7)
                    .padding(.trailing, 14)
            } else {
                Color.clear
                    .frame(width: 7, height: 7)
                    .padding(.trailing, 14)
            }
        }
        .padding(.vertical, 10)
    }

    private func themeEnName(_ id: String) -> String {
        let map: [String: String] = [
            "obsidian": "Obsidian", "paper": "Paper", "limestone": "Limestone",
            "grove": "Grove", "moss": "Moss & Amber", "mocha": "Mocha", "seafloor": "Seafloor",
            "skyline": "Skyline", "navy": "Deep Navy", "lavender": "Lavender Fog",
            "midnight": "Midnight Mauve", "teal": "Teal & Coral", "blush": "Blush Garden",
            "slateRose": "Slate & Rose", "sapphireGold": "Sapphire & Gold",
        ]
        return map[id] ?? id.capitalized
    }

    private func themeZhName(_ id: String) -> String {
        let map: [String: String] = [
            "obsidian": "黑曜", "paper": "白紙", "limestone": "石灰岩",
            "grove": "林間", "moss": "苔蘚琥珀", "mocha": "摩卡", "seafloor": "海床",
            "skyline": "天際", "navy": "深海藍", "lavender": "薰衣草霧",
            "midnight": "午夜藕色", "teal": "青與珊瑚", "blush": "胭脂花園",
            "slateRose": "石板玫瑰", "sapphireGold": "藍寶石與金",
        ]
        return map[id] ?? ""
    }
}

struct LanguageView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var languageManager
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    private var theme: ThemeTokens { themeManager.current }
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 0) {
                    langRow(.english, label: "English")
                    Rectangle().fill(theme.accentDim).frame(height: 0.5).padding(.leading, 16)
                    langRow(.traditionalChinese, label: "繁體中文")
                }
                .background(theme.surface)
                .cornerRadius(14)
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .background(theme.bg.ignoresSafeArea())
        .navigationTitle(languageManager.L("language.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func langRow(_ lang: AppLanguage, label: String) -> some View {
        Button {
            profile?.language = lang
            try? ctx.save()
            languageManager.apply(lang)
            UserDefaults.standard.set(lang.code, forKey: "activeLanguageCode")
        } label: {
            HStack {
                Text(label)
                    .font(.system(size: 16))
                    .foregroundColor(theme.text)
                Spacer()
                if profile?.language == lang {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13))
                        .foregroundColor(theme.accent)
                }
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .frame(minHeight: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

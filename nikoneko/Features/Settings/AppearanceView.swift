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
                    HStack(spacing: 10) {
                        // Mini preview tile
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(t.bg)
                            VStack(spacing: 2) {
                                Text("15")
                                    .font(.system(size: 14, weight: .ultraLight))
                                    .foregroundColor(t.text)
                                    .monospacedDigit()
                                Text("min")
                                    .font(.system(size: 5))
                                    .foregroundColor(t.textDim)
                                Circle()
                                    .strokeBorder(t.accentDim, lineWidth: 0.5)
                                    .frame(width: 14, height: 14)
                                    .overlay(
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 5))
                                            .foregroundColor(t.text)
                                    )
                            }
                        }
                        .frame(width: 44, height: 56)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.accentDim, lineWidth: 0.5))

                        VStack(alignment: .leading, spacing: 1) {
                            Text(t.id.capitalized)
                                .font(.system(size: 12))
                                .foregroundColor(theme.text)
                            Text(themeZhName(t.id))
                                .font(.system(size: 9))
                                .foregroundColor(theme.textDim)
                        }
                        Spacer()
                        if themeManager.current.id == t.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11))
                                .foregroundColor(theme.accent)
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

    private func themeZhName(_ id: String) -> String {
        let map: [String: String] = [
            "obsidian": "黑曜", "paper": "白紙", "limestone": "石灰岩", "zinc": "鋅",
            "grove": "林間", "moss": "苔蘚琥珀", "mocha": "摩卡慕斯", "seafloor": "海床",
            "skyline": "天際", "navy": "深海藍", "lavender": "薰衣草霧",
            "midnight": "午夜藕色", "teal": "青與珊瑚", "blush": "胭脂花園",
        ]
        return map[id] ?? id
    }
}

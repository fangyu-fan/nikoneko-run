import SwiftUI
import WidgetKit

struct WidgetSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    @Environment(\.dismiss) private var dismiss
    private var theme: ThemeTokens { themeManager.current }

    // All 7 widgets with their App Group themeId key, display name, and size badge.
    private let widgets: [(id: String, name: String, nameZh: String, size: String, kind: String)] = [
        ("widget.streak.themeId",        "Streak",          "連勝天數",  "Small",  "StreakWidget"),
        ("widget.todayDuration.themeId", "Today Duration",  "當天時長",  "Small",  "TodayDurationWidget"),
        ("widget.todayDistance.themeId", "Today Distance",  "當天距離",  "Small",  "TodayDistanceWidget"),
        ("widget.todaySteps.themeId",    "Today Steps",     "當天步數",  "Small",  "TodayStepsWidget"),
        ("widget.heatmap.themeId",       "Year Heatmap",    "年熱力圖",  "Medium", "HeatmapWidget"),
        ("widget.calendar.themeId",      "Month Calendar",  "月曆",      "Large",  "CalendarWidget"),
        ("widget.allStats.themeId",      "All Stats",       "所有數據",  "Large",  "AllStatsWidget"),
    ]

    // Bumping this causes SwiftUI to re-render all cards when any widget theme changes.
    @State private var refreshToken: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text(lm.L("widget.hint"))
                    .font(.system(size: 12))
                    .foregroundColor(theme.textDim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                ForEach(widgets, id: \.id) { w in
                    widgetCard(w)
                }
            }
            .padding(.bottom, 24)
        }
        .id(refreshToken)
        .background(theme.bg.ignoresSafeArea())
        .navigationTitle(lm.L("widget.title"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(theme.textMid)
                }
            }
        }
    }

    // MARK: - Widget Card

    private func widgetCard(
        _ w: (id: String, name: String, nameZh: String, size: String, kind: String)
    ) -> some View {
        let widgetThemeId = AppGroupDefaults.shared.string(forKey: w.id)
            ?? AppGroupDefaults.shared.string(forKey: "activeThemeId")
            ?? "obsidian"
        let widgetTheme = ThemeLibrary.all.first { $0.id == widgetThemeId } ?? ThemeLibrary.obsidian

        return VStack(alignment: .leading, spacing: 10) {
            // Header: name + size badge
            HStack {
                Text(lm.language == .traditionalChinese ? w.nameZh : w.name)
                    .font(.system(size: 16))
                    .foregroundColor(theme.text)
                Text(w.size)
                    .font(.system(size: 11))
                    .foregroundColor(theme.textMid)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(theme.card).cornerRadius(6)
                Spacer()
            }

            // Miniature widget preview
            widgetPreview(kind: w.kind, widgetTheme: widgetTheme)
                .frame(height: w.size == "Large" ? 160 : w.size == "Medium" ? 90 : 80)
                .cornerRadius(12)
                .clipped()

            // Theme selector — same appearance as AppearanceView.themeRow
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(ThemeLibrary.all, id: \.id) { t in
                        themeRow(t, selectedId: widgetThemeId, widgetKey: w.id)
                            .background(t.bg)
                            .cornerRadius(10)
                            .padding(.bottom, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                AppGroupDefaults.shared.set(t.id, forKey: w.id)
                                WidgetCenter.shared.reloadAllTimelines()
                                refreshToken += 1
                            }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(14)
        .background(theme.surface)
        .cornerRadius(14)
        .padding(.horizontal, 18)
    }

    // MARK: - Theme Row (mirrors AppearanceView.themeRow)

    private func themeRow(_ t: ThemeTokens, selectedId: String, widgetKey: String) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 3) {
                ForEach(t.bar.indices, id: \.self) { i in
                    Rectangle()
                        .fill(t.bar[i])
                        .frame(width: 20, height: 28)
                        .cornerRadius(3)
                }
            }
            .padding(.leading, 14)

            Text(lm.language == .traditionalChinese ? themeZhName(t.id) : themeEnName(t.id))
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(t.text)

            Spacer()

            if selectedId == t.id {
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

    // MARK: - Widget Previews

    @ViewBuilder
    private func widgetPreview(kind: String, widgetTheme: ThemeTokens) -> some View {
        switch kind {
        case "StreakWidget":
            smallStatPreview(label: "STREAK", value: "12", unit: "day streak", theme: widgetTheme)

        case "TodayDurationWidget":
            smallStatPreview(label: "TODAY", value: "24", unit: "min today", theme: widgetTheme)

        case "TodayDistanceWidget":
            smallStatPreview(label: "TODAY", value: "—", unit: "km today", theme: widgetTheme)

        case "TodayStepsWidget":
            smallStatPreview(label: "TODAY", value: "3.2k", unit: "steps today", theme: widgetTheme)

        case "HeatmapWidget":
            heatmapPreview(widgetTheme: widgetTheme)

        case "AllStatsWidget":
            allStatsPreview(widgetTheme: widgetTheme)

        default: // CalendarWidget
            calendarPreview(widgetTheme: widgetTheme)
        }
    }

    private func smallStatPreview(label: String, value: String, unit: String, theme: ThemeTokens) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 7)).tracking(1)
                    .foregroundColor(theme.textDim)
                Text(value)
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundColor(theme.accent)
                Text(unit)
                    .font(.system(size: 9))
                    .foregroundColor(theme.textDim)
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.bg)
    }

    private func heatmapPreview(widgetTheme: ThemeTokens) -> some View {
        ZStack(alignment: .topLeading) {
            widgetTheme.bg
            VStack(alignment: .leading, spacing: 3) {
                Text("THIS YEAR")
                    .font(.system(size: 6)).tracking(1)
                    .foregroundColor(widgetTheme.textDim)
                let cols = 18, rows = 7
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: cols),
                    spacing: 2
                ) {
                    ForEach(0..<cols * rows, id: \.self) { i in
                        let tier = previewTier(index: i, total: cols * rows)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(widgetTheme.bar[tier])
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            .padding(10)
        }
    }

    private func allStatsPreview(widgetTheme: ThemeTokens) -> some View {
        ZStack(alignment: .topLeading) {
            widgetTheme.bg
            VStack(alignment: .leading, spacing: 8) {
                Text("TODAY")
                    .font(.system(size: 6)).tracking(1)
                    .foregroundColor(widgetTheme.textDim)
                let stats = [("30","min"),("4.2k","steps"),("210","kcal"),("148","avg HR"),("—","km"),("7","day streak")]
                ForEach(Array(stride(from: 0, to: stats.count, by: 2)), id: \.self) { i in
                    HStack(spacing: 0) {
                        ForEach(i..<min(i+2, stats.count), id: \.self) { j in
                            VStack(alignment: .leading, spacing: 1) {
                                Text(stats[j].0)
                                    .font(.system(size: 14, weight: .ultraLight))
                                    .foregroundColor(widgetTheme.accent)
                                Text(stats[j].1)
                                    .font(.system(size: 6))
                                    .foregroundColor(widgetTheme.textDim)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(10)
        }
    }

    private func calendarPreview(widgetTheme: ThemeTokens) -> some View {
        ZStack(alignment: .topLeading) {
            widgetTheme.bg
            VStack(spacing: 2) {
                HStack {
                    ForEach(["S","M","T","W","T","F","S"], id: \.self) { d in
                        Text(d)
                            .font(.system(size: 6))
                            .foregroundColor(widgetTheme.textDim)
                            .frame(maxWidth: .infinity)
                    }
                }
                ForEach(0..<4) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<7) { col in
                            let n = row * 7 + col + 1
                            ZStack {
                                if n <= 30 {
                                    let tier = previewTier(index: n, total: 30)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(widgetTheme.cal[tier])
                                    Text("\(n)")
                                        .font(.system(size: 5))
                                        .foregroundColor(widgetTheme.text.opacity(tier > 0 ? 0.8 : 0.4))
                                } else {
                                    Color.clear
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
            .padding(10)
        }
    }

    /// Deterministic wave pattern for preview cells (0–4 tier index).
    private func previewTier(index: Int, total: Int) -> Int {
        let wave = sin(Double(index) / Double(total) * .pi * 4 + 1.0)
        let mapped = (wave + 1.0) / 2.0
        return min(4, Int(mapped * 5))
    }

    // MARK: - Theme Name Maps

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

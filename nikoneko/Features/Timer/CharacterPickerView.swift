import SwiftUI
import SwiftData

struct CharacterPickerView: View {
    @Binding var selectedId: String
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    @Environment(\.modelContext) private var ctx
    @Query private var profiles: [UserProfile]

    private var theme: ThemeTokens { themeManager.current }
    private var profile: UserProfile? { profiles.first }

    // Characters that map to actual Lottie files in the bundle
    private let characters: [(id: String, labelKey: String)] = [
        ("loader_cat", "character.loaderCat"),
        ("bad_cat",    "character.badCat"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(characters, id: \.id) { char in
                        characterRow(char: char)
                        if char.id != characters.last?.id {
                            Rectangle()
                                .fill(theme.accentDim)
                                .frame(height: 0.5)
                                .padding(.leading, 88)
                        }
                    }
                }
                .background(theme.surface)
                .cornerRadius(14)
                .padding(.horizontal, 18)
                .padding(.top, 8)
            }
            .background(theme.bg.ignoresSafeArea())
            .navigationTitle(lm.L("character.title"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func characterRow(char: (id: String, labelKey: String)) -> some View {
        let isSelected = selectedId == char.id
        return Button(action: {
            selectedId = char.id
            profile?.activeCharacterId = char.id
            try? ctx.save()
            dismiss()
        }) {
            HStack(spacing: 14) {
                LottieCharacterView(
                    characterId: char.id,
                    color: theme.accentMid,
                    bpm: 160,
                    isAnimating: isSelected
                )
                .frame(width: 56, height: 40)

                Text(lm.L(char.labelKey))
                    .font(.system(size: 16))
                    .foregroundColor(theme.text)

                Spacer()

                if isSelected {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 8, height: 8)
                        .padding(.trailing, 4)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

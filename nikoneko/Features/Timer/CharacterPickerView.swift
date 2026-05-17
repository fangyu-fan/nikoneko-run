import SwiftUI

struct CharacterPickerView: View {
    @Binding var selectedId: String
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager

    private var theme: ThemeTokens { themeManager.current }

    private let characters: [(id: String, label: String, unlockStreak: Int)] = [
        ("cat_a",    "Cat α",     0),
        ("cat_b",    "Cat β",     0),
        ("human",    "Human",     0),
        ("pushup",   "Push-Up",   0),
        ("situp",    "Sit-Up",    7),
        ("jumprope", "Jump Rope", 14),
        ("parrot",   "Parrot",    30),
    ]

    private let currentStreak: Int = 0

    var body: some View {
        NavigationStack {
            List(characters, id: \.id) { char in
                HStack {
                    PlaceholderCharacterView(
                        characterId: char.id,
                        color: theme.accentMid,
                        speedMultiplier: 1.0,
                        isAnimating: selectedId == char.id
                    )
                    .frame(width: 40, height: 30)

                    Text(char.label)
                        .font(.system(size: 14))
                        .foregroundColor(char.unlockStreak <= currentStreak ? theme.text : theme.textDim)

                    Spacer()

                    if char.unlockStreak > currentStreak {
                        Text("\(char.unlockStreak)d")
                            .font(.system(size: 10))
                            .foregroundColor(theme.textDim)
                        Image(systemName: "lock")
                            .font(.system(size: 10))
                            .foregroundColor(theme.textDim)
                    } else if selectedId == char.id {
                        Image(systemName: "checkmark")
                            .foregroundColor(theme.accent)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    guard char.unlockStreak <= currentStreak else { return }
                    selectedId = char.id
                    dismiss()
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(theme.bg)
            .navigationTitle("Character")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

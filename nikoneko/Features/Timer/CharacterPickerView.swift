import SwiftUI

struct CharacterPickerView: View {
    @Binding var selectedId: String
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager

    private var theme: ThemeTokens { themeManager.current }

    private let freeCharacters: [(id: String, label: String)] = [
        ("cat_a",  "Cat α"),
        ("cat_b",  "Cat β"),
        ("human",  "Human"),
        ("pushup", "Push-Up"),
    ]

    private let lockedCharacters: [(id: String, label: String, requiredStreak: Int)] = [
        ("situp",    "Sit-Up",    7),
        ("jumprope", "Jump Rope", 14),
        ("parrot",   "Parrot",    30),
    ]

    // Placeholder — will connect to real streak data in a future pass
    private let currentStreak: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sectionHeader("Free")
                    ForEach(freeCharacters, id: \.id) { char in
                        freeRow(char: char)
                        if char.id != freeCharacters.last?.id {
                            Divider()
                                .background(theme.accentDim)
                                .padding(.leading, 66)
                        }
                    }

                    sectionHeader("Achievements")
                    ForEach(lockedCharacters, id: \.id) { char in
                        lockedRow(char: char)
                        if char.id != lockedCharacters.last?.id {
                            Divider()
                                .background(theme.accentDim)
                                .padding(.leading, 66)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(theme.bg.ignoresSafeArea())
            .navigationTitle("Characters")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 8))
            .tracking(1)
            .foregroundColor(theme.textDim)
            .padding(.top, 14)
            .padding(.bottom, 4)
            .padding(.horizontal, 2)
    }

    private func freeRow(char: (id: String, label: String)) -> some View {
        let isSelected = selectedId == char.id
        return Button(action: {
            selectedId = char.id
            dismiss()
        }) {
            HStack(spacing: 12) {
                LottieCharacterView(
                    characterId: char.id,
                    color: theme.accentMid,
                    bpm: 120,
                    isAnimating: isSelected
                )
                .frame(width: 38, height: 26)

                Text(char.label)
                    .font(.system(size: 12))
                    .foregroundColor(theme.text)

                Spacer()

                if isSelected {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(isSelected ? theme.surface : Color.clear)
        }
        .buttonStyle(.plain)
    }

    private func lockedRow(char: (id: String, label: String, requiredStreak: Int)) -> some View {
        let isUnlocked = currentStreak >= char.requiredStreak
        return HStack(spacing: 12) {
            LottieCharacterView(
                characterId: char.id,
                color: theme.accentMid,
                bpm: 120,
                isAnimating: false
            )
            .frame(width: 38, height: 26)
            .opacity(isUnlocked ? 1.0 : 0.2)

            VStack(alignment: .leading, spacing: 2) {
                Text(char.label)
                    .font(.system(size: 12))
                    .foregroundColor(isUnlocked ? theme.text : theme.textDim)
                if !isUnlocked {
                    Text("\(char.requiredStreak)-day streak")
                        .font(.system(size: 8))
                        .foregroundColor(theme.bar[1])
                }
            }

            Spacer()

            if !isUnlocked {
                Text("⚿")
                    .font(.system(size: 10))
                    .foregroundColor(theme.textDim)
            } else if selectedId == char.id {
                Circle()
                    .fill(theme.accent)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            guard isUnlocked else { return }
            selectedId = char.id
            dismiss()
        }
    }
}

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
                            Rectangle()
                                .fill(theme.accentDim)
                                .frame(height: 0.5)
                        }
                    }

                    sectionHeader("Achievements")
                    ForEach(lockedCharacters, id: \.id) { char in
                        lockedRow(char: char)
                        if char.id != lockedCharacters.last?.id {
                            Rectangle()
                                .fill(theme.accentDim)
                                .frame(height: 0.5)
                        }
                    }
                }
            }
            .background(theme.bg.ignoresSafeArea())
            .navigationTitle("Characters")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10))
            .tracking(1)
            .foregroundColor(theme.textDim)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .padding(.horizontal, 18)
    }

    private func freeRow(char: (id: String, label: String)) -> some View {
        let isSelected = selectedId == char.id
        return Button(action: {
            selectedId = char.id
            dismiss()
        }) {
            HStack(spacing: 14) {
                LottieCharacterView(
                    
                    color: theme.accentMid,
                    bpm: 120,
                    isAnimating: isSelected
                )
                .frame(width: 56, height: 32)

                Text(char.label)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMid)

                Spacer()

                if isSelected {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(isSelected ? theme.card : Color.clear)
        }
        .buttonStyle(.plain)
    }

    private func lockedRow(char: (id: String, label: String, requiredStreak: Int)) -> some View {
        let isUnlocked = currentStreak >= char.requiredStreak
        let isSelected = selectedId == char.id
        return HStack(spacing: 14) {
            LottieCharacterView(
                
                color: theme.accentMid,
                bpm: 120,
                isAnimating: false
            )
            .frame(width: 56, height: 32)
            .opacity(isUnlocked ? 1.0 : 0.2)

            VStack(alignment: .leading, spacing: 2) {
                Text(char.label)
                    .font(.system(size: 14))
                    .foregroundColor(isUnlocked ? theme.textMid : theme.textDim)
                if !isUnlocked {
                    Text("\(char.requiredStreak)-day streak")
                        .font(.system(size: 10))
                        .foregroundColor(theme.bar[1])
                }
            }

            Spacer()

            if !isUnlocked {
                Text("⚿")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textDim)
            } else if isSelected {
                Circle()
                    .fill(theme.accent)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 18)
        .background(isSelected ? theme.card : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            guard isUnlocked else { return }
            selectedId = char.id
            dismiss()
        }
    }
}

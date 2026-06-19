import SwiftUI

// MARK: - Model

private struct OnboardingCard {
    let titleKey: String
    let bodyKey: String
    let icon: String
}

private let onboardingCards: [OnboardingCard] = [
    OnboardingCard(
        titleKey: "onboarding.card1.title",
        bodyKey: "onboarding.card1.body",
        icon: "metronome"
    ),
    OnboardingCard(
        titleKey: "onboarding.card2.title",
        bodyKey: "onboarding.card2.body",
        icon: "chart.bar"
    ),
    OnboardingCard(
        titleKey: "onboarding.card3.title",
        bodyKey: "onboarding.card3.body",
        icon: "figure.run"
    ),
]

// MARK: - OnboardingView

struct OnboardingView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var languageManager

    let onDismiss: () -> Void

    @State private var currentPage: Int = 0

    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(onboardingCards.indices, id: \.self) { index in
                        cardPage(onboardingCards[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                VStack(spacing: 24) {
                    // Dot indicator
                    dotIndicator

                    // Start button — only visible on last card
                    startButton
                        .opacity(currentPage == onboardingCards.count - 1 ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
            }
        }
        .id(languageManager.version)
    }

    // MARK: Card page

    private func cardPage(_ card: OnboardingCard) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 40)

            Image(systemName: card.icon)
                .font(.system(size: 40, weight: .light))
                .foregroundColor(theme.accent)
                .padding(.bottom, 32)

            Text(languageManager.L(card.titleKey))
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(theme.text)
                .padding(.bottom, 16)

            Text(languageManager.L(card.bodyKey))
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(theme.textMid)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Dot indicator

    private var dotIndicator: some View {
        HStack(spacing: 8) {
            ForEach(onboardingCards.indices, id: \.self) { index in
                Circle()
                    .fill(index == currentPage
                          ? theme.accent
                          : theme.textDim.opacity(0.4))
                    .frame(width: 6, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }

    // MARK: Start button

    private var startButton: some View {
        Button {
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
            onDismiss()
        } label: {
            Text(languageManager.L("onboarding.cta"))
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(theme.bg)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(theme.accent)
                .cornerRadius(12)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let themeManager = ThemeManager()
    let languageManager = LanguageManager()
    return OnboardingView(onDismiss: {})
        .environment(themeManager)
        .environment(languageManager)
}
#endif

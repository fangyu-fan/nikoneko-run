import SwiftUI

struct LaunchScreenView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onComplete: () -> Void

    // Controls Lottie playback: false = frozen at frame 0, true = looping
    @State private var isAnimating: Bool = false

    // Keep the in-app launch animation aligned with the fixed system launch image.
    private let theme = ThemeLibrary.moss

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()

                // Lottie renders synchronously at frame 0 on first layout pass,
                // so the cat is visible immediately — no blank flash.
                LottieCharacterView(
                    characterId: "loader_cat",
                    color: theme.accentMid,
                    secondaryColor: theme.accent,
                    tertiaryColor: theme.accentDim,
                    shadowColor: theme.bg,
                    bpm: 180,
                    isAnimating: isAnimating
                )
                .frame(width: 120, height: 88)
                .padding(.bottom, 17)

                Text("nikoneko run")
                    .font(.system(size: 30, weight: .ultraLight))
                    .foregroundColor(theme.text)
                    .offset(y: -10)

                Spacer()
            }
            .offset(y: -12)
        }
        .task {
            if !reduceMotion {
                try? await Task.sleep(for: .milliseconds(50))
                isAnimating = true
            }
            try? await Task.sleep(for: .milliseconds(1000))
            onComplete()
        }
    }
}

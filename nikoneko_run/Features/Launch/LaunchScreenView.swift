import SwiftUI

struct LaunchScreenView: View {
    @Environment(ThemeManager.self) private var themeManager
    let onComplete: () -> Void

    // Controls Lottie playback: false = frozen at frame 0, true = looping
    @State private var isAnimating: Bool = false

    private var theme: ThemeTokens { themeManager.current }

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
                    shadowColor: theme.accentDim,
                    bpm: 180,
                    isAnimating: isAnimating
                )
                .frame(width: 120, height: 88)
                .padding(.bottom, 32)

                Text("Nikoneko")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundColor(theme.text)
                    .padding(.bottom, 8)

                Text("slow jog · smile pace")
                    .font(.system(size: 13))
                    .tracking(0.5)
                    .foregroundColor(theme.textDim)

                Spacer()
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(50))
            isAnimating = true
            try? await Task.sleep(for: .milliseconds(1000))
            onComplete()
        }
    }
}

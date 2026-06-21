import SwiftUI

struct LaunchScreenView: View {
    @Environment(ThemeManager.self) private var themeManager
    let onComplete: () -> Void

    @State private var isAnimating: Bool = false  // starts static, animates after brief pause

    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                LottieCharacterView(
                    characterId: "loader_cat",
                    color: theme.accentMid,
                    shadowColor: theme.accentDim,
                    bpm: 180,
                    isAnimating: isAnimating
                )
                .frame(width: 120, height: 88)
                .padding(.bottom, 32)

                Text("Niko Neko")
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
        .onAppear {
            Task {
                // Brief pause on first frame so system launch screen → static cat is seamless
                try? await Task.sleep(for: .milliseconds(120))
                isAnimating = true
                // Total visible: 120ms static + 900ms animation
                try? await Task.sleep(for: .milliseconds(900))
                onComplete()
            }
        }
    }
}

import SwiftUI
import Lottie

struct LottieTrophyView: View {
    var body: some View {
        if let url = Bundle.main.url(forResource: "Trophy", withExtension: "json") {
            LottieView(animation: .filepath(url.path))
                .configure { $0.contentMode = .scaleAspectFit }
                .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
        }
    }
}

struct LottieCharacterView: View {
    let color: Color
    let bpm: Int
    let isAnimating: Bool

    private var animationSpeed: Double { Double(bpm) / 120.0 }

    var body: some View {
        if let url = Bundle.main.url(forResource: "Loader cat", withExtension: "json") {
            LottieView(animation: .filepath(url.path))
                .configure { view in
                    view.contentMode = .scaleAspectFit
                }
                .animationSpeed(animationSpeed)
                .playing(isAnimating
                    ? .fromProgress(0, toProgress: 1, loopMode: .loop)
                    : .fromProgress(0, toProgress: 0, loopMode: .playOnce))
        }
    }
}

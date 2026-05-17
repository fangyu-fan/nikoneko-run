import SwiftUI
import Lottie

struct LottieCharacterView: View {
    let characterId: String
    let color: Color
    let bpm: Int
    let isAnimating: Bool

    // 1 loop = 2 beats → loopsPerSecond = bpm / 60 / 2
    private var animationSpeed: Double { Double(bpm) / 120.0 }

    var body: some View {
        if let url = Bundle.main.url(forResource: characterId, withExtension: "json",
                                     subdirectory: "Characters/Lottie") {
            LottieView(animation: .filepath(url.path))
                .configure { view in
                    let lottieColor = color.lottieColor
                    view.setValueProvider(ColorValueProvider(lottieColor),
                                          keypath: AnimationKeypath(keypath: "**.Color"))
                    view.setValueProvider(ColorValueProvider(lottieColor),
                                          keypath: AnimationKeypath(keypath: "**.Fill Color"))
                    view.setValueProvider(ColorValueProvider(lottieColor),
                                          keypath: AnimationKeypath(keypath: "**.Stroke Color"))
                }
                .animationSpeed(animationSpeed)
                .looping()
                .playing(isAnimating ? .fromProgress(0, toProgress: 1, loopMode: .loop) : .fromProgress(0, toProgress: 0, loopMode: .playOnce))
        } else {
            PlaceholderCharacterView(
                characterId: characterId,
                color: color,
                bpm: bpm,
                isAnimating: isAnimating
            )
        }
    }
}

private extension Color {
    var lottieColor: LottieColor {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return LottieColor(r: Double(r), g: Double(g), b: Double(b), a: Double(a))
    }
}

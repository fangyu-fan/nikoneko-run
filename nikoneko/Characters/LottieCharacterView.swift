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
    var characterId: String = "loader_cat"
    let color: Color
    let bpm: Int
    let isAnimating: Bool

    // Natural loop duration (seconds) for each animation — measured from JSON fr/op/ip
    private static let naturalDuration: [String: Double] = [
        "loader_cat": 32.0 / 25.0,  // 1.28s
        "bad_cat":    65.0 / 60.0,  // 1.083s
    ]

    static let fileNameMap: [String: String] = [
        "loader_cat": "Loader cat",
        "bad_cat":    "Bad Cat",
    ]

    private var lottieFileName: String {
        Self.fileNameMap[characterId] ?? "Loader cat"
    }

    // Speed so that one animation loop = two metronome beats
    private var animationSpeed: Double {
        let twoBeatInterval = 2 * 60.0 / Double(bpm)
        let natural = Self.naturalDuration[characterId] ?? (32.0 / 25.0)
        return natural / twoBeatInterval
    }

    var body: some View {
        if let url = Bundle.main.url(forResource: lottieFileName, withExtension: "json") {
            let uiColor = UIColor(color)
            let colorProvider = ColorValueProvider(uiColor.lottieColorValue)
            LottieView(animation: .filepath(url.path))
                .configure { view in
                    view.contentMode = .scaleAspectFit
                }
                .valueProvider(colorProvider, for: AnimationKeypath(keypath: "**.Fill 1.Color"))
                .valueProvider(colorProvider, for: AnimationKeypath(keypath: "**.Fill 2.Color"))
                .valueProvider(colorProvider, for: AnimationKeypath(keypath: "**.Stroke 1.Color"))
                .animationSpeed(animationSpeed)
                .playing(isAnimating
                    ? .fromProgress(0, toProgress: 1, loopMode: .loop)
                    : .fromProgress(0, toProgress: 0, loopMode: .playOnce))
                .id(characterId)
        }
    }
}

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
    var secondaryColor: Color? = nil
    var tertiaryColor: Color? = nil
    var shadowColor: Color? = nil  // loader_cat tail shadow / ground shadow; falls back to color
    let bpm: Int
    let isAnimating: Bool

    // Add character IDs here only when their artwork should follow the active theme.
    private static let themedCharacterIds: Set<String> = [
        "loader_cat",
        "bad_cat",
        "crow_people",
        "running_dog",
        "soccer",
        "happy_dog",
        "heartbeat",
        "runner",
        "jogger",
        "jumper",
        "squirrel",
    ]

    // These animations contain multiple motions per loop, so stretch them across four beats.
    private static let fourBeatCharacterIds: Set<String> = [
        "coffee",
        "running_dog",
        "soccer",
        "happy_dog",
    ]

    // These need four times the default two-beat interval.
    private static let eightBeatCharacterIds: Set<String> = [
        "jogger",
    ]

    // These already fill their display area; all other characters render at 1.5x scale.
    private static let normalSizeCharacterIds: Set<String> = [
        "loader_cat",
        "bad_cat",
        "salad_cat",
        "jumper",
        "jogger",
    ]

    // Natural loop duration (seconds) for each animation — measured from JSON fr/op/ip
    private static let naturalDuration: [String: Double] = [
        "loader_cat":  32.0 / 25.0,
        "bad_cat":     65.0 / 60.0,
        "coffee":      51.0 / 50.0,
        "crow_people": 55.0 / 50.0,
        "jumper":      165.0 / 30.0,
        "running_dog": 80.0 / 30.0,
        "soccer":      202.0 / 120.0,
        "fries":       51.0 / 50.0,
        "happy_dog":   162.0 / 60.0,
        "heartbeat":   61.0 / 25.0,
        "space_buddy": 27.0 / 50.0,
        "mushrooms":   31.0 / 60.0,
        "potato":      51.0 / 50.0,
        "runner":      34.0 / 60.0,
        "jogger":      112.0 / 30.0,
        "salad_cat":   160.0 / 50.0,
        "squirrel":    17.0 / 30.0,
        "avocado":     52.0 / 50.0,
        "donut":       51.0 / 50.0,
        "pothos":      51.0 / 50.0,
        "taco":        51.0 / 50.0,
        "running_man": 28.0 / 24.0,
    ]

    static let fileNameMap: [String: String] = [
        "loader_cat":   "Loader",
        "bad_cat":      "Bad Cat",
        "coffee":       "Coffee",
        "crow_people":  "Crow People",
        "jumper":       "Jumper",
        "running_dog":  "Running Dog",
        "soccer":       "Soccer",
        "fries":        "Fries",
        "happy_dog":    "Happy Dog",
        "heartbeat":    "Heartbeat",
        "space_buddy":  "Space Buddy",
        "mushrooms":    "Mushrooms",
        "potato":       "Potato",
        "runner":       "Runner",
        "jogger":       "Jogger",
        "salad_cat":    "Salad Cat",
        "squirrel":     "Squirrel",
        "avocado":      "Avocado",
        "donut":        "Donut",
        "pothos":       "Pothos",
        "taco":         "Taco",
        "running_man":  "Running Man",
    ]

    private var lottieFileName: String {
        Self.fileNameMap[resolvedCharacterId] ?? "Loader"
    }

    // Old app versions used IDs such as cat_a. Treat unknown IDs as Loader for
    // the file, theme whitelist, sizing, and speed—not just for the file lookup.
    private var resolvedCharacterId: String {
        Self.fileNameMap[characterId] == nil ? "loader_cat" : characterId
    }

    // Match each complete animation loop to an exact number of metronome beats.
    private var animationSpeed: Double {
        let natural = Self.naturalDuration[resolvedCharacterId] ?? (32.0 / 25.0)
        let beatsPerLoop: Double
        if resolvedCharacterId == "jumper" {
            // The 165-frame file is the same 55-frame jump repeated three times.
            beatsPerLoop = 6
        } else if Self.eightBeatCharacterIds.contains(resolvedCharacterId) {
            beatsPerLoop = 8
        } else if Self.fourBeatCharacterIds.contains(resolvedCharacterId) {
            beatsPerLoop = 4
        } else {
            beatsPerLoop = 2
        }
        let targetLoopDuration = beatsPerLoop * 60.0 / Double(bpm)
        return natural / targetLoopDuration
    }

    private var characterScale: CGFloat {
        Self.normalSizeCharacterIds.contains(resolvedCharacterId) ? 1 : 1.5
    }

    // Recreate Lottie when returning from Settings with a different theme.
    private var renderIdentity: String {
        [
            resolvedCharacterId,
            UIColor(color).description,
            UIColor(secondaryColor ?? color).description,
            UIColor(tertiaryColor ?? secondaryColor ?? color).description,
            UIColor(shadowColor ?? color).description,
        ].joined(separator: "|")
    }

    var body: some View {
        if let url = Bundle.main.url(forResource: lottieFileName, withExtension: "json") {
            let animation = LottieView(animation: .filepath(url.path))
                .configure { view in
                    view.contentMode = .scaleAspectFit
                }
                .animationSpeed(animationSpeed)
                .playing(isAnimating
                    ? .fromProgress(0, toProgress: 1, loopMode: .loop)
                    : .fromProgress(0, toProgress: 0, loopMode: .playOnce))

            if Self.themedCharacterIds.contains(resolvedCharacterId) {
                let primaryProvider = ColorValueProvider(UIColor(color).lottieColorValue)
                let secondaryProvider = ColorValueProvider(UIColor(secondaryColor ?? color).lottieColorValue)
                let tertiaryProvider = ColorValueProvider(UIColor(tertiaryColor ?? secondaryColor ?? color).lottieColorValue)
                let shadowProvider = ColorValueProvider(UIColor(shadowColor ?? secondaryColor ?? color).lottieColorValue)
                if resolvedCharacterId == "loader_cat" {
                    animation
                        // Loader stays a one-color silhouette; shadows match the surrounding background.
                        .valueProvider(primaryProvider, for: AnimationKeypath(keypath: "**.Color"))
                        .valueProvider(primaryProvider, for: AnimationKeypath(keypath: "**.Fill 1.Color"))
                        .valueProvider(primaryProvider, for: AnimationKeypath(keypath: "**.Fill 2.Color"))
                        .valueProvider(primaryProvider, for: AnimationKeypath(keypath: "**.Stroke 1.Color"))
                        .valueProvider(shadowProvider, for: AnimationKeypath(keypath: "**.Queue Ombre.**.Stroke 1.Color"))
                        .valueProvider(shadowProvider, for: AnimationKeypath(keypath: "**.Ombre.**.Fill 1.Color"))
                        .scaleEffect(characterScale)
                        .id(renderIdentity)
                } else if resolvedCharacterId == "heartbeat" {
                    // Heartbeat intentionally keeps its current two-color treatment.
                    animation
                        .valueProvider(primaryProvider, for: AnimationKeypath(keypath: "**.Fill 1.Color"))
                        .valueProvider(secondaryProvider, for: AnimationKeypath(keypath: "**.Fill 2.Color"))
                        .valueProvider(tertiaryProvider, for: AnimationKeypath(keypath: "**.Stroke 1.Color"))
                        .scaleEffect(characterScale)
                        .id(renderIdentity)
                } else {
                    // All other themed characters are rendered as one-color silhouettes.
                    animation
                        .valueProvider(primaryProvider, for: AnimationKeypath(keypath: "**.Color"))
                        .scaleEffect(characterScale)
                        .id(renderIdentity)
                }
            } else {
                animation
                    .scaleEffect(characterScale)
                    .id(renderIdentity)
            }
        }
    }
}

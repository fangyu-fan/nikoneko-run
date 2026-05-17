import SwiftUI

// Stub — replace when Lottie JSON assets are available.
// Drop JSON files into Characters/Lottie/<characterId>.json
struct LottieCharacterView: View {
    let characterId: String
    let color: Color
    let speedMultiplier: Double

    var body: some View {
        PlaceholderCharacterView(
            characterId: characterId,
            color: color,
            speedMultiplier: speedMultiplier,
            isAnimating: true
        )
    }
}

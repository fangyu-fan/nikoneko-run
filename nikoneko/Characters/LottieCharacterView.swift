import SwiftUI

// Stub — replace with real Lottie implementation when JSON assets are available.
// Drop JSON files into Characters/Lottie/<characterId>.json
//
// When integrating Lottie:
//   let loopsPerSecond = Double(bpm) / 120.0   // 1 loop = 2 beats
//   animationView.animationSpeed = loopsPerSecond
struct LottieCharacterView: View {
    let characterId: String
    let color: Color
    let bpm: Int

    var body: some View {
        PlaceholderCharacterView(
            characterId: characterId,
            color: color,
            bpm: bpm,
            isAnimating: true
        )
    }
}

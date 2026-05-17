import SwiftUI

struct PlaceholderCharacterView: View {
    let characterId: String
    let color: Color
    let speedMultiplier: Double
    let isAnimating: Bool

    var body: some View {
        Circle().fill(color).frame(width: 30, height: 30)
    }
}

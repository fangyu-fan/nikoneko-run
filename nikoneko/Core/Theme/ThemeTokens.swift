import SwiftUI

struct ThemeTokens {
    let id: String
    let bg: Color
    let surface: Color
    let card: Color
    let text: Color
    let textDim: Color
    let textMid: Color
    let accent: Color
    let accentMid: Color
    let accentDim: Color
    let bar: [Color]   // exactly 5: [0]=empty [1]=low [2]=mid [3]=high [4]=peak
    let cal: [Color]   // exactly 5, same semantics
    let isDark: Bool
}

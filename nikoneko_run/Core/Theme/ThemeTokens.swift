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
    let bar: [Color]    // exactly 5: [0]=empty [1]=low [2]=mid [3]=high [4]=peak
    let onBar: [Color]  // exactly 5: text color to use ON bar[i] background
    let cal: [Color]    // exactly 5, same semantics
    let onCal: [Color]  // exactly 5: text color to use ON cal[i] background
    let isDark: Bool
}

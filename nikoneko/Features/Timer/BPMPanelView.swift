import SwiftUI

struct BPMPanelView: View {
    @Binding var bpm: Int
    @Environment(ThemeManager.self) private var themeManager

    private let minBPM = 140
    private let maxBPM = 220
    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        VStack(spacing: 12) {
            Text("BPM")
                .font(.system(size: 10, weight: .medium))
                .tracking(1)
                .foregroundColor(theme.textDim)

            Text("\(bpm)")
                .font(.system(size: 28, weight: .ultraLight))
                .foregroundColor(theme.text)
                .monospacedDigit()

            HStack(spacing: 8) {
                bpmButton(label: "−5", delta: -5)
                bpmButton(label: "−",  delta: -1)
                bpmButton(label: "+",  delta: +1)
                bpmButton(label: "+5", delta: +5)
            }
        }
        .padding(16)
        .background(theme.surface)
        .presentationDetents([.height(130)])
    }

    private func bpmButton(label: String, delta: Int) -> some View {
        Button(label) {
            bpm = min(maxBPM, max(minBPM, bpm + delta))
        }
        .font(.system(size: 14))
        .foregroundColor(theme.text)
        .frame(width: 44, height: 36)
        .background(theme.card)
        .cornerRadius(8)
    }
}

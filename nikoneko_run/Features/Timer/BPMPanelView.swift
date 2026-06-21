import SwiftUI

struct BPMPanelView: View {
    @Binding var bpm: Int
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    @FocusState private var isEditing: Bool
    @State private var inputText: String = ""

    private let minBPM = 140
    private let maxBPM = 220
    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        VStack(spacing: 8) {
            Text(lm.L("timer.bpm"))
                .font(.system(size: 14, weight: .medium))
                .tracking(1)
                .foregroundColor(theme.textDim)
                .padding(.top, 4)

            HStack(spacing: 8) {
                // Left: -5, -
                HStack(spacing: 6) {
                    bpmButton(label: "−5", delta: -5)
                    bpmButton(label: "−",  delta: -1)
                }

                // Center: number
                ZStack {
                    if isEditing {
                        TextField("", text: $inputText)
                            .font(.system(size: 48, weight: .ultraLight))
                            .foregroundColor(theme.text)
                            .multilineTextAlignment(.center)
                            .monospacedDigit()
                            .keyboardType(.numberPad)
                            .focused($isEditing)
                            .frame(width: 100, height: 56)
                            .onSubmit { commitInput() }
                            .onChange(of: inputText) { _, v in
                                inputText = v.filter(\.isNumber)
                            }
                    } else {
                        Text("\(bpm)")
                            .font(.system(size: 48, weight: .ultraLight))
                            .foregroundColor(theme.text)
                            .monospacedDigit()
                            .frame(width: 100, height: 56)
                            .onTapGesture {
                                inputText = "\(bpm)"
                                isEditing = true
                            }
                    }
                }

                // Right: +, +5
                HStack(spacing: 6) {
                    bpmButton(label: "+",  delta: +1)
                    bpmButton(label: "+5", delta: +5)
                }
            }

            if isEditing {
                Button(lm.L("timer.done")) { commitInput() }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.accent)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(theme.bg)
        .presentationDetents([.height(isEditing ? 220 : 160)])
        .onDisappear { commitInput() }
    }

    private func commitInput() {
        if let v = Int(inputText) {
            bpm = min(maxBPM, max(minBPM, v))
        }
        isEditing = false
    }

    private func bpmButton(label: String, delta: Int) -> some View {
        Button {
            bpm = min(maxBPM, max(minBPM, bpm + delta))
        } label: {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(theme.text)
                .frame(width: 52, height: 52)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(theme.card)
        .cornerRadius(10)
    }
}

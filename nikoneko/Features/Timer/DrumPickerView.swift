import SwiftUI

struct DrumPickerView: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let stepHeight: CGFloat = 28

    @State private var baseValue: Int = 0
    @Environment(ThemeManager.self) private var themeManager

    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        ZStack {
            ghostText(value: value + 1, offset: -stepHeight)
            selectedText(value: value)
            ghostText(value: value - 1, offset: stepHeight)
        }
        .gesture(
            DragGesture()
                .onChanged { g in
                    let steps = Self.stepsFrom(translationY: g.translation.height, stepHeight: stepHeight)
                    value = Self.clamped(baseValue + steps, to: range)
                }
                .onEnded { _ in
                    baseValue = value
                }
        )
        .onAppear { baseValue = value }
    }

    private func ghostText(value: Int, offset: CGFloat) -> some View {
        Text("\(value)")
            .font(.system(size: 48, weight: .ultraLight))
            .foregroundColor(theme.text.opacity(0.15))
            .offset(y: offset)
            .monospacedDigit()
    }

    private func selectedText(value: Int) -> some View {
        Text("\(value)")
            .font(.system(size: 70, weight: .ultraLight))
            .foregroundColor(theme.text)
            .monospacedDigit()
            .kerning(-3)
    }

    static func stepsFrom(translationY: CGFloat, stepHeight: CGFloat) -> Int {
        Int(-translationY / stepHeight)
    }

    static func clamped(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(range.upperBound, max(range.lowerBound, value))
    }
}

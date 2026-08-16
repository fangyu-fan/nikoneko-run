import SwiftUI

struct DrumPickerView: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    var hapticEnabled: Bool = true
    var zeroPadded: Bool = false

    @Environment(ThemeManager.self) private var themeManager
    private var theme: ThemeTokens { themeManager.current }

    private let rowHeight: CGFloat = 90
    private let stepDistance: CGFloat = 32

    @State private var startValue: Int = 0
    @State private var isDragging: Bool = false
    @State private var countsDown: Bool = false

    var body: some View {
        ZStack {
            if range.contains(value - 1) {
                slot(value - 1, isCenter: false).offset(y: -rowHeight)
            }
            slot(value, isCenter: true)
            if range.contains(value + 1) {
                slot(value + 1, isCenter: false).offset(y: rowHeight)
            }
        }
        .frame(height: rowHeight * 3)
        .clipped()
        .frame(maxWidth: .infinity)
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black, location: 0.22),
                    .init(color: .black, location: 0.78),
                    .init(color: .clear, location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .contentShape(Rectangle())
        .highPriorityGesture(
            DragGesture(minimumDistance: 4)
                .onChanged { g in
                    if !isDragging {
                        isDragging = true
                        startValue = value  // lock anchor at gesture start
                    }
                    countsDown = g.velocity.height < 0
                    let steps = Self.stepsFrom(
                        translationY: g.translation.height,
                        stepHeight: stepDistance
                    )
                    let next = Self.clamped(startValue + steps, to: range)
                    if next != value {
                        if hapticEnabled && (next / 10) != (value / 10) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        value = next
                    }
                }
                .onEnded { g in
                    let steps = Self.stepsFrom(
                        translationY: g.translation.height,
                        stepHeight: stepDistance
                    )
                    value = Self.clamped(startValue + steps, to: range)
                    isDragging = false
                }
        )
        .onAppear { startValue = value }
        .onChange(of: value) { _, v in
            if !isDragging { startValue = v }
        }
    }

    private func slot(_ num: Int, isCenter: Bool) -> some View {
        Text(zeroPadded ? String(format: "%02d", num) : "\(num)")
            .font(.system(size: isCenter ? 108 : 48,
                          weight: isCenter ? .ultraLight : .thin))
            .foregroundColor(theme.text.opacity(isCenter ? 1.0 : 0.20))
            .monospacedDigit()
            .kerning(isCenter ? -5 : -2)
            .fixedSize()
            .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: .center)
            .contentTransition(.numericText(countsDown: countsDown))
            .animation(.smooth(duration: 0.15), value: value)
    }

    static func clamped(_ v: Int, to range: ClosedRange<Int>) -> Int {
        min(range.upperBound, max(range.lowerBound, v))
    }

    static func stepsFrom(translationY: CGFloat, stepHeight: CGFloat) -> Int {
        Int((-translationY / stepHeight).rounded())
    }
}

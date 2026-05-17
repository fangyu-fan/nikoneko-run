import SwiftUI

struct DrumPickerView: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    @Environment(ThemeManager.self) private var themeManager
    private var theme: ThemeTokens { themeManager.current }

    private let rowHeight: CGFloat = 90
    @State private var baseValue: Int = 0

    var body: some View {
        ZStack {
            // Ghost above
            if range.contains(value - 1) {
                slot(value - 1, isCenter: false)
                    .offset(y: -rowHeight)
            }
            // Center
            slot(value, isCenter: true)
            // Ghost below
            if range.contains(value + 1) {
                slot(value + 1, isCenter: false)
                    .offset(y: rowHeight)
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
        .gesture(
            DragGesture()
                .onChanged { g in
                    let steps = Int((-g.translation.height / rowHeight).rounded())
                    let preview = Self.clamped(baseValue + steps, to: range)
                    if preview != value {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        value = preview
                    }
                }
                .onEnded { g in
                    let steps = Int((-g.translation.height / rowHeight).rounded())
                    value = Self.clamped(baseValue + steps, to: range)
                    baseValue = value
                }
        )
        .onAppear { baseValue = value }
    }

    // Each slot has the same fixed height so ZStack centers them correctly.
    // Center slot uses minimumScaleFactor(1) to prevent SwiftUI from shrinking the
    // 108pt numeral to fit inside rowHeight — it will overflow, which is intentional
    // (clipped by parent). This ensures the numeral's visual center matches the
    // running-state numeral which renders at full size in a taller frame.
    private func slot(_ num: Int, isCenter: Bool) -> some View {
        Text("\(num)")
            .font(.system(size: isCenter ? 108 : 48,
                          weight: isCenter ? .ultraLight : .thin))
            .foregroundColor(theme.text.opacity(isCenter ? 1.0 : 0.20))
            .monospacedDigit()
            .kerning(isCenter ? -5 : -2)
            .fixedSize()
            .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: .center)
            .animation(.easeOut(duration: 0.1), value: value)
    }

    static func clamped(_ v: Int, to range: ClosedRange<Int>) -> Int {
        min(range.upperBound, max(range.lowerBound, v))
    }
}

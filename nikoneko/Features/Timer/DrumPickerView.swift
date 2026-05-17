import SwiftUI

struct DrumPickerView: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        Text("\(value)")
    }

    static func stepsFrom(translationY: CGFloat, stepHeight: CGFloat) -> Int {
        Int(-translationY / stepHeight)
    }

    static func clamped(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(range.upperBound, max(range.lowerBound, value))
    }
}

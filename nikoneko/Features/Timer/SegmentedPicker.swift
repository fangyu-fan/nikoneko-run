import SwiftUI

struct SegmentedPicker: View {
    @Binding var selection: Int
    let segments: [String]
    let selectedTint: Color
    let background: Color
    let selectedTextColor: Color
    let normalTextColor: Color

    @Namespace private var ns

    private let height: CGFloat = 32
    private let cornerRadius: CGFloat = 7
    private let horizontalPad: CGFloat = 12

    var body: some View {
        HStack(spacing: 0) {
            ForEach(segments.indices, id: \.self) { i in
                let isSelected = selection == i
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(selectedTint)
                            .matchedGeometryEffect(id: "pill", in: ns)
                    }
                    Text(segments[i])
                        .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                        .foregroundColor(isSelected ? selectedTextColor : normalTextColor)
                        .padding(.horizontal, horizontalPad)
                }
                .frame(height: height)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selection = i
                    }
                }
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: cornerRadius + 2).fill(background))
    }
}

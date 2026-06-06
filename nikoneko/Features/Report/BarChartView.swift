import SwiftUI
import SwiftData

struct BarChartView: View {
    let bars: [ChartBar]
    var yUnit: String = ""
    var xUnit: String = ""
    var onTap: ((ChartBar, CGFloat) -> Void)? = nil  // bar, bar centerX in chart coords
    @Environment(ThemeManager.self) private var themeManager
    @Query private var configs: [ThresholdConfig]
    private var theme: ThemeTokens { themeManager.current }
    private var t1: Int { configs.first?.threshold1 ?? 25 }
    private var t2: Int { configs.first?.threshold2 ?? 60 }
    private var t3: Int { configs.first?.threshold3 ?? 90 }

    private let barAreaHeight: CGFloat = 140
    private let xLabelHeight: CGFloat = 14
    private let yAxisWidth: CGFloat = 28

    private var maxValue: Double { bars.map(\.value).max() ?? 1 }

    private var yLabels: [Double] {
        let top = maxValue > 0 ? maxValue : 1
        return [top, top / 2, 0]
    }

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            // Y axis — labels pinned at top, middle, and bottom of barAreaHeight
            // Bottom of Y axis (the "0" label) aligns exactly with the X axis line.
            VStack(alignment: .trailing, spacing: 0) {
                if !yUnit.isEmpty {
                    Text(yUnit)
                        .font(.system(size: 9))
                        .foregroundColor(theme.textDim)
                        .frame(height: 12, alignment: .top)
                }
                // top label
                Text(formatY(yLabels[0]))
                    .font(.system(size: 10))
                    .foregroundColor(theme.textDim)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Spacer()
                // mid label
                Text(formatY(yLabels[1]))
                    .font(.system(size: 10))
                    .foregroundColor(theme.textDim)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Spacer()
                // 0 label — bottom-aligned to X axis line
                Text("0")
                    .font(.system(size: 10))
                    .foregroundColor(theme.textDim)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(width: yAxisWidth, height: barAreaHeight)

            // Bars + X labels
            VStack(spacing: 0) {
                GeometryReader { chartGeo in
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(bars.indices, id: \.self) { i in
                            let ratio = maxValue > 0 ? bars[i].value / maxValue : 0
                            let hasValue = bars[i].value > 0
                            GeometryReader { barGeo in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(hasValue
                                          ? Self.barColor(ratio: ratio, theme: theme, t1: t1, t2: t2, t3: t3)
                                          : Color.clear)
                                    .frame(width: 6, height: hasValue ? max(2, ratio * barAreaHeight) : 0)
                                    .animation(.easeInOut(duration: 0.25), value: ratio)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                    .contentShape(Rectangle())
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { _ in
                                                if hasValue {
                                                    let centerX = barGeo.frame(in: .named("barChart")).midX
                                                    onTap?(bars[i], centerX)
                                                }
                                            }
                                            .onEnded { _ in
                                                onTap?(ChartBar(label: "", value: 0, isToday: false), 0)
                                            }
                                    )
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .frame(height: barAreaHeight)
                .coordinateSpace(name: "barChart")

                // X axis line
                Rectangle()
                    .fill(theme.textDim.opacity(0.3))
                    .frame(height: 0.5)

                // X labels — GeometryReader to place labels at correct x positions
                GeometryReader { geo in
                    let maxLabels = 6
                    let count = bars.count
                    let step = max(1, (count - 1) / (maxLabels - 1))
                    let indices = (0..<count).filter { i in
                        count <= maxLabels || i % step == 0 || i == count - 1
                    }
                    let barWidth = count > 0 ? geo.size.width / CGFloat(count) : geo.size.width
                    ForEach(indices, id: \.self) { i in
                        Text(bars[i].label)
                            .font(.system(size: 9))
                            .foregroundColor(theme.textDim)
                            .fixedSize()
                            .position(x: barWidth * CGFloat(i) + barWidth / 2, y: geo.size.height / 2)
                    }
                }
                .frame(height: xLabelHeight)

                if !xUnit.isEmpty {
                    Text(xUnit)
                        .font(.system(size: 9))
                        .foregroundColor(theme.textDim)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }

    private func formatY(_ v: Double) -> String {
        if v == 0 { return "0" }
        if v >= 1000 { return String(format: "%.0fk", v / 1000) }
        if v >= 10 { return "\(Int(v.rounded()))" }
        return String(format: "%.1f", v)
    }

    static func barColor(ratio: Double, theme: ThemeTokens, t1: Int, t2: Int, t3: Int) -> Color {
        let pct = Int(ratio * 100)
        if pct == 0          { return theme.bar[0] }
        if pct <= t1         { return theme.bar[1] }
        if pct < t2          { return theme.bar[2] }
        if pct <= t3         { return theme.bar[3] }
        return theme.bar[4]
    }
}

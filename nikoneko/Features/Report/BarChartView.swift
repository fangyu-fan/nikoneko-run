import SwiftUI

struct BarChartView: View {
    let bars: [ChartBar]
    @Environment(ThemeManager.self) private var themeManager
    private var theme: ThemeTokens { themeManager.current }

    private var maxValue: Double { bars.map(\.value).max() ?? 1 }

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(bars.indices, id: \.self) { i in
                let bar = bars[i]
                let ratio = maxValue > 0 ? bar.value / maxValue : 0
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Self.barColor(ratio: ratio, theme: theme, t1: 10, t2: 50, t3: 90))
                        .frame(height: max(2, ratio * 52))
                        .animation(.easeInOut(duration: 0.25), value: ratio)
                    Text(bar.label)
                        .font(.system(size: 6)).foregroundColor(theme.textDim)
                }
                .frame(maxWidth: .infinity)
            }
        }
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

import WidgetKit
import SwiftUI

@main
struct NikoNekoWidgetBundle: WidgetBundle {
    var body: some Widget {
        StatWidget()
        HeatmapWidget()
        BarChartWidget()
        CalendarWidget()
        AllStatsWidget()
    }
}

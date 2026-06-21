import WidgetKit
import SwiftUI
import ActivityKit

@main
struct NikoNekoWidgetBundle: WidgetBundle {
    var body: some Widget {
        StatWidget()
        HeatmapWidget()
        BarChartWidget()
        CalendarWidget()
        AllStatsWidget()
        NikoNekoLiveActivityView()
    }
}

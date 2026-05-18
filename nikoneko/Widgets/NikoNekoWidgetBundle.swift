import WidgetKit
import SwiftUI

@main
struct NikoNekoWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
        TodayDurationWidget()
        TodayDistanceWidget()
        TodayStepsWidget()
        HeatmapWidget()
        CalendarWidget()
        AllStatsWidget()
        NikoNekoLiveActivityView()
    }
}

import WidgetKit
import SwiftUI

@main
struct NikoNekoWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
        TotalTimeWidget()
        HeatmapWidget()
        CalendarWidget()
        NikoNekoLiveActivityView()
    }
}

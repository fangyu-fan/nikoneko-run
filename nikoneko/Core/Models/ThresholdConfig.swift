import Foundation
import SwiftData

@Model
final class ThresholdConfig {
    var widgetKind: String
    var threshold1: Int
    var threshold2: Int
    var threshold3: Int
    var cellInfo: WidgetCellInfo
    var showDayNumbers: Bool
    var showStreak: Bool
    var showTotalTime: Bool

    init(widgetKind: String) {
        self.widgetKind = widgetKind
        self.threshold1 = 10
        self.threshold2 = 50
        self.threshold3 = 90
        self.cellInfo = .duration
        self.showDayNumbers = true
        self.showStreak = true
        self.showTotalTime = true
    }
}

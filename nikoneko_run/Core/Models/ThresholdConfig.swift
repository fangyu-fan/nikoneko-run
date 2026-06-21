import Foundation
import SwiftData

@Model
final class ThresholdConfig {
    var widgetKind: String = ""
    var threshold1: Int = 10
    var threshold2: Int = 50
    var threshold3: Int = 90
    var cellInfoRaw: String = WidgetCellInfo.duration.rawValue
    var showDayNumbers: Bool = true
    var showStreak: Bool = true
    var showTotalTime: Bool = true

    var cellInfo: WidgetCellInfo {
        get { WidgetCellInfo(rawValue: cellInfoRaw) ?? .duration }
        set { cellInfoRaw = newValue.rawValue }
    }

    init(widgetKind: String) {
        self.widgetKind = widgetKind
    }
}

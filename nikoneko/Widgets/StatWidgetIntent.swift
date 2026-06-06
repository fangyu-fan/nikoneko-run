import AppIntents
import WidgetKit

// MARK: - StatMetric

enum StatMetric: String, AppEnum, CaseIterable {
    case streak
    case duration
    case distance
    case calories
    case steps
    case runs

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Metric")
    }

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .streak:   "Streak"
        case .duration: "Duration"
        case .distance: "Distance"
        case .calories: "Calories"
        case .steps:    "Steps"
        case .runs:     "Runs"
        }
    }

    static let caseDisplayRepresentations: [StatMetric: DisplayRepresentation] = [
        .streak:   DisplayRepresentation(title: "Streak"),
        .duration: DisplayRepresentation(title: "Duration"),
        .distance: DisplayRepresentation(title: "Distance"),
        .calories: DisplayRepresentation(title: "Calories"),
        .steps:    DisplayRepresentation(title: "Steps"),
        .runs:     DisplayRepresentation(title: "Runs"),
    ]
}

// MARK: - TimePeriod

enum TimePeriod: String, AppEnum, CaseIterable {
    case today
    case week
    case month
    case year

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Period")
    }

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .today: "Today"
        case .week:  "This week"
        case .month: "This month"
        case .year:  "This year"
        }
    }

    static let caseDisplayRepresentations: [TimePeriod: DisplayRepresentation] = [
        .today: DisplayRepresentation(title: "Today"),
        .week:  DisplayRepresentation(title: "This week"),
        .month: DisplayRepresentation(title: "This month"),
        .year:  DisplayRepresentation(title: "This year"),
    ]
}

// MARK: - StatWidgetIntent

struct StatWidgetIntent: AppIntent, WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Stat Widget"
    static let description = IntentDescription("Choose a metric and time period to display.")

    @Parameter(title: "Metric", default: .streak)
    var metric: StatMetric

    @Parameter(title: "Period", default: .week)
    var period: TimePeriod

    static var parameterSummary: some ParameterSummary {
        When(\StatWidgetIntent.$metric, .equalTo, .streak) {
            Summary("Show \(\.$metric)")
        } otherwise: {
            Summary("Show \(\.$metric) for \(\.$period)")
        }
    }
}

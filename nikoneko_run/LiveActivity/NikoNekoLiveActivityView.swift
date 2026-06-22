import SwiftUI
import ActivityKit
import WidgetKit

struct NikoNekoLiveActivityView: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NikoNekoLiveActivityAttributes.self) { context in
            let theme = WidgetSharedData.loadTheme()
            LockScreenCardView(state: context.state, theme: theme)
        } dynamicIsland: { context in
            let theme = WidgetSharedData.loadTheme()
            return DynamicIsland {
                // Expanded — shown when user taps Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("NIKONEKO RUN")
                            .font(.system(size: 8, weight: .medium))
                            .tracking(1.2)
                            .foregroundColor(theme.accent)

                        Text(timeString(context.state))
                            .font(.system(size: 28, weight: .ultraLight))
                            .foregroundColor(theme.text)
                            .monospacedDigit()

                        HStack(spacing: 8) {
                            Label("\(context.state.bpm) bpm", systemImage: "metronome")
                                .font(.system(size: 10))
                                .foregroundColor(theme.textMid)
                            if context.state.hr > 0 {
                                Label("\(context.state.hr)", systemImage: "heart.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(theme.accent)
                            }
                        }
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 28, weight: .ultraLight))
                            .foregroundColor(theme.accentMid)

                        if context.state.distance > 0 {
                            Text(String(format: "%.2f km", context.state.distance / 1000))
                                .font(.system(size: 10))
                                .foregroundColor(theme.textMid)
                                .monospacedDigit()
                        }
                    }
                    .padding(.trailing, 4)
                }
            } compactLeading: {
                Image(systemName: "figure.run")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(theme.accentMid)
            } compactTrailing: {
                Text(timeString(context.state))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.text)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "figure.run")
                    .font(.system(size: 12))
                    .foregroundColor(theme.accentMid)
            }
        }
    }

    private func timeString(_ state: NikoNekoLiveActivityAttributes.ContentState) -> String {
        let t = state.isCountdown ? state.remaining : state.elapsed
        let min = Int(max(0, t) / 60)
        let sec = Int(max(0, t)) % 60
        return String(format: "%d:%02d", min, sec)
    }
}

struct LockScreenCardView: View {
    let state: NikoNekoLiveActivityAttributes.ContentState
    let theme: ThemeTokens

    var body: some View {
        HStack(spacing: 12) {
            // Left: title + time + BPM
            VStack(alignment: .leading, spacing: 4) {
                Text("NIKONEKO RUN")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(1.2)
                    .foregroundColor(theme.accent)

                Text(formattedTime)
                    .font(.system(size: 40, weight: .ultraLight))
                    .foregroundColor(theme.text)
                    .monospacedDigit()

                HStack(spacing: 10) {
                    Label("\(state.bpm) bpm", systemImage: "metronome")
                        .font(.system(size: 11))
                        .foregroundColor(theme.textMid)

                    if state.hr > 0 {
                        Label("\(state.hr)", systemImage: "heart.fill")
                            .font(.system(size: 11))
                            .foregroundColor(theme.accent)
                    }

                    if state.distance > 0 {
                        Label(String(format: "%.2f km", state.distance / 1000), systemImage: "location.fill")
                            .font(.system(size: 11))
                            .foregroundColor(theme.textMid)
                            .monospacedDigit()
                    }
                }
            }

            Spacer()

            // Right: running figure
            Image(systemName: "figure.run")
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundColor(theme.accentMid)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(theme.bg)
    }

    private var formattedTime: String {
        let t = state.isCountdown ? state.remaining : state.elapsed
        let min = Int(max(0, t) / 60)
        let sec = Int(max(0, t)) % 60
        return String(format: "%d:%02d", min, sec)
    }
}

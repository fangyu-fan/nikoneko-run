import SwiftUI
import ActivityKit
import WidgetKit

struct NikoNekoLiveActivityView: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NikoNekoLiveActivityAttributes.self) { context in
            let theme = WidgetSharedData.loadTheme()
            LockScreenLiveView(state: context.state, theme: theme)
        } dynamicIsland: { context in
            let theme = WidgetSharedData.loadTheme()
            return DynamicIsland {
                // Expanded — tapping the island
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("NIKONEKO RUN")
                            .font(.system(size: 8, weight: .medium))
                            .tracking(1.2)
                            .foregroundColor(theme.accent)

                        liveTimerText(context.state)
                            .font(.system(size: 28, weight: .ultraLight))
                            .foregroundColor(.white)
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
                            if context.state.distance > 0 {
                                Label(String(format: "%.2fkm", context.state.distance / 1000),
                                      systemImage: "location.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(theme.textMid)
                                    .monospacedDigit()
                            }
                        }
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    LottieCharacterView(
                        characterId: context.state.characterId,
                        color: theme.accentMid,
                        bpm: context.state.bpm,
                        isAnimating: true
                    )
                    .frame(width: 52, height: 40)
                    .padding(.trailing, 4)
                }
            } compactLeading: {
                // Cat animation in compact left slot
                LottieCharacterView(
                    characterId: context.state.characterId,
                    color: theme.accentMid,
                    bpm: context.state.bpm,
                    isAnimating: true
                )
                .frame(width: 24, height: 20)
            } compactTrailing: {
                // Live counting time — white for visibility on black island
                liveTimerText(context.state)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .monospacedDigit()
            } minimal: {
                LottieCharacterView(
                    characterId: context.state.characterId,
                    color: theme.accentMid,
                    bpm: context.state.bpm,
                    isAnimating: true
                )
                .frame(width: 18, height: 16)
            }
        }
    }

    // Returns a Text that counts automatically using the system timer
    @ViewBuilder
    private func liveTimerText(_ state: NikoNekoLiveActivityAttributes.ContentState) -> some View {
        if state.isCountdown {
            let end = state.startDate.addingTimeInterval(state.targetDuration)
            Text(timerInterval: state.startDate...end, countsDown: true)
        } else {
            Text(timerInterval: state.startDate...Date.distantFuture, countsDown: false)
        }
    }
}

// MARK: - Lock Screen / Notification Banner

struct LockScreenLiveView: View {
    let state: NikoNekoLiveActivityAttributes.ContentState
    let theme: ThemeTokens

    var body: some View {
        HStack(spacing: 14) {
            // Left: title, live timer, metrics
            VStack(alignment: .leading, spacing: 5) {
                Text("NIKONEKO RUN")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(1.2)
                    .foregroundColor(theme.accent)

                liveTimerText
                    .font(.system(size: 40, weight: .ultraLight))
                    .foregroundColor(theme.text)
                    .monospacedDigit()

                HStack(spacing: 12) {
                    Label("\(state.bpm) bpm", systemImage: "metronome")
                        .font(.system(size: 11))
                        .foregroundColor(theme.textMid)

                    if state.hr > 0 {
                        Label("\(state.hr)", systemImage: "heart.fill")
                            .font(.system(size: 11))
                            .foregroundColor(theme.accent)
                    }

                    if state.distance > 0 {
                        Label(String(format: "%.2f km", state.distance / 1000),
                              systemImage: "location.fill")
                            .font(.system(size: 11))
                            .foregroundColor(theme.textMid)
                            .monospacedDigit()
                    }
                }
            }

            Spacer()

            // Right: Lottie cat
            LottieCharacterView(
                characterId: state.characterId,
                color: theme.accentMid,
                bpm: state.bpm,
                isAnimating: true
            )
            .frame(width: 52, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(theme.bg)
    }

    @ViewBuilder
    private var liveTimerText: some View {
        if state.isCountdown {
            let end = state.startDate.addingTimeInterval(state.targetDuration)
            Text(timerInterval: state.startDate...end, countsDown: true)
        } else {
            Text(timerInterval: state.startDate...Date.distantFuture, countsDown: false)
        }
    }
}

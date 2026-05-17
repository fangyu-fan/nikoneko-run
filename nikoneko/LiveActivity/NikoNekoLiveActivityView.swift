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
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("JOG").font(.system(size: 8)).tracking(1).foregroundColor(theme.textDim)
                        Text(formattedTime(context.state))
                            .font(.system(size: 26, weight: .ultraLight)).foregroundColor(theme.text)
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        PlaceholderCharacterView(
                            characterId: context.state.characterId,
                            color: theme.accentMid,
                            bpm: context.state.bpm,
                            isAnimating: true
                        )
                        .frame(width: 44, height: 32)
                        Text("♩ \(context.state.bpm)")
                            .font(.system(size: 9)).foregroundColor(theme.textDim)
                    }
                }
            } compactLeading: {
                PlaceholderCharacterView(
                    characterId: context.state.characterId,
                    color: theme.accentMid,
                    bpm: context.state.bpm,
                    isAnimating: true
                )
                .frame(width: 22, height: 22)
            } compactTrailing: {
                Text(formattedTime(context.state))
                    .font(.system(size: 14, weight: .light)).foregroundColor(theme.text)
                    .monospacedDigit()
            } minimal: {
                PlaceholderCharacterView(
                    characterId: context.state.characterId,
                    color: theme.accentMid,
                    bpm: context.state.bpm,
                    isAnimating: true
                )
                .frame(width: 18, height: 18)
            }
        }
    }

    private func formattedTime(_ state: NikoNekoLiveActivityAttributes.ContentState) -> String {
        let t = state.isCountdown ? state.remaining : state.elapsed
        let min = Int(t / 60)
        let sec = Int(t) % 60
        return String(format: "%d:%02d", min, sec)
    }
}

struct LockScreenCardView: View {
    let state: NikoNekoLiveActivityAttributes.ContentState
    let theme: ThemeTokens

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("JOG").font(.system(size: 8)).tracking(1).foregroundColor(theme.textDim)
                Text(formattedTime)
                    .font(.system(size: 36, weight: .ultraLight)).foregroundColor(theme.text)
                    .monospacedDigit()
                Text("♩ \(state.bpm)").font(.system(size: 10)).foregroundColor(theme.textDim)
            }
            Spacer()
            PlaceholderCharacterView(
                characterId: state.characterId,
                color: theme.accentMid,
                bpm: state.bpm,
                isAnimating: true
            )
            .frame(width: 52, height: 40)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(theme.bg.opacity(0.88))
    }

    private var formattedTime: String {
        let t = state.isCountdown ? state.remaining : state.elapsed
        let min = Int(t / 60)
        let sec = Int(t) % 60
        return String(format: "%d:%02d", min, sec)
    }
}

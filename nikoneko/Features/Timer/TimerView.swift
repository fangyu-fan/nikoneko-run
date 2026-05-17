import SwiftUI

struct TimerView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var vm = TimerViewModel()
    @State private var longPressProgress: CGFloat = 0
    @State private var showCharacterPicker = false
    @State private var showBPMPanel = false
    @State private var bpm: Int = 180
    @State private var characterId: String = "cat_a"

    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                PlaceholderCharacterView(
                    characterId: characterId,
                    color: theme.accentMid,
                    bpm: bpm,
                    isAnimating: vm.state == .running
                )
                .frame(height: 36)
                .onTapGesture { showCharacterPicker = true }
                .padding(.top, 22)

                Spacer()

                if vm.state == .idle {
                    DrumPickerView(value: $vm.selectedMinutes, range: 1...999)
                        .frame(height: 120)
                } else {
                    timerNumeralView
                }

                Spacer()

                Text("♥ --")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(theme.textMid)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)

                Spacer()

                HStack {
                    Button("♩ \(bpm)") { showBPMPanel = true }
                        .font(.system(size: 13))
                        .foregroundColor(theme.textDim)
                    Spacer()
                }
                .padding(.horizontal, 16)

                actionButton
                    .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showCharacterPicker) {
            CharacterPickerView(selectedId: $characterId)
        }
        .popover(isPresented: $showBPMPanel) {
            BPMPanelView(bpm: $bpm)
        }
    }

    private var timerNumeralView: some View {
        VStack(spacing: 2) {
            Text("\(vm.displayMinutes)")
                .font(.system(size: 70, weight: .ultraLight))
                .foregroundColor(theme.text)
                .monospacedDigit()
                .kerning(-3)
            if vm.isCountdown {
                Text(": \(String(format: "%02d", vm.displaySeconds))")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(theme.textDim)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            vm.state == .running ? vm.pause() : vm.resume()
        }
    }

    private var actionButton: some View {
        ZStack {
            Circle()
                .strokeBorder(theme.accentDim, lineWidth: 1)
                .frame(width: 64, height: 64)

            if vm.state == .running {
                Circle()
                    .trim(from: 0, to: longPressProgress)
                    .stroke(theme.accentMid, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
            }

            Image(systemName: vm.state == .idle ? "play.fill" : "stop.fill")
                .font(.system(size: vm.state == .idle ? 22 : 16))
                .foregroundColor(vm.state == .idle ? theme.text : theme.textMid)
        }
        .onTapGesture {
            if vm.state == .idle {
                vm.targetDuration = Double(vm.selectedMinutes) * 60
                vm.start(bpm: bpm, characterId: characterId, themeId: themeManager.current.id)
            }
        }
        .onLongPressGesture(minimumDuration: 2.0, pressing: { pressing in
            if pressing && vm.state != .idle {
                withAnimation(.linear(duration: 2.0)) { longPressProgress = 1.0 }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { longPressProgress = 0 }
            }
        }, perform: {
            if vm.state != .idle {
                vm.stopAndSave(bpm: bpm, characterId: characterId,
                               themeId: themeManager.current.id,
                               distance: 0, calories: 0, steps: 0,
                               avgHR: 0, maxHR: 0, avgCadence: 0)
                withAnimation(.easeOut(duration: 0.2)) { longPressProgress = 0 }
            }
        })
    }
}

#if DEBUG
#Preview {
    TimerView()
        .environment(ThemeManager())
}
#endif

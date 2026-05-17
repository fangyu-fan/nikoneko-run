import SwiftUI

struct TimerView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var vm = TimerViewModel()
    @State private var longPressProgress: CGFloat = 0
    @State private var showCharacterPicker = false
    @State private var showBPMPanel = false
    @State private var bpm: Int = 180
    @State private var volume: Double = 0.6
    @State private var characterId: String = "cat_a"

    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Character strip
                LottieCharacterView(
                    characterId: characterId,
                    color: theme.accentMid,
                    bpm: bpm,
                    isAnimating: vm.state == .running
                )
                .frame(height: 36)
                .onTapGesture { showCharacterPicker = true }
                .padding(.top, 22)

                Spacer()

                // Time numeral area
                if vm.state == .idle {
                    DrumPickerView(value: $vm.selectedMinutes, range: 1...999)
                        .frame(height: 120)
                } else {
                    timerNumeralView
                }

                Spacer()

                // Live metrics
                metricsBlock

                Spacer()

                // BPM + volume ctrl row
                ctrlRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, 9)

                // Action button
                actionButtonArea
                    .padding(.bottom, 24)
            }
        }
        .onChange(of: vm.state) { _, newState in
            if newState == .idle {
                withAnimation(.easeOut(duration: 0.2)) { longPressProgress = 0 }
            }
        }
        .sheet(isPresented: $showCharacterPicker) {
            CharacterPickerView(selectedId: $characterId)
        }
        .popover(isPresented: $showBPMPanel) {
            BPMPanelView(bpm: $bpm)
        }
    }

    // MARK: - Timer numeral

    private var timerNumeralView: some View {
        VStack(spacing: 2) {
            Text("\(vm.displayMinutes)")
                .font(.system(size: 70, weight: .ultraLight))
                .foregroundColor(theme.text)
                .monospacedDigit()
                .kerning(-3)
            if vm.state == .running && vm.isCountdown {
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

    // MARK: - Live metrics

    private var metricsBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            metricItem(icon: "♥", value: "—", unit: nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 16)
    }

    private func metricItem(icon: String, value: String, unit: String?) -> some View {
        HStack(spacing: 3) {
            Text(icon)
                .font(.system(size: 10))
                .foregroundColor(theme.textDim)
            Text(value)
                .font(.system(size: 13, weight: .light))
                .foregroundColor(theme.textMid)
                .monospacedDigit()
            if let unit {
                Text(unit)
                    .font(.system(size: 9))
                    .foregroundColor(theme.textDim)
            }
        }
    }

    // MARK: - Ctrl row (BPM + volume)

    private var ctrlRow: some View {
        HStack {
            // BPM tap target
            Button(action: { showBPMPanel = true }) {
                HStack(spacing: 3) {
                    Text("♩")
                        .font(.system(size: 10))
                        .foregroundColor(theme.textDim)
                    Text("\(bpm)")
                        .font(.system(size: 10))
                        .foregroundColor(theme.textDim)
                        .monospacedDigit()
                    Text("bpm")
                        .font(.system(size: 8))
                        .foregroundColor(theme.textDim)
                }
            }

            Spacer()

            // Volume slider
            HStack(spacing: 4) {
                Text("♪")
                    .font(.system(size: 9))
                    .foregroundColor(theme.textDim)

                volumeSlider

                Text("♫")
                    .font(.system(size: 9))
                    .foregroundColor(theme.textDim)
            }
        }
    }

    private var volumeSlider: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(theme.accentDim)
                    .frame(height: 1.5)

                // Fill
                Capsule()
                    .fill(theme.textDim)
                    .frame(width: geo.size.width * volume, height: 1.5)

                // Thumb
                Circle()
                    .fill(theme.textMid)
                    .frame(width: 8, height: 8)
                    .offset(x: geo.size.width * volume - 4)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        volume = min(1, max(0, v.location.x / geo.size.width))
                    }
            )
        }
        .frame(width: 48, height: 8)
    }

    // MARK: - Action button

    private var actionButtonArea: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .strokeBorder(theme.accentDim, lineWidth: 1)
                    .frame(width: 64, height: 64)

                if vm.state == .running {
                    Circle()
                        .trim(from: 0, to: longPressProgress)
                        .stroke(theme.accentMid,
                                style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                }

                Image(systemName: vm.state == .idle ? "play.fill" : "stop.fill")
                    .font(.system(size: vm.state == .idle ? 22 : 16))
                    .foregroundColor(vm.state == .idle ? theme.text : theme.textMid)
            }
            .simultaneousGesture(TapGesture().onEnded {
                guard vm.state == .idle else { return }
                vm.targetDuration = Double(vm.selectedMinutes) * 60
                vm.start(bpm: bpm, characterId: characterId, themeId: themeManager.current.id)
            })
            .onLongPressGesture(minimumDuration: 2.0, pressing: { pressing in
                if pressing && vm.state != .idle {
                    withAnimation(.linear(duration: 2.0)) { longPressProgress = 1.0 }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) { longPressProgress = 0 }
                }
            }, perform: {
                guard vm.state != .idle else { return }
                vm.stopAndSave(
                    bpm: bpm, characterId: characterId, themeId: themeManager.current.id,
                    distance: 0, calories: 0, steps: 0,
                    avgHR: 0, maxHR: 0, avgCadence: 0
                )
                withAnimation(.easeOut(duration: 0.2)) { longPressProgress = 0 }
            })

            Text(vm.state == .idle ? "tap to start" : "hold 2s to stop")
                .font(.system(size: 6.5))
                .foregroundColor(theme.textDim)
        }
    }
}

#if DEBUG
#Preview {
    TimerView()
        .environment(ThemeManager())
}
#endif

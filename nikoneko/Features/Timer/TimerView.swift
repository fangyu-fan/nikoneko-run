import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }
    @Bindable var vm: TimerViewModel
    @State private var selectedHours: Int = 0
    @State private var metronome = MetronomeService()
    @State private var hrService = HeartRateService()
    @State private var motionService = MotionService()
    @State private var longPressProgress: CGFloat = 0
    @State private var showBPMPanel = false
    @State private var bpm: Int = 180
    @State private var volume: Double = 0.6

    private var theme: ThemeTokens { themeManager.current }
    private let numeralHeight: CGFloat = 360

    // MARK: - Display helpers

    private var timeDisplayFormat: TimeFormat {
        profile?.timeDisplayFormat ?? .plainMinutes
    }

    /// Large numeral when running
        // Plain mode big numeral: minutes
    private var primaryTimeText: String {
        let seconds = vm.isCountdown ? vm.remaining : vm.elapsed
        return "\(Int(seconds / 60))"
    }

    // Plain mode seconds overlay
    private var secondaryTimeText: String {
        guard vm.state != .idle else { return " " }
        let seconds = vm.isCountdown ? vm.remaining : vm.elapsed
        return String(format: "%02d", Int(seconds) % 60)
    }

    // HH:MM mode — separate HH and MM for identical slot sizing
    private var hhText: String {
        let seconds = vm.isCountdown ? vm.remaining : vm.elapsed
        return String(format: "%02d", Int(seconds) / 3600)
    }

    private var mmText: String {
        let seconds = vm.isCountdown ? vm.remaining : vm.elapsed
        return String(format: "%02d", (Int(seconds) % 3600) / 60)
    }

    private var ssText: String {
        let seconds = vm.isCountdown ? vm.remaining : vm.elapsed
        return String(format: "%02d", Int(seconds) % 60)
    }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Character strip
                LottieCharacterView(
                    color: theme.accentMid,
                    bpm: bpm,
                    isAnimating: vm.state == .running
                )
                .frame(width: 72, height: 52)
                .frame(maxWidth: .infinity)
                .padding(.top, 116)

                Spacer(minLength: 0)

                // Numeral zone — idle and running share the same ZStack.
                // DrumPickerView center slot uses .fixedSize() so its 108pt numeral renders
                // at true size (overflowing rowHeight), matching the running numeral's layout.
                // Both therefore have the same visual center = ZStack geometric center.
                ZStack(alignment: .center) {
                    // Plain mode — single minutes wheel (untouched)
                    if timeDisplayFormat != .hhMM {
                        DrumPickerView(value: $vm.selectedMinutes, range: 1...999,
                                      hapticEnabled: profile?.hapticEnabled ?? true)
                            .opacity(vm.state == .idle ? 1 : 0)
                            .allowsHitTesting(vm.state == .idle)

                        // Plain running numeral — ZStack so offset is from center, matching DrumPickerView ghost
                        ZStack {
                            Text(primaryTimeText)
                                .font(.system(size: 108, weight: .ultraLight))
                                .foregroundColor(theme.text)
                                .monospacedDigit()
                                .kerning(-5)
                                .fixedSize()

                            if vm.state != .idle {
                                Text(secondaryTimeText)
                                    .font(.system(size: 48, weight: .thin))
                                    .foregroundColor(theme.text)
                                    .monospacedDigit()
                                    .fixedSize()
                                    .offset(y: 90)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .opacity(vm.state != .idle ? 1 : 0)
                        .allowsHitTesting(vm.state != .idle)
                        .onTapGesture(count: 2) {
                            vm.state == .running ? vm.pause() : vm.resume()
                        }
                    }

                    // HH:MM mode — SAME layout for idle and running, only content changes
                    if timeDisplayFormat == .hhMM {
                        ZStack(alignment: .center) {
                            Color.clear.frame(maxWidth: .infinity)

                            // Identical HStack structure for both idle and running.
                            // Idle: DrumPickers. Running: Text numerals.
                            // Width is always: SS_mirror + HH + colon + MM + SS
                            HStack(alignment: .bottom, spacing: 0) {
                                // Left mirror of SS — keeps HH:MM centered
                                Text("00")
                                    .font(.system(size: 32, weight: .ultraLight))
                                    .monospacedDigit()
                                    .fixedSize()
                                    .hidden()
                                    .padding(.trailing, 4)

                                // HH slot
                                Group {
                                    if vm.state == .idle {
                                        DrumPickerView(value: $selectedHours, range: 0...9,
                                                      hapticEnabled: profile?.hapticEnabled ?? true)
                                            .frame(width: 120)
                                    } else {
                                        Text(hhText)
                                            .font(.system(size: 80, weight: .ultraLight))
                                            .foregroundColor(theme.text)
                                            .monospacedDigit()
                                            .kerning(-3)
                                            .fixedSize()
                                            .frame(width: 100, alignment: .center)
                                    }
                                }

                                // Colon
                                Text(":")
                                    .font(.system(size: 72, weight: .ultraLight))
                                    .foregroundColor(theme.text)
                                    .padding(.bottom, vm.state == .idle ? 8 : 0)

                                // MM slot
                                Group {
                                    if vm.state == .idle {
                                        DrumPickerView(value: $vm.selectedMinutes, range: 0...59,
                                                      hapticEnabled: profile?.hapticEnabled ?? true)
                                            .frame(width: 120)
                                    } else {
                                        Text(mmText)
                                            .font(.system(size: 80, weight: .ultraLight))
                                            .foregroundColor(theme.text)
                                            .monospacedDigit()
                                            .kerning(-3)
                                            .fixedSize()
                                            .frame(width: 100, alignment: .center)
                                    }
                                }

                                // SS — hidden in idle, visible when running
                                Text(vm.state != .idle ? ssText : "00")
                                    .font(.system(size: 32, weight: .ultraLight))
                                    .foregroundColor(theme.text)
                                    .monospacedDigit()
                                    .fixedSize()
                                    .opacity(vm.state != .idle ? 1 : 0)
                                    .padding(.leading, 4)
                                    .padding(.bottom, 6)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            guard vm.state != .idle else { return }
                            vm.state == .running ? vm.pause() : vm.resume()
                        }
                        .allowsHitTesting(true)
                    }
                }
                .frame(height: numeralHeight)

                Spacer(minLength: 32)

                // Live metrics — fixed height so it never shifts
                metricsBlock
                    .frame(height: 28)
                    .padding(.bottom, 20)

                // BPM + volume ctrl row
                ctrlRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)

                // Action button
                actionButtonArea
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            bpm = profile?.defaultBPM ?? 180
            let defMins = profile?.defaultDuration ?? 15
            selectedHours = defMins / 60
            vm.selectedMinutes = defMins % 60
            vm.isCountdown = (profile?.timerMode ?? .countdown) == .countdown
            volume = 0.6
            metronome.soundType = profile?.soundType ?? .tap
            metronome.volume = Float(volume)
            Task { await HealthKitService.shared.requestPermissions() }
        }
        .onChange(of: vm.state) { _, newState in
            switch newState {
            case .running:
                metronome.start()
                motionService.weightKg = profile?.weightKg ?? 65
                motionService.heightCm = profile?.heightCm ?? 170
                hrService.startMonitoring()
                motionService.startTracking()
            case .paused:
                metronome.pause()
            case .idle:
                metronome.stop()
                hrService.stopMonitoring()
                motionService.stopTracking()
                withAnimation(.easeOut(duration: 0.2)) { longPressProgress = 0 }
            }
        }
        .onChange(of: bpm) { _, newBPM in
            metronome.updateBPM(newBPM)
        }
        .sheet(isPresented: $showBPMPanel) {
            BPMPanelView(bpm: $bpm)
                .presentationBackground(theme.bg)
                .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Live metrics

    private var metricsBlock: some View {
        HStack(spacing: 28) {
            if vm.state == .running {
                if profile?.showHR ?? true {
                    metricItem(icon: "heart",
                               value: hrService.currentHR > 0 ? "\(hrService.currentHR)" : "—",
                               unit: nil)
                }
                if profile?.showDistance ?? true {
                    metricItem(icon: "location.circle",
                               value: String(format: "%.2f", motionService.distance / 1000),
                               unit: "km")
                }
                if profile?.showCalories ?? true {
                    metricItem(icon: "flame",
                               value: "\(Int(motionService.calories))",
                               unit: nil)
                }
                if profile?.showSteps ?? true {
                    metricItem(icon: "shoeprints.fill",
                               value: "\(motionService.steps)",
                               unit: nil)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func metricItem(icon: String, value: String, unit: String?) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(theme.text)
            Text(value)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(theme.text)
                .monospacedDigit()
            if let unit {
                Text(unit)
                    .font(.system(size: 16))
                    .foregroundColor(theme.text)
            }
        }
    }

    // MARK: - Ctrl row (BPM + volume)

    private var ctrlRow: some View {
        HStack(spacing: 32) {
            Spacer()

            Button(action: { showBPMPanel = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "metronome")
                        .font(.system(size: 16))
                        .foregroundColor(theme.text)
                    Text("\(bpm)")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(theme.text)
                        .monospacedDigit()
                    Text(lm.L("timer.bpm"))
                        .font(.system(size: 16))
                        .foregroundColor(theme.text)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(theme.text)
                volumeSlider
            }

            Spacer()
        }
    }

    private var volumeSlider: some View {
        let locked = profile?.volumeLockEnabled == true
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(theme.accentDim)
                    .frame(height: 3)
                Capsule()
                    .fill(theme.textMid)
                    .frame(width: geo.size.width * volume, height: 3)
                Circle()
                    .fill(theme.text)
                    .frame(width: 14, height: 14)
                    .offset(x: geo.size.width * volume - 7)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        volume = min(1, max(0, v.location.x / geo.size.width))
                        metronome.volume = Float(volume)
                    }
            )
            .allowsHitTesting(!locked)
        }
        .frame(width: 88, height: 14)
    }

    // MARK: - Action button

    private var actionButtonArea: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(theme.surface, lineWidth: 2)
                    .frame(width: 128, height: 128)

                if vm.state == .running {
                    Circle()
                        .trim(from: 0, to: longPressProgress)
                        .stroke(theme.accentMid,
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                }

                Image(systemName: vm.state == .idle ? "play.fill" : "stop.fill")
                    .font(.system(size: vm.state == .idle ? 44 : 32, weight: .medium))
                    .foregroundColor(vm.state == .idle ? theme.text : theme.accentMid)
            }
            .simultaneousGesture(TapGesture().onEnded {
                guard vm.state == .idle else { return }
                vm.targetDuration = timeDisplayFormat == .hhMM
                    ? Double(selectedHours * 3600 + vm.selectedMinutes * 60)
                    : Double(vm.selectedMinutes) * 60
                vm.start(bpm: bpm, characterId: "loader_cat", themeId: themeManager.current.id)
            })
            .onLongPressGesture(minimumDuration: 1.0, pressing: { pressing in
                if pressing && vm.state != .idle {
                    withAnimation(.linear(duration: 1.0)) { longPressProgress = 1.0 }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) { longPressProgress = 0 }
                }
            }, perform: {
                guard vm.state != .idle else { return }
                hrService.stopMonitoring()
                motionService.stopTracking()
                vm.stopAndSave(
                    bpm: bpm, characterId: "loader_cat", themeId: themeManager.current.id,
                    distance: motionService.distance,
                    calories: motionService.calories,
                    steps: motionService.steps,
                    avgHR: hrService.avgHR,
                    maxHR: hrService.maxHR,
                    avgCadence: motionService.avgCadence
                )
                withAnimation(.easeOut(duration: 0.2)) { longPressProgress = 0 }
            })

            Text(" ")
                .font(.system(size: 14))
        }
        .frame(height: 169)
    }
}

private struct NumeralBottomKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

#if DEBUG
#Preview {
    TimerView(vm: TimerViewModel())
        .environment(ThemeManager())
        .environment(LanguageManager())
}
#endif

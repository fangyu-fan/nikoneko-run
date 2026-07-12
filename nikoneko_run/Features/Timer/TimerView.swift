import SwiftUI
import SwiftData
import WidgetKit

struct TimerView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }
    @Bindable var vm: TimerViewModel
    @State private var selectedHours: Int = 0
    @State private var selectedSeconds: Int = 0
    @State private var metronome = MetronomeService()
    @State private var hrService = HeartRateService()
    @State private var motionService = MotionService()
    @State private var longPressProgress: CGFloat = 0
    @State private var isLongPressing: Bool = false
    @State private var isLongPressingPending: Bool = false
    @State private var stopWorkItem: DispatchWorkItem? = nil
    @State private var didCompleteStop: Bool = false
    @State private var showBPMPanel = false
    @State private var showCharacterPicker = false
    @State private var savedSession: RunSession? = nil
    @State private var bpm: Int = 180
    @State private var volume: Double = 0.6
    @Environment(\.modelContext) private var ctx

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
        return "\(Int(seconds) / 3600)"
    }

    private var mmText: String {
        let seconds = vm.isCountdown ? vm.remaining : vm.elapsed
        return String(format: "%02d", (Int(seconds) % 3600) / 60)
    }

    private var ssText: String {
        let seconds = vm.isCountdown ? vm.remaining : vm.elapsed
        return String(format: "%02d", Int(seconds) % 60)
    }

    private var hhmmssText: String {
        let seconds = vm.isCountdown ? vm.remaining : vm.elapsed
        let hh = Int(seconds) / 3600
        let mm = (Int(seconds) % 3600) / 60
        let ss = Int(seconds) % 60
        return String(format: "%d:%02d:%02d", hh, mm, ss)
    }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            // Centred run-complete popup
            if let session = savedSession {
                // Dim background — tap to dismiss
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeOut(duration: 0.2)) { savedSession = nil } }
                    .transition(.opacity)
                    .zIndex(1)

                // Card — absorbs taps so they don't fall through to background
                SessionDetailSheet(session: session, onDismiss: {
                    withAnimation(.easeOut(duration: 0.2)) { savedSession = nil }
                })
                .frame(maxWidth: 340)
                .fixedSize(horizontal: false, vertical: true)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 24, y: 8)
                .padding(.horizontal, 20)
                .contentShape(Rectangle())
                .onTapGesture {}  // absorb taps on card — only ✕ button closes
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(2)
            }

            VStack(spacing: 0) {
                // Character strip
                LottieCharacterView(
                    characterId: profile?.activeCharacterId ?? "loader_cat",
                    color: theme.accentMid,
                    shadowColor: theme.accentDim,
                    bpm: bpm,
                    isAnimating: vm.state == .running
                )
                .frame(width: 72, height: 52)
                .frame(maxWidth: .infinity)
                .padding(.top, 116)
                .onTapGesture {
                    guard vm.state == .idle else { return }
                    showCharacterPicker = true
                }

                Spacer(minLength: 0)

                // Numeral zone — idle and running share the same ZStack.
                // DrumPickerView center slot uses .fixedSize() so its 108pt numeral renders
                // at true size (overflowing rowHeight), matching the running numeral's layout.
                // Both therefore have the same visual center = ZStack geometric center.
                ZStack(alignment: .center) {
                    // Plain mode idle
                    if timeDisplayFormat != .hhMM {
                        if vm.isCountdown {
                            // Countdown: scrollable minutes picker
                            DrumPickerView(value: $vm.selectedMinutes,
                                          range: 1...999,
                                          hapticEnabled: profile?.hapticEnabled ?? true)
                                .opacity(vm.state == .idle ? 1 : 0)
                                .allowsHitTesting(vm.state == .idle)
                        } else {
                            // Stopwatch: static 0 — no picker
                            Text("0")
                                .font(.system(size: 108, weight: .ultraLight))
                                .foregroundColor(theme.text)
                                .monospacedDigit()
                                .kerning(-5)
                                .fixedSize()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .opacity(vm.state == .idle ? 1 : 0)
                        }

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
                    }

                    // HH:MM mode — HH:MM:SS three equal slots, same size idle and running
                    if timeDisplayFormat == .hhMM {
                        ZStack {
                            Color.clear.frame(maxWidth: .infinity)

                            HStack(alignment: .center, spacing: 0) {
                                Spacer(minLength: 0)
                                // HH
                                hhmmSlot(
                                    countdown: DrumPickerView(value: $selectedHours, range: 0...9,
                                                              hapticEnabled: profile?.hapticEnabled ?? true),
                                    stopwatchText: "0",
                                    runningText: Text(hhText),
                                    width: 72
                                )

                                colon

                                // MM
                                hhmmSlot(
                                    countdown: DrumPickerView(value: $vm.selectedMinutes, range: 0...59,
                                                              hapticEnabled: profile?.hapticEnabled ?? true,
                                                              zeroPadded: true),
                                    stopwatchText: "00",
                                    runningText: Text(mmText),
                                    width: 100
                                )

                                colon

                                // SS — stopwatch: static 00; countdown: locked at 0
                                ssSlot(running: Text(ssText))
                                Spacer(minLength: 0)
                            }
                        }
                        .contentShape(Rectangle())
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

                // Action button — disabled while popup is showing to prevent accidental re-start
                actionButtonArea
                    .padding(.bottom, 24)
                    .allowsHitTesting(savedSession == nil)
            }
        }
        .onChange(of: vm.completedSession) { _, session in
            guard let session else { return }
            print("[TV] completedSession changed — duration=\(session.duration)")
            ctx.insert(session)
            try? ctx.save()
            let allSessions = (try? ctx.fetch(FetchDescriptor<RunSession>())) ?? []
            AppGroupDefaults.writeSessionSummaries(
                from: allSessions,
                dailyGoalMinutes: profile?.dailyGoalMinutes ?? 20
            )
            WidgetCenter.shared.reloadAllTimelines()
            print("[TV] setting savedSession — will show popup")
            withAnimation(.easeOut(duration: 0.25)) { savedSession = session }
            vm.completedSession = nil
        }
        .onAppear {
            bpm = profile?.defaultBPM ?? 180
            volume = UserDefaults.standard.object(forKey: "defaultVolume") as? Double ?? 0.6
            metronome.volume = Float(volume)
            let defMins = profile?.dailyGoalMinutes ?? 20
            vm.isCountdown = (profile?.timerMode ?? .countdown) == .countdown
            if timeDisplayFormat == .hhMM {
                selectedHours = defMins / 60
                vm.selectedMinutes = defMins % 60
            } else {
                selectedHours = 0
                vm.selectedMinutes = defMins
            }
            volume = 0.6
            metronome.soundType = profile?.soundType ?? .tap
            metronome.volume = Float(volume)
            Task {
                await HealthKitService.shared.requestPermissions()
                await MotionService.requestAuthorization()
            }
        }
        .onChange(of: vm.state) { oldState, newState in
            print("[TV] state changed \(oldState) → \(newState)")
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            switch newState {
            case .running:
                if oldState == .paused {
                    metronome.resume()
                } else {
                    metronome.start()
                    motionService.weightKg = profile?.weightKg ?? 65
                    motionService.heightCm = profile?.heightCm ?? 170
                    hrService.startMonitoring()
                    motionService.startTracking()
                }
            case .paused:
                metronome.pause()
            case .idle:
                metronome.stop()
                hrService.stopMonitoring()
                motionService.stopTracking()
                withAnimation(.easeOut(duration: 0.2)) { longPressProgress = 0 }
            }
        }
        .onChange(of: vm.countdownFinished) { _, finished in
            print("[TV] countdownFinished changed → \(finished)")
            guard finished else { return }
            print("[TV] calling stopAndSave from countdownFinished handler")
            vm.stopAndSave(
                bpm: bpm,
                characterId: profile?.activeCharacterId ?? "loader_cat",
                themeId: themeManager.current.id,
                distance: motionService.distance,
                calories: motionService.calories,
                steps: motionService.steps,
                avgHR: hrService.avgHR,
                maxHR: hrService.maxHR,
                avgCadence: motionService.avgCadence
            )
        }
        .onChange(of: isLongPressing) { _, pressing in
            if pressing { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        }
        .onChange(of: bpm) { _, newBPM in
            metronome.updateBPM(newBPM)
        }
        .onChange(of: vm.isCountdown) { _, countdown in
            if !countdown {
                // Stopwatch: reset to 0 so display shows 0:00 / 0:00:00
                vm.selectedMinutes = 0
                selectedHours = 0
            } else {
                // Restore default duration when switching back
                let defMins = profile?.dailyGoalMinutes ?? 20
                if timeDisplayFormat == .hhMM {
                    selectedHours = defMins / 60
                    vm.selectedMinutes = defMins % 60
                } else {
                    selectedHours = 0
                    vm.selectedMinutes = defMins
                }
            }
        }
        .sheet(isPresented: $showBPMPanel) {
            BPMPanelView(bpm: $bpm)
                .presentationBackground(theme.bg)
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showCharacterPicker) {
            CharacterPickerView(selectedId: Binding(
                get: { profile?.activeCharacterId ?? "loader_cat" },
                set: { v in
                    profile?.activeCharacterId = v
                    try? ctx.save()
                }
            ))
            .presentationBackground(theme.bg)
            .presentationDetents([.medium])
        }
    }

    // MARK: - Live metrics

    private var metricsBlock: some View {
        ZStack(alignment: .leading) {
            // Countdown/Stopwatch segment control — only visible when idle
            if vm.state == .idle {
                SegmentedPicker(
                    selection: Binding(
                        get: { vm.isCountdown ? 0 : 1 },
                        set: { vm.isCountdown = $0 == 0 }
                    ),
                    segments: [lm.L("timer.mode.countdown"), lm.L("timer.mode.stopwatch")],
                    selectedTint: theme.accent,
                    background: theme.surface,
                    selectedTextColor: theme.bg,
                    normalTextColor: theme.textMid
                )
                .fixedSize()
                .frame(maxWidth: .infinity, alignment: .center)
            }

            // Live metrics — shown when running or paused
            HStack(spacing: 28) {
                if vm.state == .running || vm.state == .paused {
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


    // MARK: - HH:MM slot helpers

    @ViewBuilder
    private func slot<I: View>(idle: I, running: Text, width: CGFloat = 100) -> some View {
        Group {
            if vm.state == .idle {
                idle
            } else {
                running
                    .font(.system(size: 108, weight: .ultraLight))
                    .foregroundColor(theme.text)
                    .monospacedDigit()
                    .kerning(-5)
                    .fixedSize()
            }
        }
        .frame(width: width)
    }

    private var colon: some View {
        Text(":")
            .font(.system(size: 108, weight: .ultraLight))
            .foregroundColor(theme.text)
            .padding(.bottom, 18)
            .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func hhmmSlot<I: View>(countdown: I, stopwatchText: String, runningText: Text, width: CGFloat) -> some View {
        Group {
            if vm.state == .idle {
                if vm.isCountdown {
                    countdown
                } else {
                    Text(stopwatchText)
                        .font(.system(size: 108, weight: .ultraLight))
                        .foregroundColor(theme.text)
                        .monospacedDigit()
                        .kerning(-5)
                        .fixedSize()
                }
            } else {
                runningText
                    .font(.system(size: 108, weight: .ultraLight))
                    .foregroundColor(theme.text)
                    .monospacedDigit()
                    .kerning(-5)
                    .fixedSize()
            }
        }
        .frame(width: width)
    }

    @ViewBuilder
    private func ssSlot(running: Text) -> some View {
        Group {
            if vm.state == .idle {
                if vm.isCountdown {
                    // Countdown: picker locked at 0 (range 0...0, no interaction)
                    DrumPickerView(value: $selectedSeconds, range: 0...0,
                                   hapticEnabled: false, zeroPadded: true)
                        .allowsHitTesting(false)
                } else {
                    // Stopwatch: pure static text, no gesture layer
                    Text("00")
                        .font(.system(size: 108, weight: .ultraLight))
                        .foregroundColor(theme.text)
                        .monospacedDigit()
                        .kerning(-5)
                        .fixedSize()
                }
            } else {
                running
                    .font(.system(size: 108, weight: .ultraLight))
                    .foregroundColor(theme.text)
                    .monospacedDigit()
                    .kerning(-5)
                    .fixedSize()
            }
        }
        .frame(width: 100)
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

    // MARK: - Stop helper

    private func doStop() {
        print("[TV] doStop called")
        isLongPressing = false
        isLongPressingPending = false
        didCompleteStop = true
        withAnimation(.easeOut(duration: 0.15)) { longPressProgress = 0 }
        hrService.stopMonitoring()
        motionService.stopTracking()
        vm.stopAndSave(
            bpm: bpm, characterId: profile?.activeCharacterId ?? "loader_cat", themeId: themeManager.current.id,
            distance: motionService.distance,
            calories: motionService.calories,
            steps: motionService.steps,
            avgHR: hrService.avgHR,
            maxHR: hrService.maxHR,
            avgCadence: motionService.avgCadence
        )
    }

    // MARK: - Action button

    private var actionButtonArea: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(theme.surface, lineWidth: 2)
                    .frame(width: 128, height: 128)

                if vm.state != .idle {
                    Circle()
                        .trim(from: 0, to: longPressProgress)
                        .stroke(theme.accentMid,
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                }

                // play (idle) / pause (running) / play (paused) / stop (long-pressing)
                Image(systemName: vm.state == .idle
                      ? "play.fill"
                      : isLongPressing
                        ? "stop.fill"
                        : vm.state == .running ? "pause.fill" : "play.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(theme.accentMid)
                    .animation(.none, value: isLongPressing)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard vm.state != .idle, !isLongPressingPending else { return }
                        isLongPressingPending = true
                        // After 0.2s: show stop icon + start arc
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            guard self.isLongPressingPending else { return }
                            self.isLongPressing = true
                            withAnimation(.linear(duration: 0.8)) { self.longPressProgress = 1.0 }
                            // Schedule stop after arc completes
                            let work = DispatchWorkItem { self.doStop() }
                            self.stopWorkItem = work
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: work)
                        }
                    }
                    .onEnded { _ in
                        isLongPressingPending = false
                        if didCompleteStop {
                            didCompleteStop = false
                            return
                        }
                        if isLongPressing {
                            // Hand lifted before arc finished — cancel
                            stopWorkItem?.cancel()
                            stopWorkItem = nil
                            isLongPressing = false
                            withAnimation(.easeOut(duration: 0.15)) { longPressProgress = 0 }
                        } else {
                            // Quick tap
                            switch vm.state {
                            case .idle:
                                guard savedSession == nil, !didCompleteStop else { return }
                                vm.targetDuration = timeDisplayFormat == .hhMM
                                    ? Double(selectedHours * 3600 + vm.selectedMinutes * 60)
                                    : Double(vm.selectedMinutes) * 60
                                vm.start(bpm: bpm, characterId: profile?.activeCharacterId ?? "loader_cat", themeId: themeManager.current.id)
                            case .running:
                                vm.pause()
                            case .paused:
                                vm.resume()
                            }
                        }
                    }
            )

            Text(vm.state == .idle ? " " : lm.L("timer.tip.longPress"))
                .font(.system(size: 11))
                .foregroundColor(theme.textDim)
        }
        .frame(height: 169)
    }
}

// MARK: - HH:MM slot helpers (only used by TimerView HH:MM mode)

private struct HHMMSlot<Idle: View, Running: View>: View {
    let isIdle: Bool
    let idle: Idle
    let running: Running

    var body: some View {
        Group {
            if isIdle { idle } else { running
                    .font(.system(size: 108, weight: .ultraLight))
                    .monospacedDigit()
                    .kerning(-5)
                    .fixedSize()
            }
        }
        .frame(width: 100)
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

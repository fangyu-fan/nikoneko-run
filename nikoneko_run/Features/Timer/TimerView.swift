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
    @State private var hasCompletedInitialLayout = false
    @Environment(\.modelContext) private var ctx

    private var theme: ThemeTokens { themeManager.current }
    private struct Layout {
        let isCompactHeight: Bool
        let isNarrow: Bool
        let contentMaxWidth: CGFloat
        let characterTopPadding: CGFloat
        let numeralHeight: CGFloat
        let pickerRowHeight: CGFloat
        let timeFontSize: CGFloat
        let ghostFontSize: CGFloat
        let secondaryTimeOffset: CGFloat
        let hhmmSlotWidth: CGFloat
        let colonPadding: CGFloat
        let middleSpacing: CGFloat
        let metricsBottomPadding: CGFloat
        let controlsBottomPadding: CGFloat
        let actionBottomPadding: CGFloat

        init(size: CGSize) {
            isCompactHeight = size.height < 780
            isNarrow = size.width < 430
            contentMaxWidth = min(size.width, 600)
            characterTopPadding = min(max(size.height * 0.15, 72), 116)
            numeralHeight = isCompactHeight ? 236 : 360
            pickerRowHeight = isCompactHeight ? 72 : 90
            timeFontSize = isCompactHeight ? 92 : 108
            ghostFontSize = isCompactHeight ? 40 : 48
            secondaryTimeOffset = isCompactHeight ? 72 : 90
            hhmmSlotWidth = isNarrow ? 82 : 100
            colonPadding = isNarrow ? 2 : 8
            middleSpacing = isCompactHeight ? 4 : 32
            metricsBottomPadding = isCompactHeight ? 12 : 20
            controlsBottomPadding = isCompactHeight ? 12 : 24
            actionBottomPadding = isCompactHeight ? 8 : 24
        }
    }

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

    var body: some View {
        GeometryReader { geometry in
            let layout = Layout(size: geometry.size)

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
                .frame(maxWidth: 340, maxHeight: min(430, geometry.size.height - 40))
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
                    secondaryColor: theme.accent,
                    tertiaryColor: theme.accentDim,
                    shadowColor: theme.bg,
                    bpm: bpm,
                    isAnimating: vm.state == .running
                )
                .frame(width: 72, height: 52)
                .frame(maxWidth: .infinity)
                .padding(.top, layout.characterTopPadding)
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
                                          hapticEnabled: profile?.hapticEnabled ?? true,
                                          centerFontSize: layout.timeFontSize,
                                          ghostFontSize: layout.ghostFontSize,
                                          rowHeight: layout.pickerRowHeight,
                                          stepDistance: layout.isCompactHeight ? 28 : 32)
                                .opacity(vm.state == .idle ? 1 : 0)
                                .allowsHitTesting(vm.state == .idle)
                        } else {
                            // Stopwatch: static 0 — no picker
                            Text("0")
                                .font(.system(size: layout.timeFontSize, weight: .ultraLight))
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
                                .font(.system(size: layout.timeFontSize, weight: .ultraLight))
                                .foregroundColor(theme.text)
                                .monospacedDigit()
                                .kerning(-5)
                                .fixedSize()

                            if vm.state != .idle {
                                Text(secondaryTimeText)
                                    .font(.system(size: layout.ghostFontSize, weight: .thin))
                                    .foregroundColor(theme.text)
                                    .monospacedDigit()
                                    .fixedSize()
                                    .offset(y: layout.secondaryTimeOffset)
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
                                                              hapticEnabled: profile?.hapticEnabled ?? true,
                                                              centerFontSize: layout.isNarrow ? 72 : layout.timeFontSize,
                                                              ghostFontSize: layout.isNarrow ? 34 : layout.ghostFontSize,
                                                              rowHeight: layout.pickerRowHeight,
                                                              stepDistance: layout.isCompactHeight ? 28 : 32),
                                    stopwatchText: "0",
                                    runningText: Text(hhText),
                                    width: layout.hhmmSlotWidth,
                                    fontSize: layout.isNarrow ? 72 : layout.timeFontSize
                                )

                                colon(fontSize: layout.isNarrow ? 72 : layout.timeFontSize,
                                      horizontalPadding: layout.colonPadding)

                                // MM
                                hhmmSlot(
                                    countdown: DrumPickerView(value: $vm.selectedMinutes, range: 0...59,
                                                              hapticEnabled: profile?.hapticEnabled ?? true,
                                                              zeroPadded: true,
                                                              centerFontSize: layout.isNarrow ? 72 : layout.timeFontSize,
                                                              ghostFontSize: layout.isNarrow ? 34 : layout.ghostFontSize,
                                                              rowHeight: layout.pickerRowHeight,
                                                              stepDistance: layout.isCompactHeight ? 28 : 32),
                                    stopwatchText: "00",
                                    runningText: Text(mmText),
                                    width: layout.hhmmSlotWidth,
                                    fontSize: layout.isNarrow ? 72 : layout.timeFontSize
                                )

                                colon(fontSize: layout.isNarrow ? 72 : layout.timeFontSize,
                                      horizontalPadding: layout.colonPadding)

                                // SS — stopwatch: static 00; countdown: locked at 0
                                ssSlot(running: Text(ssText),
                                       width: layout.hhmmSlotWidth,
                                       fontSize: layout.isNarrow ? 72 : layout.timeFontSize,
                                       layout: layout)
                                Spacer(minLength: 0)
                            }
                        }
                        .contentShape(Rectangle())
                        .allowsHitTesting(true)
                    }
                }
                .frame(height: layout.numeralHeight)

                Spacer(minLength: layout.middleSpacing)

                // Live metrics — fixed height so it never shifts
                metricsBlock
                    .frame(height: 28)
                    .padding(.bottom, layout.metricsBottomPadding)

                // BPM + volume ctrl row
                ctrlRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, layout.controlsBottomPadding)

                // Action button — disabled while popup is showing to prevent accidental re-start
                actionButtonArea(compact: layout.isCompactHeight)
                    .padding(.bottom, layout.actionBottomPadding)
                    .allowsHitTesting(savedSession == nil)
                }
                .frame(maxWidth: layout.contentMaxWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .transaction { transaction in
            if !hasCompletedInitialLayout {
                transaction.disablesAnimations = true
            }
        }
        .onChange(of: vm.completedSession) { _, session in
            guard let session else { return }
            ctx.insert(session)
            do {
                try ctx.save()
            } catch {
                print("⚠️ [TV] ctx.save() failed: \(error)")
            }
            let allSessions = (try? ctx.fetch(FetchDescriptor<RunSession>())) ?? []
            AppGroupDefaults.writeSessionSummaries(
                from: allSessions,
                dailyGoalMinutes: profile?.dailyGoalMinutes ?? 20
            )
            WidgetCenter.shared.reloadAllTimelines()
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
            DispatchQueue.main.async {
                hasCompletedInitialLayout = true
            }
            metronome.soundType = profile?.soundType ?? .tap
        }
        .onChange(of: vm.state) { oldState, newState in
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
            guard finished else { return }
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
                    if (profile?.showHR ?? true), hrService.currentHR > 0 {
                        metricItem(icon: "heart",
                                   value: "\(hrService.currentHR)",
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

    private func colon(fontSize: CGFloat, horizontalPadding: CGFloat) -> some View {
        Text(":")
            .font(.system(size: fontSize, weight: .ultraLight))
            .foregroundColor(theme.text)
            .padding(.bottom, fontSize * 0.167)
            .padding(.horizontal, horizontalPadding)
    }

    @ViewBuilder
    private func hhmmSlot<I: View>(countdown: I, stopwatchText: String, runningText: Text, width: CGFloat, fontSize: CGFloat) -> some View {
        Group {
            if vm.state == .idle {
                if vm.isCountdown {
                    countdown
                } else {
                    Text(stopwatchText)
                        .font(.system(size: fontSize, weight: .ultraLight))
                        .foregroundColor(theme.text)
                        .monospacedDigit()
                        .kerning(-5)
                        .fixedSize()
                }
            } else {
                runningText
                    .font(.system(size: fontSize, weight: .ultraLight))
                    .foregroundColor(theme.text)
                    .monospacedDigit()
                    .kerning(-5)
                    .fixedSize()
            }
        }
        .frame(width: width)
    }

    @ViewBuilder
    private func ssSlot(running: Text, width: CGFloat, fontSize: CGFloat, layout: Layout) -> some View {
        Group {
            if vm.state == .idle {
                if vm.isCountdown {
                    // Countdown: picker locked at 0 (range 0...0, no interaction)
                    DrumPickerView(value: $selectedSeconds, range: 0...0,
                                   hapticEnabled: false, zeroPadded: true,
                                   centerFontSize: fontSize,
                                   ghostFontSize: layout.isNarrow ? 34 : layout.ghostFontSize,
                                   rowHeight: layout.pickerRowHeight,
                                   stepDistance: layout.isCompactHeight ? 28 : 32)
                        .allowsHitTesting(false)
                } else {
                    // Stopwatch: pure static text, no gesture layer
                    Text("00")
                        .font(.system(size: fontSize, weight: .ultraLight))
                        .foregroundColor(theme.text)
                        .monospacedDigit()
                        .kerning(-5)
                        .fixedSize()
                }
            } else {
                running
                    .font(.system(size: fontSize, weight: .ultraLight))
                    .foregroundColor(theme.text)
                    .monospacedDigit()
                    .kerning(-5)
                    .fixedSize()
            }
        }
        .frame(width: width)
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

    private func actionButtonArea(compact: Bool) -> some View {
        let buttonSize: CGFloat = compact ? 108 : 128
        let progressSize: CGFloat = compact ? 120 : 140
        return VStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(theme.surface, lineWidth: 2)
                    .frame(width: buttonSize, height: buttonSize)

                if vm.state != .idle {
                    Circle()
                        .trim(from: 0, to: longPressProgress)
                        .stroke(theme.accentMid,
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .frame(width: progressSize, height: progressSize)
                        .rotationEffect(.degrees(-90))
                }

                // play (idle) / pause (running) / play (paused) / stop (long-pressing)
                Image(systemName: vm.state == .idle
                      ? "play.fill"
                      : isLongPressing
                        ? "stop.fill"
                        : vm.state == .running ? "pause.fill" : "play.fill")
                    .font(.system(size: compact ? 28 : 32, weight: .medium))
                    .foregroundColor(theme.accentMid)
                    .animation(.none, value: isLongPressing)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard vm.state != .idle, !isLongPressingPending else { return }
                        isLongPressingPending = true
                        // After 0.2s show the stop state, then finish at 1.0s total.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            MainActor.assumeIsolated {
                                guard self.isLongPressingPending else { return }
                                self.isLongPressing = true
                                withAnimation(.linear(duration: 0.8)) { self.longPressProgress = 1.0 }
                                let work = DispatchWorkItem {
                                    MainActor.assumeIsolated { self.doStop() }
                                }
                                self.stopWorkItem = work
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: work)
                            }
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
        .frame(height: compact ? 145 : 169)
    }
}

#if DEBUG
#Preview {
    TimerView(vm: TimerViewModel())
        .environment(ThemeManager())
        .environment(LanguageManager())
}
#endif

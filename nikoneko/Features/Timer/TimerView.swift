import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }
    @State private var vm = TimerViewModel()
    @State private var longPressProgress: CGFloat = 0
    @State private var showBPMPanel = false
    @State private var bpm: Int = 180
    @State private var volume: Double = 0.6

    private var theme: ThemeTokens { themeManager.current }
    private let numeralHeight: CGFloat = 360

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
                .padding(.top, 88)

                Spacer(minLength: 0)

                // Numeral zone — idle and running share the same ZStack.
                // DrumPickerView center slot uses .fixedSize() so its 108pt numeral renders
                // at true size (overflowing rowHeight), matching the running numeral's layout.
                // Both therefore have the same visual center = ZStack geometric center.
                ZStack(alignment: .center) {
                    DrumPickerView(value: $vm.selectedMinutes, range: 1...999)
                        .opacity(vm.state == .idle ? 1 : 0)
                        .allowsHitTesting(vm.state == .idle)

                    Text("\(vm.displayMinutes)")
                        .font(.system(size: 108, weight: .ultraLight))
                        .foregroundColor(theme.text)
                        .monospacedDigit()
                        .kerning(-5)
                        .fixedSize()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .overlay(alignment: .bottom) {
                            Text(vm.isCountdown
                                 ? ": \(String(format: "%02d", vm.displaySeconds))"
                                 : " ")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundColor(theme.text)
                                .fixedSize()
                                .offset(y: 40)
                        }
                        .opacity(vm.state != .idle ? 1 : 0)
                        .allowsHitTesting(vm.state != .idle)
                        .onTapGesture(count: 2) {
                            vm.state == .running ? vm.pause() : vm.resume()
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
        .onChange(of: vm.state) { _, newState in
            if newState == .idle {
                withAnimation(.easeOut(duration: 0.2)) { longPressProgress = 0 }
            }
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
                if profile?.showHR ?? true      { metricItem(icon: "heart", value: "—", unit: nil) }
                if profile?.showDistance ?? true { metricItem(icon: "location.circle", value: "—", unit: "km") }
                if profile?.showCalories ?? true { metricItem(icon: "flame", value: "—", unit: nil) }
                if profile?.showSteps ?? true    { metricItem(icon: "figure.walk", value: "—", unit: nil) }
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
                    Text("bpm")
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
        GeometryReader { geo in
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
                    }
            )
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
                vm.targetDuration = Double(vm.selectedMinutes) * 60
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
                vm.stopAndSave(
                    bpm: bpm, characterId: "loader_cat", themeId: themeManager.current.id,
                    distance: 0, calories: 0, steps: 0,
                    avgHR: 0, maxHR: 0, avgCadence: 0
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
    TimerView()
        .environment(ThemeManager())
}
#endif

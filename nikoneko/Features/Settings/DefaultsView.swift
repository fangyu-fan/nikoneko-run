import SwiftUI
import SwiftData
import WidgetKit

struct DefaultsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var lm
    @Query private var profiles: [UserProfile]
    @Query private var configs: [ThresholdConfig]
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    private var theme: ThemeTokens { themeManager.current }
    private var profile: UserProfile? { profiles.first }
    private var config: ThresholdConfig? { configs.first }

    // Local drag state — committed to SwiftData on drag end
    @State private var t1: Double = 25
    @State private var t2: Double = 60
    @State private var t3: Double = 90
    @State private var volume: Double = 0.7
    @State private var weekStartsOnMonday: Bool = AppGroupDefaults.weekStartsOnMonday

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionLabel(lm.L("defaults.section.time"))
                VStack(spacing: 0) {
                    stepperRow(icon: "flag", name: lm.L("defaults.row.dailyGoal"),
                               value: profile?.dailyGoalMinutes ?? 15,
                               step: 5, range: 5...999) { v in
                        profile?.dailyGoalMinutes = v
                        profile?.defaultDuration = v
                        try? ctx.save()
                    }
                    Rectangle().fill(theme.accentDim).frame(height: 0.5)
                    thresholdSlider
                }
                .background(theme.surface)
                .cornerRadius(14)
                .padding(.bottom, 4)

                sectionLabel(lm.L("defaults.section.calendar"))
                VStack(spacing: 0) {
                    weekStartRow
                }
                .background(theme.surface)
                .cornerRadius(14)
                .padding(.bottom, 4)

                sectionLabel(lm.L("defaults.section.beat"))
                VStack(spacing: 0) {
                    stepperRow(icon: "metronome", name: lm.L("defaults.row.bpm"),
                               value: profile?.defaultBPM ?? 180,
                               step: 1, range: 140...220,
                               isBPM: true) { v in
                        profile?.defaultBPM = v; try? ctx.save()
                    }
                    Rectangle().fill(theme.accentDim).frame(height: 0.5)
                    soundRow
                    Rectangle().fill(theme.accentDim).frame(height: 0.5)
                    volumeRow
                }
                .background(theme.surface)
                .cornerRadius(14)
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .background(theme.bg.ignoresSafeArea())
        .id(lm.version)
        .navigationTitle(lm.L("defaults.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            ensureConfig()
            t1 = Double(config?.threshold1 ?? 25)
            t2 = Double(config?.threshold2 ?? 60)
            t3 = Double(config?.threshold3 ?? 90)
            volume = UserDefaults.standard.object(forKey: "defaultVolume") as? Double ?? 0.7
        }
        .onChange(of: config?.threshold1) { _, v in if let v { t1 = Double(v) } }
        .onChange(of: config?.threshold2) { _, v in if let v { t2 = Double(v) } }
        .onChange(of: config?.threshold3) { _, v in if let v { t3 = Double(v) } }
    }

    // MARK: - Threshold Slider

    private var thresholdSlider: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16))
                    .foregroundColor(theme.text)
                    .frame(width: 20)
                Text("Goal Thresholds")
                    .font(.system(size: 16))
                    .foregroundColor(theme.text)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            GeometryReader { geo in
                let w = geo.size.width
                let minGap: Double = 5
                let barH: CGFloat = 10
                let handleR: CGFloat = 14

                ZStack(alignment: .leading) {
                    // Segmented gradient bar
                    HStack(spacing: 0) {
                        // 0 → t1 : cal[0]
                        theme.cal[0].frame(width: w * t1 / 100)
                        // t1 → t2 : cal[2]
                        theme.cal[2].frame(width: w * (t2 - t1) / 100)
                        // t2 → t3 : cal[3]
                        theme.cal[3].frame(width: w * (t3 - t2) / 100)
                        // t3 → 100 : cal[4]
                        theme.cal[4].frame(maxWidth: .infinity)
                    }
                    .frame(height: barH)
                    .cornerRadius(barH / 2)

                    // Handle T1
                    handle(color: theme.cal[1])
                        .position(x: w * t1 / 100, y: barH / 2)
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                let pct = (v.location.x / w * 100).clamped(to: 1...(t2 - minGap))
                                t1 = pct
                            }
                            .onEnded { _ in
                                config?.threshold1 = Int(t1.rounded())
                                try? ctx.save()
                            })

                    // Handle T2
                    handle(color: theme.cal[2])
                        .position(x: w * t2 / 100, y: barH / 2)
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                let pct = (v.location.x / w * 100).clamped(to: (t1 + minGap)...(t3 - minGap))
                                t2 = pct
                            }
                            .onEnded { _ in
                                config?.threshold2 = Int(t2.rounded())
                                try? ctx.save()
                            })

                    // Handle T3
                    handle(color: theme.cal[3])
                        .position(x: w * t3 / 100, y: barH / 2)
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                let pct = (v.location.x / w * 100).clamped(to: (t2 + minGap)...99)
                                t3 = pct
                            }
                            .onEnded { _ in
                                config?.threshold3 = Int(t3.rounded())
                                try? ctx.save()
                            })
                }
                .frame(height: handleR * 2)
            }
            .frame(height: 28)
            .padding(.horizontal, 16)

            // Labels row
            HStack(spacing: 0) {
                Text("0%")
                    .frame(width: 0, alignment: .leading)
                Spacer()
                    .frame(width: CGFloat(t1) / 100 * 1) // placeholder — real spacing via HStack
                Text("\(Int(t1.rounded()))%")
                    .foregroundColor(theme.textMid)
                Spacer()
                Text("\(Int(t2.rounded()))%")
                    .foregroundColor(theme.textMid)
                Spacer()
                Text("\(Int(t3.rounded()))%")
                    .foregroundColor(theme.textMid)
                Spacer()
                Text("100%")
            }
            .font(.system(size: 10))
            .foregroundColor(theme.textDim)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
    }

    private func handle(color: Color) -> some View {
        ZStack {
            Circle()
                .fill(theme.surface)
                .frame(width: 22, height: 22)
                .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
        }
    }

    // MARK: - Section helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10))
            .tracking(1)
            .foregroundColor(theme.textDim)
            .padding(.top, 10)
            .padding(.bottom, 5)
            .padding(.horizontal, 2)
    }

    private func stepperRow(icon: String, name: String, value: Int,
                             step: Int, range: ClosedRange<Int>,
                             isBPM: Bool = false,
                             onChange: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(theme.text)
                .frame(width: 20)
            Text(name)
                .font(.system(size: 16))
                .foregroundColor(theme.text)
            Spacer()
            HStack(spacing: 8) {
                stepButton("−") { onChange(max(range.lowerBound, value - step)) }
                Text("\(value)")
                    .font(.system(size: 16, weight: .ultraLight))
                    .foregroundColor(theme.text)
                    .monospacedDigit()
                    .frame(minWidth: isBPM ? 40 : 52, alignment: .center)
                stepButton("+") { onChange(min(range.upperBound, value + step)) }
            }
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
    }

    private func stepButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(theme.text)
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(Circle().stroke(theme.accentDim, lineWidth: 0.5).frame(width: 26, height: 26))
    }

    private func ensureConfig() {
        guard configs.isEmpty else { return }
        let c = ThresholdConfig(widgetKind: "defaults")
        c.threshold1 = 25
        c.threshold2 = 60
        c.threshold3 = 90
        ctx.insert(c)
        try? ctx.save()
    }

    // MARK: - Calendar rows

    private var weekStartRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 16))
                .foregroundColor(theme.text)
                .frame(width: 20)
            Text(lm.L("defaults.row.weekStart"))
                .font(.system(size: 16))
                .foregroundColor(theme.text)
            Spacer()
            HStack(spacing: 2) {
                ForEach([true, false], id: \.self) { isMon in
                    Button {
                        weekStartsOnMonday = isMon
                        AppGroupDefaults.weekStartsOnMonday = isMon
                        WidgetCenter.shared.reloadAllTimelines()
                    } label: {
                        Text(isMon ? lm.L("defaults.weekStart.monday") : lm.L("defaults.weekStart.sunday"))
                            .font(.system(size: 13))
                            .foregroundColor(weekStartsOnMonday == isMon ? theme.text : theme.textMid)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(weekStartsOnMonday == isMon ? theme.card : Color.clear)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(theme.surface)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.accentDim, lineWidth: 0.5))
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
    }

    // MARK: - Beat rows

    private var soundRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "music.note")
                .font(.system(size: 16))
                .foregroundColor(theme.text)
                .frame(width: 20)
            Text(lm.L("defaults.row.sound"))
                .font(.system(size: 16))
                .foregroundColor(theme.text)
            Spacer()
            soundPicker
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
    }

    private var lockVolumeRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.open")
                .font(.system(size: 16))
                .foregroundColor(theme.text)
                .frame(width: 20)
            Text(lm.L("defaults.row.lockVolume"))
                .font(.system(size: 16))
                .foregroundColor(theme.text)
            Spacer()
            Toggle("", isOn: bindBool(\.volumeLockEnabled))
                .tint(theme.accent)
                .labelsHidden()
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
    }

    private var soundPicker: some View {
        let options: [(SoundType, String)] = [
            (.tap,  lm.L("defaults.sound.tap")),
            (.bell, lm.L("defaults.sound.bell")),
            (.drum, lm.L("defaults.sound.drum")),
            (.wood, lm.L("defaults.sound.wood")),
        ]
        let current = profile?.soundType ?? .tap
        return HStack(spacing: 2) {
            ForEach(options, id: \.0) { (type, label) in
                Button(action: { profile?.soundType = type; try? ctx.save() }) {
                    Text(label)
                        .font(.system(size: 13))
                        .foregroundColor(current == type ? theme.text : theme.textMid)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(current == type ? theme.card : Color.clear)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(theme.surface)
        .cornerRadius(10)
    }

    private var hapticRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform")
                .font(.system(size: 16))
                .foregroundColor(theme.text)
                .frame(width: 20)
            Text(lm.L("defaults.row.haptic"))
                .font(.system(size: 16))
                .foregroundColor(theme.text)
            Spacer()
            Toggle("", isOn: bindBool(\.hapticEnabled))
                .tint(theme.accent)
                .labelsHidden()
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
    }

    private var volumeRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.wave.2")
                .font(.system(size: 16))
                .foregroundColor(theme.text)
                .frame(width: 20)
            Text(lm.L("defaults.row.volume"))
                .font(.system(size: 16))
                .foregroundColor(theme.text)
            Spacer()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(theme.accentDim).frame(height: 3)
                    Capsule().fill(theme.textMid).frame(width: geo.size.width * volume, height: 3)
                    Circle().fill(theme.text).frame(width: 14, height: 14)
                        .offset(x: geo.size.width * volume - 7)
                }
                .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                    volume = min(1, max(0, v.location.x / geo.size.width))
                    UserDefaults.standard.set(volume, forKey: "defaultVolume")
                })
            }
            .frame(width: 100, height: 14)
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
    }

    private func bindBool(_ kp: ReferenceWritableKeyPath<UserProfile, Bool>) -> Binding<Bool> {
        Binding(
            get: { profile?[keyPath: kp] ?? false },
            set: { v in
                guard let p = profile else { return }
                p[keyPath: kp] = v
                try? ctx.save()
            }
        )
    }
}

// MARK: - Clamped helper

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(range.upperBound, max(range.lowerBound, self))
    }
}

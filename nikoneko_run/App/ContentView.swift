import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.modelContext) private var ctx
    @Query private var profiles: [UserProfile]
    @Query(sort: \RunSession.startDate, order: .reverse) private var sessions: [RunSession]
    @Query private var thresholdConfigs: [ThresholdConfig]
    @State private var timerVM = TimerViewModel()
    @State private var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    private var theme: ThemeTokens { themeManager.current }
    private var reportSettings: ThresholdConfig? {
        ThresholdConfig.goalSettings(in: thresholdConfigs)
    }

    var body: some View {
        if showOnboarding {
            OnboardingView {
                showOnboarding = false
            }
            .environment(themeManager)
            .environment(languageManager)
        } else {
            mainView
        }
    }

    private var mainView: some View {
        NavigationStack {
            ZStack {
                theme.bg.ignoresSafeArea()
                TimerView(vm: timerVM)
                if timerVM.state == .idle {
                    VStack {
                        HStack {
                            NavigationLink {
                                ReportView()
                            } label: {
                                Image(systemName: "chart.bar")
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundColor(theme.text)
                                    .frame(width: 44, height: 44)
                            }
                            Spacer()
                            NavigationLink {
                                SettingsView()
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundColor(theme.text)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .frame(maxWidth: 700)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)
                        .padding(.top, 56)
                        Spacer()
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: timerVM.state == .idle)
            .navigationBarHidden(true)
        }
        .onAppear {
            ensureProfile()
        }
        .task {
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            syncWidgetData()
        }
        .onChange(of: sessions) { _, _ in
            syncWidgetData()
        }
        .onChange(of: profiles.first?.dailyGoalMinutes) { _, _ in
            syncWidgetData()
        }
        .onChange(of: reportSettings?.threshold1) { _, _ in syncWidgetData() }
        .onChange(of: reportSettings?.threshold2) { _, _ in syncWidgetData() }
        .onChange(of: reportSettings?.threshold3) { _, _ in syncWidgetData() }
    }

    private func ensureProfile() {
        guard profiles.isEmpty else {
            if let p = profiles.first {
                languageManager.apply(p.language)
                var dirty = false
                if LottieCharacterView.fileNameMap[p.activeCharacterId] == nil {
                    p.activeCharacterId = "loader_cat"
                    dirty = true
                }
                if !UserDefaults.standard.bool(forKey: "metricsMigrationDone") {
                    if !p.showHR      { p.showHR = true;      dirty = true }
                    if !p.showDistance { p.showDistance = true; dirty = true }
                    if !p.showCalories { p.showCalories = true; dirty = true }
                    if !p.showSteps   { p.showSteps = true;    dirty = true }
                    UserDefaults.standard.set(true, forKey: "metricsMigrationDone")
                }
                if dirty { try? ctx.save() }
            }
            return
        }
        let profile = UserProfile()
        ctx.insert(profile)
        try? ctx.save()
    }

    private func syncWidgetData() {
        let settings = reportSettings
        AppGroupDefaults.writeReportSettings(
            dailyGoalMinutes: profiles.first?.dailyGoalMinutes ?? 20,
            threshold1: settings?.threshold1 ?? 25,
            threshold2: settings?.threshold2 ?? 60,
            threshold3: settings?.threshold3 ?? 90
        )
        AppGroupDefaults.writeSessionSummaries(
            from: sessions,
            dailyGoalMinutes: profiles.first?.dailyGoalMinutes ?? 20
        )
        WidgetCenter.shared.reloadAllTimelines()
    }
}

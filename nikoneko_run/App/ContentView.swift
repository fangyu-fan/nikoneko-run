import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.modelContext) private var ctx
    @Query private var profiles: [UserProfile]
    @State private var timerVM = TimerViewModel()
    @State private var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    private var theme: ThemeTokens { themeManager.current }

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
        .onAppear { ensureProfile() }
    }

    private func ensureProfile() {
        guard profiles.isEmpty else {
            if let p = profiles.first {
                languageManager.apply(p.language)
                // Migration: if metrics were incorrectly hidden, restore them.
                // showHR/showDistance/showCalories/showSteps default to true in UserProfile.
                // Onboarding used to set them false when health status was pending — fix that here.
                var dirty = false
                if !p.showHR      { p.showHR = true;      dirty = true }
                if !p.showDistance { p.showDistance = true; dirty = true }
                if !p.showCalories { p.showCalories = true; dirty = true }
                if !p.showSteps   { p.showSteps = true;    dirty = true }
                if dirty { try? ctx.save() }
            }
            return
        }
        let profile = UserProfile()
        ctx.insert(profile)
        try? ctx.save()
    }
}

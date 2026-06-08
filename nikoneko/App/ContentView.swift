import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.modelContext) private var ctx
    @Query private var profiles: [UserProfile]
    @State private var timerVM = TimerViewModel()
    @State private var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var onboardingVM = OnboardingViewModel()
    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(vm: onboardingVM) {
                    showOnboarding = false
                }
            } else {
                NavigationStack {
                    ZStack {
                        theme.bg.ignoresSafeArea()

                        TimerView(vm: timerVM)

                        // Top-left: Report, Top-right: Settings — hidden while running
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
            }
        }
        .onAppear { ensureProfile() }
    }

    private func ensureProfile() {
        guard !showOnboarding else { return }
        if profiles.isEmpty {
            let p = UserProfile()
            ctx.insert(p)
            try? ctx.save()
        } else {
            if let lang = profiles.first?.language {
                languageManager.apply(lang)
            }
        }
    }
}

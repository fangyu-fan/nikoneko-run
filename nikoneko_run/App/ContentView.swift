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
        .onAppear { ensureProfile() }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                showOnboarding = false
            }
            .environment(themeManager)
            .environment(languageManager)
        }
    }

    private func ensureProfile() {
        guard profiles.isEmpty else {
            // Restore saved language into LanguageManager on each launch
            if let lang = profiles.first?.language {
                languageManager.apply(lang)
            }
            return
        }
        let profile = UserProfile()
        ctx.insert(profile)
        try? ctx.save()
    }
}

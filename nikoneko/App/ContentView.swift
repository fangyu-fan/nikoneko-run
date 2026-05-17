import SwiftUI

struct ContentView: View {
    @Environment(ThemeManager.self) private var themeManager
    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.bg.ignoresSafeArea()

                TimerView()

                // Top-left: Report, Top-right: Settings
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
                    .padding(.top, 8)
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

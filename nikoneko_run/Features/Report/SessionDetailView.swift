import SwiftUI

struct SessionDetailView: View {
    let session: RunSession
    @Environment(ThemeManager.self) private var themeManager
    private var theme: ThemeTokens { themeManager.current }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(session.duration / 60))")
                        .font(.system(size: 46, weight: .ultraLight)).foregroundColor(theme.text)
                    Text("min · \(session.startDate, format: .dateTime.month().day().year())")
                        .font(.system(size: 10)).foregroundColor(theme.textDim)
                }
                .padding(.horizontal, 16)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    metricCell("Distance",   value: String(format: "%.2f km", session.distance / 1000))
                    metricCell("Calories",   value: "\(Int(session.calories)) kcal")
                    metricCell("Steps",      value: "\(session.steps)")
                    metricCell("Avg HR",     value: session.avgHR > 0 ? "\(session.avgHR) bpm" : "—")
                    metricCell("Max HR",     value: session.maxHR > 0 ? "\(session.maxHR) bpm" : "—")
                    metricCell("Cadence",    value: session.avgCadence > 0 ? "\(session.avgCadence) spm" : "—")
                    metricCell("BPM",        value: "\(session.bpm)")
                    metricCell("Mode",       value: session.mode.rawValue.capitalized)
                }
                .padding(.horizontal, 12)
            }
            .padding(.top, 12)
        }
        .background(theme.bg)
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func metricCell(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 7)).foregroundColor(theme.textDim)
            Text(value).font(.system(size: 16, weight: .ultraLight)).foregroundColor(theme.textMid)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(theme.card)
        .cornerRadius(9)
    }
}

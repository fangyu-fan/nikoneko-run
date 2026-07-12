import SwiftUI

struct ShareCardView: View {
    let session: RunSession
    let theme: ThemeTokens

    var body: some View {
        VStack(spacing: 12) {
            Text("NIKONEKO RUN")
                .font(.system(size: 11, weight: .medium))
                .tracking(3)
                .foregroundColor(theme.textDim)

            Text("\(Int(session.duration / 60))")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundColor(theme.text)
                .monospacedDigit()

            Text("min · \(session.startDate, format: .dateTime.month().day().locale(Locale(identifier: LanguageBundle.languageCode)))")
                .font(.system(size: 10))
                .foregroundColor(theme.textDim)
        }
        .frame(width: 300, height: 200)
        .background(theme.bg)
    }

    @MainActor
    static func render(session: RunSession, theme: ThemeTokens) -> UIImage? {
        let view = ShareCardView(session: session, theme: theme)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        return renderer.uiImage
    }
}

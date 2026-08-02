import SwiftUI

struct PlaceholderCharacterView: View {
    let characterId: String
    let color: Color
    let bpm: Int
    let isAnimating: Bool

    @State private var frame: Int = 0
    @State private var animTimer: Timer?

    // 1 loop = 2 steps = 2 beats
    // loopsPerSecond = bpm / 60 / 2
    private var loopsPerSecond: Double { Double(bpm) / 120.0 }

    // 4-frame loop → each frame lasts 1 / (loopsPerSecond * 4)
    private var frameInterval: TimeInterval { max(0.05, 1.0 / (loopsPerSecond * 4)) }

    var body: some View {
        Canvas { context, size in
            drawCatFrame(frame, in: context, size: size, color: color)
        }
        .onAppear {
            if isAnimating { startAnimation() }
        }
        .onDisappear { animTimer?.invalidate() }
        .onChange(of: isAnimating) { _, animating in
            animating ? startAnimation() : stopAnimation()
        }
        .onChange(of: bpm) { _, _ in
            if isAnimating { startAnimation() }
        }
    }

    private func startAnimation() {
        animTimer?.invalidate()
        animTimer = Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: true) { _ in
            MainActor.assumeIsolated { frame = (frame + 1) % 4 }
        }
    }

    private func stopAnimation() {
        animTimer?.invalidate()
        animTimer = nil
    }

    private func drawCatFrame(_ frame: Int, in context: GraphicsContext, size: CGSize, color: Color) {
        let w = size.width, h = size.height
        let bounce: CGFloat = [0, -2, 0, 2][frame % 4]

        var ctx = context
        ctx.translateBy(x: 0, y: bounce)

        let body = Path(ellipseIn: CGRect(x: w * 0.25, y: h * 0.35, width: w * 0.45, height: h * 0.38))
        ctx.fill(body, with: .color(color))

        let head = Path(ellipseIn: CGRect(x: w * 0.55, y: h * 0.12, width: w * 0.3, height: h * 0.28))
        ctx.fill(head, with: .color(color))

        let ear = Path { p in
            p.move(to: CGPoint(x: w * 0.60, y: h * 0.14))
            p.addLine(to: CGPoint(x: w * 0.63, y: h * 0.04))
            p.addLine(to: CGPoint(x: w * 0.68, y: h * 0.14))
            p.closeSubpath()
        }
        ctx.fill(ear, with: .color(color))

        let legOffset: CGFloat = frame < 2 ? 0 : w * 0.06
        let frontLeg = Path(roundedRect:
            CGRect(x: w * 0.55 + legOffset, y: h * 0.62, width: w * 0.1, height: h * 0.28),
            cornerRadius: 4)
        ctx.fill(frontLeg, with: .color(color))

        let backLeg = Path(roundedRect:
            CGRect(x: w * 0.28 - legOffset, y: h * 0.62, width: w * 0.1, height: h * 0.28),
            cornerRadius: 4)
        ctx.fill(backLeg, with: .color(color))

        var tail = Path()
        tail.move(to: CGPoint(x: w * 0.26, y: h * 0.45))
        tail.addQuadCurve(
            to: CGPoint(x: w * 0.05, y: h * 0.25),
            control: CGPoint(x: w * 0.1, y: h * 0.55))
        ctx.stroke(tail, with: .color(color), lineWidth: max(2, w * 0.06))
    }
}

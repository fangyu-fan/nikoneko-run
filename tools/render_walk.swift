import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let width = 1080
let height = 1080
let fps = 30
let seconds = 4
let frames = fps * seconds
let outDir = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "build/walk_frames")
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let ink = CGColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1)
let warmRed = CGColor(red: 0.93, green: 0.28, blue: 0.24, alpha: 1)
let coral = CGColor(red: 0.98, green: 0.46, blue: 0.34, alpha: 1)
let yellow = CGColor(red: 0.98, green: 0.73, blue: 0.16, alpha: 1)
let cream = CGColor(red: 1.0, green: 0.88, blue: 0.55, alpha: 1)
let green = CGColor(red: 0.24, green: 0.65, blue: 0.37, alpha: 1)
let darkGreen = CGColor(red: 0.10, green: 0.38, blue: 0.24, alpha: 1)
let purple = CGColor(red: 0.60, green: 0.35, blue: 0.73, alpha: 1)
let pink = CGColor(red: 0.98, green: 0.44, blue: 0.56, alpha: 1)
let tan = CGColor(red: 0.82, green: 0.50, blue: 0.25, alpha: 1)
let brown = CGColor(red: 0.47, green: 0.25, blue: 0.13, alpha: 1)

func path(_ ctx: CGContext, _ make: (CGMutablePath) -> Void, fill: CGColor?, stroke: CGColor? = ink, line: CGFloat = 5) {
    let p = CGMutablePath(); make(p); ctx.addPath(p)
    if let fill { ctx.setFillColor(fill); ctx.fillPath() }
    if let stroke { ctx.addPath(p); ctx.setStrokeColor(stroke); ctx.setLineWidth(line); ctx.setLineCap(.round); ctx.setLineJoin(.round); ctx.strokePath() }
}

func ellipse(_ ctx: CGContext, _ rect: CGRect, fill: CGColor, stroke: CGColor? = ink, line: CGFloat = 5) {
    ctx.setFillColor(fill); ctx.fillEllipse(in: rect)
    if let stroke { ctx.setStrokeColor(stroke); ctx.setLineWidth(line); ctx.strokeEllipse(in: rect) }
}

func roundRect(_ ctx: CGContext, _ rect: CGRect, radius: CGFloat, fill: CGColor, stroke: CGColor? = ink, line: CGFloat = 5) {
    let p = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.addPath(p); ctx.setFillColor(fill); ctx.fillPath()
    if let stroke { ctx.addPath(p); ctx.setStrokeColor(stroke); ctx.setLineWidth(line); ctx.strokePath() }
}

func face(_ ctx: CGContext, y: CGFloat, wink: Bool = false) {
    ellipse(ctx, CGRect(x: 38, y: y, width: 8, height: 11), fill: ink, stroke: nil)
    if wink {
        path(ctx, { p in p.move(to: CGPoint(x: 91, y: y+8)); p.addLine(to: CGPoint(x: 102, y: y+8)) }, fill: nil, stroke: ink, line: 4)
    } else { ellipse(ctx, CGRect(x: 92, y: y, width: 8, height: 11), fill: ink, stroke: nil) }
    path(ctx, { p in p.move(to: CGPoint(x: 61, y: y-12)); p.addCurve(to: CGPoint(x: 77, y: y-12), control1: CGPoint(x: 66, y: y-5), control2: CGPoint(x: 72, y: y-5)) }, fill: nil, stroke: ink, line: 3)
}

func legs(_ ctx: CGContext, swing: CGFloat, shoe: CGColor = ink) {
    path(ctx, { p in p.move(to: CGPoint(x: 51, y: 38)); p.addLine(to: CGPoint(x: 43 + swing, y: 10)) }, fill: nil, stroke: ink, line: 6)
    path(ctx, { p in p.move(to: CGPoint(x: 89, y: 38)); p.addLine(to: CGPoint(x: 97 - swing, y: 10)) }, fill: nil, stroke: ink, line: 6)
    ellipse(ctx, CGRect(x: 32 + swing, y: 3, width: 23, height: 10), fill: shoe, stroke: nil)
    ellipse(ctx, CGRect(x: 88 - swing, y: 3, width: 23, height: 10), fill: shoe, stroke: nil)
}

func drawMushroom(_ ctx: CGContext, swing: CGFloat) {
    legs(ctx, swing: swing, shoe: ink)
    roundRect(ctx, CGRect(x: 49, y: 34, width: 44, height: 65), radius: 18, fill: cream)
    path(ctx, { p in p.move(to: CGPoint(x: 20, y: 94)); p.addCurve(to: CGPoint(x: 122, y: 94), control1: CGPoint(x: 30, y: 165), control2: CGPoint(x: 112, y: 165)); p.addCurve(to: CGPoint(x: 20, y: 94), control1: CGPoint(x: 105, y: 68), control2: CGPoint(x: 35, y: 68)); p.closeSubpath() }, fill: warmRed, stroke: ink, line: 6)
    ellipse(ctx, CGRect(x: 42, y: 116, width: 14, height: 14), fill: cream, stroke: nil)
    ellipse(ctx, CGRect(x: 82, y: 102, width: 12, height: 12), fill: cream, stroke: nil)
    ellipse(ctx, CGRect(x: 72, y: 133, width: 10, height: 10), fill: cream, stroke: nil)
    face(ctx, y: 67)
}

func drawPotato(_ ctx: CGContext, swing: CGFloat) {
    legs(ctx, swing: swing, shoe: ink)
    path(ctx, { p in p.move(to: CGPoint(x: 31, y: 58)); p.addCurve(to: CGPoint(x: 116, y: 80), control1: CGPoint(x: 17, y: 119), control2: CGPoint(x: 107, y: 150)); p.addCurve(to: CGPoint(x: 31, y: 58), control1: CGPoint(x: 55, y: 25), control2: CGPoint(x: 32, y: 42)); p.closeSubpath() }, fill: tan, stroke: ink, line: 6)
    for (x, y, r) in [(50, 98, 4), (90, 122, 4), (72, 62, 3), (40, 76, 3)] { ellipse(ctx, CGRect(x: x-r, y: y-r, width: r*2, height: r*2), fill: brown, stroke: nil) }
    face(ctx, y: 79, wink: true)
}

func drawAvocado(_ ctx: CGContext, swing: CGFloat) {
    legs(ctx, swing: swing, shoe: ink)
    path(ctx, { p in p.move(to: CGPoint(x: 73, y: 33)); p.addCurve(to: CGPoint(x: 25, y: 103), control1: CGPoint(x: 36, y: 44), control2: CGPoint(x: 13, y: 77)); p.addCurve(to: CGPoint(x: 74, y: 146), control1: CGPoint(x: 36, y: 149), control2: CGPoint(x: 104, y: 153)); p.addCurve(to: CGPoint(x: 111, y: 100), control1: CGPoint(x: 104, y: 145), control2: CGPoint(x: 128, y: 104)); p.addCurve(to: CGPoint(x: 73, y: 33), control1: CGPoint(x: 99, y: 55), control2: CGPoint(x: 83, y: 36)); p.closeSubpath() }, fill: green, stroke: ink, line: 6)
    path(ctx, { p in p.move(to: CGPoint(x: 70, y: 52)); p.addCurve(to: CGPoint(x: 42, y: 103), control1: CGPoint(x: 50, y: 64), control2: CGPoint(x: 36, y: 85)); p.addCurve(to: CGPoint(x: 73, y: 129), control1: CGPoint(x: 48, y: 132), control2: CGPoint(x: 91, y: 135)); p.addCurve(to: CGPoint(x: 96, y: 99), control1: CGPoint(x: 91, y: 129), control2: CGPoint(x: 106, y: 102)); p.addCurve(to: CGPoint(x: 70, y: 52), control1: CGPoint(x: 89, y: 67), control2: CGPoint(x: 78, y: 53)); p.closeSubpath() }, fill: cream, stroke: nil)
    ellipse(ctx, CGRect(x: 58, y: 53, width: 30, height: 30), fill: tan, stroke: ink, line: 4)
    face(ctx, y: 91)
}

func drawDonut(_ ctx: CGContext, swing: CGFloat) {
    legs(ctx, swing: swing, shoe: ink)
    ellipse(ctx, CGRect(x: 22, y: 45, width: 103, height: 102), fill: pink, stroke: ink, line: 6)
    ellipse(ctx, CGRect(x: 53, y: 74, width: 42, height: 40), fill: cream, stroke: ink, line: 5)
    for (x, y, c, r) in [(42, 123, yellow, 4), (98, 126, green, 4), (93, 61, purple, 4), (35, 83, cream, 4)] { ellipse(ctx, CGRect(x: x-r, y: y-r, width: r*2, height: r*2), fill: c, stroke: nil) }
    face(ctx, y: 90, wink: true)
}

func drawPothos(_ ctx: CGContext, swing: CGFloat) {
    legs(ctx, swing: swing, shoe: ink)
    roundRect(ctx, CGRect(x: 28, y: 36, width: 93, height: 56), radius: 18, fill: purple)
    path(ctx, { p in p.move(to: CGPoint(x: 74, y: 94)); p.addCurve(to: CGPoint(x: 42, y: 146), control1: CGPoint(x: 68, y: 112), control2: CGPoint(x: 48, y: 125)); p.addCurve(to: CGPoint(x: 106, y: 136), control1: CGPoint(x: 57, y: 161), control2: CGPoint(x: 94, y: 139)) }, fill: nil, stroke: darkGreen, line: 8)
    path(ctx, { p in p.move(to: CGPoint(x: 52, y: 118)); p.addCurve(to: CGPoint(x: 31, y: 103), control1: CGPoint(x: 44, y: 113), control2: CGPoint(x: 34, y: 102)); p.addCurve(to: CGPoint(x: 52, y: 118), control1: CGPoint(x: 40, y: 125), control2: CGPoint(x: 49, y: 127)); p.closeSubpath() }, fill: green, stroke: ink, line: 4)
    path(ctx, { p in p.move(to: CGPoint(x: 76, y: 132)); p.addCurve(to: CGPoint(x: 111, y: 115), control1: CGPoint(x: 89, y: 130), control2: CGPoint(x: 106, y: 111)); p.addCurve(to: CGPoint(x: 76, y: 132), control1: CGPoint(x: 98, y: 137), control2: CGPoint(x: 83, y: 143)); p.closeSubpath() }, fill: green, stroke: ink, line: 4)
    ellipse(ctx, CGRect(x: 40, y: 61, width: 8, height: 10), fill: cream, stroke: nil)
    ellipse(ctx, CGRect(x: 95, y: 52, width: 8, height: 10), fill: cream, stroke: nil)
    face(ctx, y: 56)
}

func drawTaco(_ ctx: CGContext, swing: CGFloat) {
    legs(ctx, swing: swing, shoe: ink)
    path(ctx, { p in p.move(to: CGPoint(x: 20, y: 55)); p.addCurve(to: CGPoint(x: 125, y: 55), control1: CGPoint(x: 35, y: 149), control2: CGPoint(x: 111, y: 149)); p.addCurve(to: CGPoint(x: 20, y: 55), control1: CGPoint(x: 95, y: 38), control2: CGPoint(x: 43, y: 38)); p.closeSubpath() }, fill: yellow, stroke: ink, line: 6)
    path(ctx, { p in p.move(to: CGPoint(x: 30, y: 75)); p.addCurve(to: CGPoint(x: 116, y: 75), control1: CGPoint(x: 47, y: 104), control2: CGPoint(x: 97, y: 104)) }, fill: nil, stroke: warmRed, line: 12)
    for (x, y, c) in [(47, 82, green), (68, 92, coral), (88, 82, green), (104, 94, pink)] { ellipse(ctx, CGRect(x: x-7, y: y-7, width: 14, height: 14), fill: c, stroke: ink, line: 2) }
    face(ctx, y: 108)
}

func savePNG(_ image: CGImage, to url: URL) throws {
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { throw NSError(domain: "PNG", code: 1) }
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) { throw NSError(domain: "PNG", code: 2) }
}

for i in 0..<frames {
    var pixels = [UInt8](repeating: 255, count: width * height * 4)
    let cs = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { fatalError("context") }
    ctx.setFillColor(CGColor.white); ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let t = Double(i) / Double(fps)
    let phase = t * 2.0 * Double.pi * 1.5
    let swing = CGFloat(sin(phase) * 13)
    let bob = CGFloat(abs(sin(phase)) * 5)
    let xs: [CGFloat] = [80, 250, 420, 590, 760, 930]
    let draws: [(CGContext, CGFloat) -> Void] = [drawMushroom, drawPotato, drawAvocado, drawDonut, drawPothos, drawTaco]
    for (idx, x) in xs.enumerated() {
        ctx.saveGState()
        ctx.translateBy(x: x, y: 438 + bob + CGFloat(idx % 2) * 1.5)
        draws[idx](ctx, swing * (idx % 2 == 0 ? 1 : -1))
        ctx.restoreGState()
    }
    // A very light baseline grounds the march without adding a scene.
    ctx.setStrokeColor(CGColor(red: 0.92, green: 0.92, blue: 0.94, alpha: 1)); ctx.setLineWidth(3)
    ctx.move(to: CGPoint(x: 60, y: 443)); ctx.addLine(to: CGPoint(x: 1020, y: 443)); ctx.strokePath()
    guard let image = ctx.makeImage() else { fatalError("image") }
    try savePNG(image, to: outDir.appendingPathComponent(String(format: "frame_%04d.png", i)))
}
print("Rendered \(frames) frames to \(outDir.path)")

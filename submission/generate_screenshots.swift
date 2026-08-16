import AppKit
import CoreGraphics

// Generates App Store screenshot candidates from the existing Niko Neko visual system.
// These are marketing compositions; replace with screenshots from the signed build before upload.

let outDir = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "submission/screenshots")
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

struct Palette {
    let bg = NSColor(calibratedRed: 0.035, green: 0.035, blue: 0.035, alpha: 1)
    let panel = NSColor(calibratedRed: 0.065, green: 0.065, blue: 0.065, alpha: 1)
    let panel2 = NSColor(calibratedRed: 0.095, green: 0.095, blue: 0.095, alpha: 1)
    let text = NSColor(calibratedRed: 0.94, green: 0.93, blue: 0.91, alpha: 1)
    let muted = NSColor(calibratedRed: 0.42, green: 0.47, blue: 0.42, alpha: 1)
    let dim = NSColor(calibratedRed: 0.32, green: 0.35, blue: 0.32, alpha: 1)
    let green = NSColor(calibratedRed: 0.42, green: 0.73, blue: 0.42, alpha: 1)
    let greenDim = NSColor(calibratedRed: 0.12, green: 0.23, blue: 0.12, alpha: 1)
}

let p = Palette()
let fontName = "SFNS-Regular"
let lightFontName = "SFNS-Ultralight"
let mediumFontName = "SFNS-Medium"

func font(_ size: CGFloat, light: Bool = false, medium: Bool = false) -> NSFont {
    NSFont(name: light ? lightFontName : (medium ? mediumFontName : fontName), size: size) ?? NSFont.systemFont(ofSize: size)
}

func rounded(_ rect: CGRect, radius: CGFloat, fill: NSColor, stroke: NSColor? = nil, width: CGFloat = 1) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    fill.setFill(); path.fill()
    if let stroke { stroke.setStroke(); path.lineWidth = width; path.stroke() }
}

func text(_ value: String, at point: CGPoint, size: CGFloat, color: NSColor, light: Bool = false, medium: Bool = false, alignment: NSTextAlignment = .left) {
    let para = NSMutableParagraphStyle(); para.alignment = alignment
    let attrs: [NSAttributedString.Key: Any] = [.font: font(size, light: light, medium: medium), .foregroundColor: color, .paragraphStyle: para]
    NSAttributedString(string: value, attributes: attrs).draw(at: point)
}

func centerText(_ value: String, x: CGFloat, y: CGFloat, size: CGFloat, color: NSColor, light: Bool = false, medium: Bool = false) {
    let para = NSMutableParagraphStyle(); para.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [.font: font(size, light: light, medium: medium), .foregroundColor: color, .paragraphStyle: para]
    NSAttributedString(string: value, attributes: attrs).draw(in: CGRect(x: x - 500, y: y, width: 1000, height: size + 20))
}

func line(_ a: CGPoint, _ b: CGPoint, color: NSColor, width: CGFloat = 2) {
    color.setStroke(); let path = NSBezierPath(); path.move(to: a); path.line(to: b); path.lineWidth = width; path.stroke()
}

func cat(at center: CGPoint, scale: CGFloat = 1, color: NSColor? = nil) {
    let c = color ?? p.muted; c.setFill(); c.setStroke()
    let body = NSBezierPath(ovalIn: CGRect(x: center.x - 70 * scale, y: center.y - 12 * scale, width: 110 * scale, height: 48 * scale)); body.fill()
    let head = NSBezierPath(ovalIn: CGRect(x: center.x + 25 * scale, y: center.y + 8 * scale, width: 48 * scale, height: 48 * scale)); head.fill()
    let ear = NSBezierPath(); ear.move(to: CGPoint(x: center.x + 30 * scale, y: center.y + 48 * scale)); ear.line(to: CGPoint(x: center.x + 34 * scale, y: center.y + 78 * scale)); ear.line(to: CGPoint(x: center.x + 50 * scale, y: center.y + 54 * scale)); ear.close(); ear.fill()
    for i in 0..<4 { line(CGPoint(x: center.x - 50 * scale + CGFloat(i) * 28 * scale, y: center.y - 14 * scale), CGPoint(x: center.x - 65 * scale + CGFloat(i) * 30 * scale, y: center.y - 50 * scale), color: c, width: 7 * scale) }
}

func save(_ image: NSImage, as name: String) throws {
    guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let data = rep.representation(using: .png, properties: [:]) else { return }
    try data.write(to: outDir.appendingPathComponent(name))
}

func makeImage(_ render: () -> Void) -> NSImage {
    let image = NSImage(size: NSSize(width: 1290, height: 2796))
    image.lockFocus(); p.bg.setFill(); NSRect(origin: .zero, size: image.size).fill(); render(); image.unlockFocus(); return image
}

func header(_ kicker: String, _ title: String, _ sub: String) {
    text(kicker.uppercased(), at: CGPoint(x: 96, y: 2580), size: 32, color: p.green, medium: true)
    text(title, at: CGPoint(x: 96, y: 2380), size: 98, color: p.text, light: true)
    text(sub, at: CGPoint(x: 96, y: 2298), size: 34, color: p.dim)
}

func phone(_ rect: CGRect, content: () -> Void) {
    rounded(rect, radius: 72, fill: p.panel, stroke: NSColor(calibratedWhite: 0.16, alpha: 1), width: 3)
    rounded(CGRect(x: rect.midX - 76, y: rect.maxY - 55, width: 152, height: 18), radius: 9, fill: NSColor(calibratedWhite: 0.12, alpha: 1))
    let screen = CGRect(x: rect.minX + 26, y: rect.minY + 26, width: rect.width - 52, height: rect.height - 100)
    rounded(screen, radius: 52, fill: p.bg)
    content()
}

func timerScreen(_ rect: CGRect, running: Bool = false) {
    phone(rect) {
        let x = rect.minX + 26, y = rect.minY + 26, w = rect.width - 52, h = rect.height - 100
        text("9:41", at: CGPoint(x: x + 30, y: y + h - 40), size: 22, color: p.dim, medium: true)
        text("▮▮▮  ▰", at: CGPoint(x: x + w - 125, y: y + h - 40), size: 20, color: p.dim)
        cat(at: CGPoint(x: x + w / 2 - 12, y: y + h * 0.70), scale: 1.05)
        centerText(running ? "14:32" : "15", x: x + w / 2, y: y + h * 0.49, size: running ? 124 : 150, color: p.text, light: true)
        if !running { centerText("10", x: x + w / 2, y: y + h * 0.42, size: 56, color: NSColor(calibratedWhite: 0.12, alpha: 1), light: true) }
        if running {
            centerText("♥ 124     ⊙ 2.1 km     △ 148 cal", x: x + w / 2, y: y + h * 0.38, size: 28, color: p.dim)
        } else { centerText("♥  —", x: x + w / 2, y: y + h * 0.39, size: 30, color: p.dim) }
        line(CGPoint(x: x + 60, y: y + 170), CGPoint(x: x + w - 60, y: y + 170), color: NSColor(calibratedWhite: 0.12, alpha: 1), width: 2)
        text("♩ 180 bpm", at: CGPoint(x: x + 64, y: y + 120), size: 28, color: p.dim)
        text("♪ ━━━━━ ♫", at: CGPoint(x: x + w - 282, y: y + 120), size: 26, color: p.dim)
        rounded(CGRect(x: x + w/2 - 72, y: y + 32, width: 144, height: 144), radius: 72, fill: running ? p.greenDim : p.panel2, stroke: running ? p.green : p.dim, width: 3)
        centerText(running ? "■" : "▶", x: x + w/2, y: y + 82, size: 48, color: running ? p.green : p.text)
    }
}

func summaryScreen(_ rect: CGRect) {
    phone(rect) {
        let x = rect.minX + 26, y = rect.minY + 26, w = rect.width - 52, h = rect.height - 100
        text("9:41", at: CGPoint(x: x + 30, y: y + h - 40), size: 22, color: p.dim, medium: true)
        cat(at: CGPoint(x: x + w/2 - 12, y: y + h - 150), scale: 0.9)
        centerText("21", x: x + w/2, y: y + h - 430, size: 132, color: p.text, light: true)
        centerText("MIN · COMPLETED", x: x + w/2, y: y + h - 505, size: 22, color: p.dim, medium: true)
        let cardW = (w - 28) / 2
        let startY = y + h - 820
        let labels = [("♥", "122", "AVG HR"), ("♩", "180", "BPM"), ("◎", "100%", "GOAL"), ("◷", "48.4h", "TOTAL")]
        for i in 0..<4 { let xx = x + CGFloat(i % 2) * (cardW + 28), yy = startY - CGFloat(i / 2) * 150; rounded(CGRect(x: xx, y: yy, width: cardW, height: 124), radius: 18, fill: p.panel2); text(labels[i].0, at: CGPoint(x: xx + 24, y: yy + 78), size: 26, color: p.dim); text(labels[i].1, at: CGPoint(x: xx + 24, y: yy + 40), size: 40, color: p.text, light: true); text(labels[i].2, at: CGPoint(x: xx + cardW - 24, y: yy + 19), size: 16, color: p.dim, medium: true, alignment: .right) }
        rounded(CGRect(x: x + 12, y: y + 250, width: w - 24, height: 106), radius: 22, fill: p.greenDim)
        text("13", at: CGPoint(x: x + 42, y: y + 280), size: 58, color: p.green, light: true); text("DAY STREAK", at: CGPoint(x: x + 44, y: y + 260), size: 17, color: p.muted, medium: true)
        for i in 0..<7 { rounded(CGRect(x: x + w - 244 + CGFloat(i) * 28, y: y + 290, width: 17, height: 17), radius: 4, fill: i == 6 ? p.green : p.muted) }
        rounded(CGRect(x: x + 22, y: y + 88, width: w - 44, height: 68), radius: 24, fill: p.text); centerText("DONE", x: x + w/2, y: y + 108, size: 24, color: p.bg, medium: true)
    }
}

func reportScreen(_ rect: CGRect) {
    phone(rect) {
        let x = rect.minX + 26, y = rect.minY + 26, w = rect.width - 52, h = rect.height - 100
        text("9:41", at: CGPoint(x: x + 30, y: y + h - 40), size: 22, color: p.dim, medium: true)
        text("DAY     WEEK     ", at: CGPoint(x: x + 36, y: y + h - 105), size: 21, color: p.dim, medium: true)
        text("MONTH", at: CGPoint(x: x + 300, y: y + h - 105), size: 21, color: p.green, medium: true)
        text("YEAR", at: CGPoint(x: x + 446, y: y + h - 105), size: 21, color: p.dim, medium: true)
        line(CGPoint(x: x + 300, y: y + h - 122), CGPoint(x: x + 392, y: y + h - 122), color: p.green, width: 3)
        centerText("2026 / 05", x: x + w/2, y: y + h - 230, size: 26, color: p.dim)
        text("26.5", at: CGPoint(x: x + 50, y: y + h - 470), size: 118, color: p.text, light: true); text("hrs", at: CGPoint(x: x + 305, y: y + h - 410), size: 30, color: p.dim); text("DURATION", at: CGPoint(x: x + 56, y: y + h - 510), size: 18, color: p.dim, medium: true)
        let metrics = [("⊙", "72.3", "DISTANCE"), ("△", "4.8k", "CALORIES"), ("⊞", "123k", "STEPS")]
        for i in 0..<3 { let xx = x + CGFloat(i) * (w - 12) / 3; rounded(CGRect(x: xx, y: y + h - 700, width: (w - 24) / 3, height: 144), radius: 16, fill: i == 0 ? p.greenDim : p.panel2); text(metrics[i].0, at: CGPoint(x: xx + 20, y: y + h - 615), size: 24, color: p.dim); text(metrics[i].1, at: CGPoint(x: xx + 20, y: y + h - 660), size: 34, color: i == 0 ? p.green : p.text, light: true); text(metrics[i].2, at: CGPoint(x: xx + 20, y: y + h - 685), size: 14, color: p.dim, medium: true) }
        let base = y + 430; for i in 0..<30 { let bh = CGFloat((i * 37) % 90 + 8); let col: NSColor = i % 5 == 0 ? p.green : (i % 2 == 0 ? p.muted : p.greenDim); rounded(CGRect(x: x + 25 + CGFloat(i) * ((w - 50) / 30), y: base, width: 13, height: bh), radius: 4, fill: col) }
        text("Today", at: CGPoint(x: x + 28, y: y + 235), size: 24, color: p.text, medium: true); text("21 min    2.1 km", at: CGPoint(x: x + 255, y: y + 235), size: 22, color: p.dim, alignment: .right); line(CGPoint(x: x + 28, y: y + 205), CGPoint(x: x + w - 28, y: y + 205), color: NSColor(calibratedWhite: 0.12, alpha: 1), width: 2)
        text("5/17", at: CGPoint(x: x + 28, y: y + 160), size: 22, color: p.dim); text("25 min    2.5 km", at: CGPoint(x: x + 255, y: y + 160), size: 22, color: p.dim, alignment: .right)
    }
}

func settingsScreen(_ rect: CGRect) {
    phone(rect) {
        let x = rect.minX + 26, y = rect.minY + 26, w = rect.width - 52, h = rect.height - 100
        text("9:41", at: CGPoint(x: x + 30, y: y + h - 40), size: 22, color: p.dim, medium: true); centerText("SETTINGS", x: x + w/2, y: y + h - 112, size: 23, color: p.text, medium: true)
        let sections = [("APPEARANCE", [("◑", "Theme", "Obsidian"), ("文", "Language", "繁體中文")]), ("DISPLAY", [("◷", "Display", "plain min")]), ("DEFAULTS", [("◎", "Training", "15 min · 180 bpm")]), ("SYSTEM", [("◌", "Notifications", "Off"), ("☁", "Data & Sync", "On-device")])]
        var yy = y + h - 215
        for section in sections { text(section.0, at: CGPoint(x: x + 8, y: yy), size: 17, color: p.dim, medium: true); yy -= 40; let cardH = CGFloat(section.1.count) * 74; rounded(CGRect(x: x, y: yy - cardH + 10, width: w, height: cardH), radius: 18, fill: p.panel2); for row in section.1 { text(row.0, at: CGPoint(x: x + 24, y: yy - 45), size: 25, color: p.dim); text(row.1, at: CGPoint(x: x + 70, y: yy - 44), size: 23, color: p.text); text(row.2, at: CGPoint(x: x + w - 24, y: yy - 44), size: 19, color: p.dim, alignment: .right); yy -= 74 }; yy -= 28 }
    }
}

func widgetsScreen(_ rect: CGRect) {
    phone(rect) {
        let x = rect.minX + 26, y = rect.minY + 26, w = rect.width - 52, h = rect.height - 100
        text("9:41", at: CGPoint(x: x + 30, y: y + h - 40), size: 22, color: p.dim, medium: true); centerText("NIKO NEKO", x: x + w/2, y: y + h - 115, size: 22, color: p.dim, medium: true)
        rounded(CGRect(x: x + 34, y: y + h - 430, width: w - 68, height: 250), radius: 30, fill: p.panel2); text("TODAY", at: CGPoint(x: x + 65, y: y + h - 255), size: 18, color: p.dim, medium: true); text("21", at: CGPoint(x: x + 65, y: y + h - 375), size: 100, color: p.text, light: true); text("min", at: CGPoint(x: x + 250, y: y + h - 345), size: 28, color: p.dim); text("GOAL  100%", at: CGPoint(x: x + 65, y: y + h - 405), size: 20, color: p.green, medium: true)
        rounded(CGRect(x: x + 34, y: y + h - 730, width: (w - 82)/2, height: 200), radius: 28, fill: p.panel2); text("STREAK", at: CGPoint(x: x + 60, y: y + h - 585), size: 16, color: p.dim, medium: true); text("13", at: CGPoint(x: x + 60, y: y + h - 690), size: 76, color: p.green, light: true); text("days", at: CGPoint(x: x + 60, y: y + h - 720), size: 20, color: p.dim)
        rounded(CGRect(x: x + 50 + (w - 82)/2, y: y + h - 730, width: (w - 82)/2, height: 200), radius: 28, fill: p.panel2); text("TOTAL", at: CGPoint(x: x + 76 + (w - 82)/2, y: y + h - 585), size: 16, color: p.dim, medium: true); text("48", at: CGPoint(x: x + 76 + (w - 82)/2, y: y + h - 690), size: 76, color: p.text, light: true); text("hours", at: CGPoint(x: x + 76 + (w - 82)/2, y: y + h - 720), size: 20, color: p.dim)
        text("A quiet nudge, right on your Home Screen.", at: CGPoint(x: x + 44, y: y + 210), size: 22, color: p.dim)
    }
}

let images: [(String, () -> Void)] = [
    ("01_start_in_one_tap.png", { header("NIKO NEKO RUN", "Start in one tap.", "A simple timer for a slower, steadier run."); timerScreen(CGRect(x: 215, y: 540, width: 860, height: 1660)) }),
    ("02_find_your_pace.png", { header("SLOW JOG · SMILE PACE", "Find your pace.", "A metronome, a calm screen, and nothing in the way."); timerScreen(CGRect(x: 215, y: 540, width: 860, height: 1660), running: true) }),
    ("03_quietly_celebrate.png", { header("AFTER YOUR RUN", "Quietly celebrate.", "Every session becomes a small, visible habit."); summaryScreen(CGRect(x: 215, y: 540, width: 860, height: 1660)) }),
    ("04_see_the_pattern.png", { header("REPORTS", "See the pattern.", "Day, week, month, or year — progress without the noise."); reportScreen(CGRect(x: 215, y: 540, width: 860, height: 1660)) }),
    ("05_keep_it_close.png", { header("WIDGETS", "Keep it close.", "Streaks, totals, heatmaps, and today’s run at a glance."); widgetsScreen(CGRect(x: 215, y: 540, width: 860, height: 1660)) }),
    ("06_make_it_yours.png", { header("14 THEMES · EN + 繁中", "Make it yours.", "Choose your colour, character, language, and display details."); settingsScreen(CGRect(x: 215, y: 540, width: 860, height: 1660)) })
]

for (name, render) in images { try save(makeImage(render), as: name) }

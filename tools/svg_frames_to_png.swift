import AppKit
import Foundation

let args = CommandLine.arguments
guard args.count >= 3 else { fatalError("usage: svg_frames_to_png <svg-dir> <png-dir>") }
let inDir = URL(fileURLWithPath: args[1])
let outDir = URL(fileURLWithPath: args[2])
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
let files = try FileManager.default.contentsOfDirectory(at: inDir, includingPropertiesForKeys: nil)
    .filter { $0.pathExtension.lowercased() == "svg" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
for (i, url) in files.enumerated() {
    guard let image = NSImage(contentsOf: url) else { fatalError("could not load \(url.path)") }
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1080, pixelsHigh: 1080, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bitmapFormat: [], bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)!
    NSColor.white.setFill(); NSRect(x: 0, y: 0, width: 1080, height: 1080).fill()
    image.draw(in: NSRect(x: 0, y: 0, width: 1080, height: 1080), from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    let out = outDir.appendingPathComponent(String(format: "frame_%04d.png", i))
    try rep.representation(using: .png, properties: [:])!.write(to: out)
}
print("Converted \(files.count) SVG frames to PNG in \(outDir.path)")

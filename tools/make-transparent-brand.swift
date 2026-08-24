import AppKit
import Foundation

let assetDir = URL(fileURLWithPath: "/Users/daniel/Documents/Codex/banking-app-assignment-site/assets")
let input = assetDir.appendingPathComponent("brand-uob-tmrw-fixed.png")
let output = assetDir.appendingPathComponent("brand-uob-tmrw-transparent.png")

func clamp(_ value: Double, min: Double = 0, max: Double = 1) -> Double {
    Swift.max(min, Swift.min(max, value))
}

func components(_ color: NSColor) -> (Double, Double, Double, Double) {
    let rgb = color.usingColorSpace(.deviceRGB) ?? color
    return (
        Double(rgb.redComponent * 255),
        Double(rgb.greenComponent * 255),
        Double(rgb.blueComponent * 255),
        Double(rgb.alphaComponent)
    )
}

guard
    let image = NSImage(contentsOf: input),
    let tiff = image.tiffRepresentation,
    let source = NSBitmapImageRep(data: tiff)
else {
    fatalError("Could not read brand image")
}

guard let out = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: source.pixelsWide,
    pixelsHigh: source.pixelsHigh,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Could not create output")
}

for y in 0..<source.pixelsHigh {
    for x in 0..<source.pixelsWide {
        guard let color = source.colorAt(x: x, y: y) else { continue }
        var (r, g, b, _) = components(color)
        let whiteSignal = min(r, min(g, b))
        let redSignal = r - max(g, b)
        let blueBackground = b > 95 && b > r + 25 && b > g + 5
        var alpha = 0.0

        if redSignal > 35 && r > 120 {
            alpha = clamp((redSignal - 8) / 55)
            r = 255
            g = 38
            b = 55
        } else if !blueBackground && whiteSignal > 120 {
            alpha = clamp((whiteSignal - 88) / 72)
            r = 255
            g = 255
            b = 255
        }

        if alpha < 0.035 { alpha = 0 }
        out.setColor(
            NSColor(deviceRed: clamp(r / 255), green: clamp(g / 255), blue: clamp(b / 255), alpha: alpha),
            atX: x,
            y: y
        )
    }
}

guard let png = out.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode transparent brand")
}
try png.write(to: output)
print("brand-uob-tmrw-transparent.png \(source.pixelsWide)x\(source.pixelsHigh)")

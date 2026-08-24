import AppKit
import Foundation

struct Spec {
    let source: String
    let output: String
    let x: Int
    let y: Int
    let width: Int
    let height: Int
    let mode: String
}

let assetDir = URL(fileURLWithPath: "/Users/daniel/Documents/Codex/banking-app-assignment-site/assets")
let specs = [
    Spec(source: "blue-reference-fixed.png", output: "quick-paynow-icon-sharp.png", x: 96, y: 432, width: 88, height: 64, mode: "quick"),
    Spec(source: "blue-reference-fixed.png", output: "quick-transfer-icon-sharp.png", x: 304, y: 430, width: 64, height: 66, mode: "quick"),
    Spec(source: "blue-reference-fixed.png", output: "quick-scan-icon-sharp.png", x: 505, y: 430, width: 66, height: 66, mode: "quick"),
    Spec(source: "blue-reference-fixed.png", output: "tool-fx-icon-badge-sharp.png", x: 506, y: 592, width: 132, height: 92, mode: "tool")
]

func clamp(_ value: Double, min: Double = 0, max: Double = 1) -> Double {
    Swift.max(min, Swift.min(max, value))
}

func luma(_ r: Double, _ g: Double, _ b: Double) -> Double {
    0.299 * r + 0.587 * g + 0.114 * b
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

func makeRep(width: Int, height: Int) -> NSBitmapImageRep {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { fatalError("bitmap") }
    return rep
}

func trim(_ source: NSBitmapImageRep, pad: Int) -> NSBitmapImageRep {
    var minX = source.pixelsWide
    var minY = source.pixelsHigh
    var maxX = -1
    var maxY = -1
    for y in 0..<source.pixelsHigh {
        for x in 0..<source.pixelsWide {
            guard let color = source.colorAt(x: x, y: y) else { continue }
            let (_, _, _, alpha) = components(color)
            if alpha > 0.04 {
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }
    }
    if maxX < minX || maxY < minY { return source }
    minX = max(0, minX - pad)
    minY = max(0, minY - pad)
    maxX = min(source.pixelsWide - 1, maxX + pad)
    maxY = min(source.pixelsHigh - 1, maxY + pad)
    let out = makeRep(width: maxX - minX + 1, height: maxY - minY + 1)
    for y in 0..<out.pixelsHigh {
        for x in 0..<out.pixelsWide {
            if let color = source.colorAt(x: minX + x, y: minY + y) {
                out.setColor(color, atX: x, y: y)
            }
        }
    }
    return out
}

for spec in specs {
    guard
        let image = NSImage(contentsOf: assetDir.appendingPathComponent(spec.source)),
        let tiff = image.tiffRepresentation,
        let source = NSBitmapImageRep(data: tiff)
    else { fatalError("read \(spec.source)") }

    let out = makeRep(width: spec.width, height: spec.height)
    for y in 0..<spec.height {
        for x in 0..<spec.width {
            guard let color = source.colorAt(x: spec.x + x, y: spec.y + y) else { continue }
            let (r, g, b, _) = components(color)
            var alpha = 0.0
            var outR = r
            var outG = g
            var outB = b

            if spec.mode == "quick" {
                let dark = 244 - luma(r, g, b)
                alpha = clamp((dark - 45) / 80)
                outR = 82
                outG = 86
                outB = 96
            } else {
                let redSignal = r - max(g, b)
                let whiteSignal = min(r, min(g, b))
                let neutralSpread = max(r, max(g, b)) - whiteSignal
                let blueBg = b > r + 35 && g > r + 10
                if redSignal > 30 && r > 115 {
                    alpha = clamp((redSignal - 12) / 85)
                    outR = 217
                    outG = 54
                    outB = 34
                } else if !blueBg && whiteSignal > 128 && neutralSpread < 90 {
                    alpha = clamp((whiteSignal - 108) / 105)
                    outR = 255
                    outG = 255
                    outB = 255
                }
            }
            if alpha < 0.035 { alpha = 0 }
            out.setColor(NSColor(deviceRed: outR / 255, green: outG / 255, blue: outB / 255, alpha: alpha), atX: x, y: y)
        }
    }

    let final = trim(out, pad: 1)
    guard let png = final.representation(using: .png, properties: [:]) else { fatalError("png") }
    try png.write(to: assetDir.appendingPathComponent(spec.output))
    print("\(spec.output) \(final.pixelsWide)x\(final.pixelsHigh)")
}

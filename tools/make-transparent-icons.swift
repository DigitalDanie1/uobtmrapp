import AppKit
import Foundation

struct Spec {
    let source: String
    let output: String
    let mode: String
    let x: Int
    let y: Int
    let width: Int
    let height: Int
}

let assetDir = URL(fileURLWithPath: "/Users/daniel/Documents/Codex/banking-app-assignment-site/assets")
let specs = [
    Spec(source: "quick-row-strip-fixed.png", output: "quick-paynow-transparent.png", mode: "quick", x: 0, y: 0, width: 102, height: 71),
    Spec(source: "quick-row-strip-fixed.png", output: "quick-transfer-transparent.png", mode: "quick", x: 102, y: 0, width: 103, height: 71),
    Spec(source: "quick-row-strip-fixed.png", output: "quick-scan-transparent.png", mode: "quick", x: 205, y: 0, width: 102, height: 71),
    Spec(source: "tool-row-strip-fixed.png", output: "tool-estatements-transparent.png", mode: "tool", x: 0, y: 0, width: 88, height: 65),
    Spec(source: "tool-row-strip-fixed.png", output: "tool-limits-transparent.png", mode: "tool", x: 88, y: 0, width: 88, height: 65),
    Spec(source: "tool-row-strip-fixed.png", output: "tool-apply-transparent.png", mode: "tool", x: 176, y: 0, width: 88, height: 65),
    Spec(source: "tool-row-strip-fixed.png", output: "tool-fx-transparent.png", mode: "tool", x: 264, y: 0, width: 88, height: 65),
    Spec(source: "bottom-nav-strip-fixed.png", output: "nav-home-transparent.png", mode: "nav", x: 0, y: 0, width: 74, height: 62),
    Spec(source: "bottom-nav-strip-fixed.png", output: "nav-accounts-transparent.png", mode: "nav", x: 74, y: 0, width: 74, height: 62),
    Spec(source: "bottom-nav-strip-fixed.png", output: "nav-wealth-transparent.png", mode: "nav", x: 148, y: 0, width: 74, height: 62),
    Spec(source: "bottom-nav-strip-fixed.png", output: "nav-rewards-transparent.png", mode: "nav", x: 222, y: 0, width: 74, height: 62),
    Spec(source: "bottom-nav-strip-fixed.png", output: "nav-services-transparent.png", mode: "nav", x: 296, y: 0, width: 75, height: 62)
]

func clamp(_ value: Double, min: Double = 0, max: Double = 1) -> Double {
    Swift.max(min, Swift.min(max, value))
}

func luma(_ r: Double, _ g: Double, _ b: Double) -> Double {
    0.299 * r + 0.587 * g + 0.114 * b
}

func colorComponents(_ color: NSColor) -> (Double, Double, Double, Double) {
    let rgb = color.usingColorSpace(.deviceRGB) ?? color
    return (
        Double(rgb.redComponent * 255),
        Double(rgb.greenComponent * 255),
        Double(rgb.blueComponent * 255),
        Double(rgb.alphaComponent)
    )
}

for spec in specs {
    let sourceURL = assetDir.appendingPathComponent(spec.source)
    let outputURL = assetDir.appendingPathComponent(spec.output)
    guard
        let image = NSImage(contentsOf: sourceURL),
        let tiff = image.tiffRepresentation,
        let sourceRep = NSBitmapImageRep(data: tiff)
    else {
        fatalError("Could not read \(spec.source)")
    }

    let width = spec.width
    let height = spec.height
    guard let outputRep = NSBitmapImageRep(
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
    ) else {
        fatalError("Could not create output bitmap")
    }

    for y in 0..<height {
        for x in 0..<width {
            guard let color = sourceRep.colorAt(x: spec.x + x, y: spec.y + y) else { continue }
            var (r, g, b, _) = colorComponents(color)
            var alpha = 0.0

            switch spec.mode {
            case "quick":
                let yValue = luma(r, g, b)
                alpha = clamp((235 - yValue) / 115)
                if alpha < 0.08 { alpha = 0 }
                if alpha > 0 {
                    r = 82
                    g = 86
                    b = 96
                }

            case "tool":
                let redSignal = r - max(g, b)
                let whiteSignal = min(r, min(g, b))
                let neutralSpread = max(r, max(g, b)) - whiteSignal
                let isBlueBackground = b > r + 35 && g > r + 10

                if redSignal > 35 && r > 125 {
                    alpha = clamp((redSignal - 25) / 95)
                    r = 217
                    g = 54
                    b = 34
                } else if !isBlueBackground && whiteSignal > 150 && neutralSpread < 80 {
                    alpha = clamp((whiteSignal - 145) / 95)
                    r = 255
                    g = 255
                    b = 255
                } else if r > 105 && g > 150 && b > 170 {
                    alpha = clamp((r - 95) / 130) * 0.75
                    r = 255
                    g = 255
                    b = 255
                }
                if alpha < 0.08 { alpha = 0 }

            case "nav":
                if y < 5 {
                    alpha = 0
                } else {
                    let yValue = luma(r, g, b)
                    let blueSignal = b - max(r, g)
                    let graySignal = 245 - yValue
                    if blueSignal > 12 && b > 120 {
                        alpha = clamp((blueSignal + graySignal) / 125)
                    } else {
                        alpha = clamp((245 - yValue) / 110)
                    }
                    if alpha < 0.08 { alpha = 0 }
                }

            default:
                fatalError("Unknown mode \(spec.mode)")
            }

            let outputColor = NSColor(
                deviceRed: clamp(r / 255),
                green: clamp(g / 255),
                blue: clamp(b / 255),
                alpha: alpha
            )
            outputRep.setColor(outputColor, atX: x, y: y)
        }
    }

    guard let pngData = outputRep.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode \(spec.output)")
    }
    try pngData.write(to: outputURL)
    print("\(spec.output) \(width)x\(height) from \(spec.source) @ \(spec.x),\(spec.y)")
}

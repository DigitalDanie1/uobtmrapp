import AppKit
import Foundation

let assetDir = URL(fileURLWithPath: "/Users/daniel/Documents/Codex/banking-app-assignment-site/assets")

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

func luma(_ r: Double, _ g: Double, _ b: Double) -> Double {
    0.299 * r + 0.587 * g + 0.114 * b
}

func bitmap(_ name: String) -> NSBitmapImageRep {
    let url = assetDir.appendingPathComponent(name)
    guard
        let image = NSImage(contentsOf: url),
        let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff)
    else { fatalError("Could not read \(name)") }
    return rep
}

func makeOutput(width: Int, height: Int) -> NSBitmapImageRep {
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
    ) else { fatalError("Could not create output") }
    return rep
}

func write(_ rep: NSBitmapImageRep, _ name: String) {
    guard let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode \(name)")
    }
    try! png.write(to: assetDir.appendingPathComponent(name))
    print("\(name) \(rep.pixelsWide)x\(rep.pixelsHigh)")
}

func extractBrand() {
    let source = bitmap("brand-uob-tmrw-fixed.png")
    let output = makeOutput(width: source.pixelsWide, height: source.pixelsHigh)

    var bgSamples: [(Double, Double, Double)] = []
    for y in 0..<source.pixelsHigh {
        for x in 0..<source.pixelsWide {
            guard let color = source.colorAt(x: x, y: y) else { continue }
            let (r, g, b, _) = components(color)
            let blueBg = b > 70 && b > r + 35 && b > g + 15 && r < 70 && g < 80
            if blueBg { bgSamples.append((r, g, b)) }
        }
    }
    let bgR = bgSamples.map(\.0).reduce(0, +) / Double(max(1, bgSamples.count))
    let bgG = bgSamples.map(\.1).reduce(0, +) / Double(max(1, bgSamples.count))
    let bgB = bgSamples.map(\.2).reduce(0, +) / Double(max(1, bgSamples.count))
    let bgL = luma(bgR, bgG, bgB)

    for y in 0..<source.pixelsHigh {
        for x in 0..<source.pixelsWide {
            guard let color = source.colorAt(x: x, y: y) else { continue }
            let (r, g, b, _) = components(color)
            let redSignal = r - max(g, b)
            let light = luma(r, g, b)
            var alpha = 0.0
            var outR = 255.0
            var outG = 255.0
            var outB = 255.0

            if redSignal > 20 && r > 95 {
                alpha = clamp((redSignal - 10) / 85)
                outR = 255
                outG = 38
                outB = 55
            } else if light > bgL + 14 && min(r, min(g, b)) > 70 {
                let aR = (r - bgR) / max(1, 255 - bgR)
                let aG = (g - bgG) / max(1, 255 - bgG)
                let aB = (b - bgB) / max(1, 255 - bgB)
                alpha = clamp((aR + aG + aB) / 3 * 1.25)
            }

            if alpha < 0.025 { alpha = 0 }
            output.setColor(NSColor(deviceRed: outR / 255, green: outG / 255, blue: outB / 255, alpha: alpha), atX: x, y: y)
        }
    }
    write(trim(output, pad: 1), "brand-uob-tmrw-extracted.png")
}

func extractFX() {
    let source = bitmap("blue-reference-fixed.png")
    let cropX = 506
    let cropY = 582
    let width = 138
    let height = 146
    let output = makeOutput(width: width, height: height)

    for y in 0..<height {
        for x in 0..<width {
            guard let color = source.colorAt(x: cropX + x, y: cropY + y) else { continue }
            let (r, g, b, _) = components(color)
            let redSignal = r - max(g, b)
            let whiteSignal = min(r, min(g, b))
            let neutralSpread = max(r, max(g, b)) - whiteSignal
            let blueBg = b > r + 28 && g > r + 4 && b > 110 && r < 95
            var alpha = 0.0
            var outR = 255.0
            var outG = 255.0
            var outB = 255.0

            if redSignal > 30 && r > 115 {
                alpha = clamp((redSignal - 16) / 85)
                outR = 217
                outG = 54
                outB = 34
            } else if !blueBg && whiteSignal > 130 && neutralSpread < 90 {
                alpha = clamp((whiteSignal - 112) / 105)
            }

            if alpha < 0.035 { alpha = 0 }
            output.setColor(NSColor(deviceRed: outR / 255, green: outG / 255, blue: outB / 255, alpha: alpha), atX: x, y: y)
        }
    }
    write(trim(output, pad: 2), "tool-fx-original-extracted.png")
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
            if alpha > 0.035 {
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

    let width = maxX - minX + 1
    let height = maxY - minY + 1
    let output = makeOutput(width: width, height: height)
    for y in 0..<height {
        for x in 0..<width {
            if let color = source.colorAt(x: minX + x, y: minY + y) {
                output.setColor(color, atX: x, y: y)
            }
        }
    }
    return output
}

extractBrand()
extractFX()

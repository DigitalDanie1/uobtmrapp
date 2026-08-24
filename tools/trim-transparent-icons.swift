import AppKit
import Foundation

let assetDir = URL(fileURLWithPath: "/Users/daniel/Documents/Codex/banking-app-assignment-site/assets")
let names = [
    "quick-paynow-transparent.png",
    "quick-transfer-transparent.png",
    "quick-scan-transparent.png",
    "tool-estatements-transparent.png",
    "tool-limits-transparent.png",
    "tool-apply-transparent.png",
    "tool-fx-transparent.png",
    "nav-home-transparent.png",
    "nav-accounts-transparent.png",
    "nav-wealth-transparent.png",
    "nav-rewards-transparent.png",
    "nav-services-transparent.png"
]

func components(_ color: NSColor) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
    let rgb = color.usingColorSpace(.deviceRGB) ?? color
    return (rgb.redComponent, rgb.greenComponent, rgb.blueComponent, rgb.alphaComponent)
}

for name in names {
    let sourceURL = assetDir.appendingPathComponent(name)
    guard
        let image = NSImage(contentsOf: sourceURL),
        let tiff = image.tiffRepresentation,
        let source = NSBitmapImageRep(data: tiff)
    else {
        fatalError("Could not read \(name)")
    }

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

    guard maxX >= minX, maxY >= minY else { continue }
    let pad = name.hasPrefix("quick") ? 2 : 1
    minX = max(0, minX - pad)
    minY = max(0, minY - pad)
    maxX = min(source.pixelsWide - 1, maxX + pad)
    maxY = min(source.pixelsHigh - 1, maxY + pad)

    let width = maxX - minX + 1
    let height = maxY - minY + 1
    guard let output = NSBitmapImageRep(
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
        fatalError("Could not create output")
    }

    for y in 0..<height {
        for x in 0..<width {
            if let color = source.colorAt(x: minX + x, y: minY + y) {
                output.setColor(color, atX: x, y: y)
            }
        }
    }

    let outputName = name.replacingOccurrences(of: "-transparent.png", with: "-trimmed.png")
    guard let png = output.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode \(outputName)")
    }
    try png.write(to: assetDir.appendingPathComponent(outputName))
    print("\(outputName) \(width)x\(height)")
}

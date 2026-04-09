#!/usr/bin/swift
/// Run from the repo root:
///   swift tools/generate_icon.swift
/// Outputs:
///   IronLog/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png  (1024×1024)
import AppKit
import CoreGraphics

let size: CGFloat = 1024
let outputPath = "IronLog/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

// MARK: - Create drawing canvas

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
    isPlanar: false, colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
)!

NSGraphicsContext.saveGraphicsState()
let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = ctx
let cg = ctx.cgContext

// MARK: - Background gradient (dark, near-black)

let bgColors = [
    CGColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1),
    CGColor(red: 0.13, green: 0.09, blue: 0.18, alpha: 1)
]
let bgLocations: [CGFloat] = [0, 1]
let colorSpace = CGColorSpaceCreateDeviceRGB()
let gradient = CGGradient(colorsSpace: colorSpace, colors: bgColors as CFArray, locations: bgLocations)!

cg.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: size),
    end: CGPoint(x: size, y: 0),
    options: []
)

// MARK: - Orange radial glow behind barbell

let glowColors = [
    CGColor(red: 1.0, green: 0.45, blue: 0.0, alpha: 0.30),
    CGColor(red: 1.0, green: 0.45, blue: 0.0, alpha: 0.0)
]
let glow = CGGradient(colorsSpace: colorSpace, colors: glowColors as CFArray, locations: bgLocations)!
cg.drawRadialGradient(
    glow,
    startCenter: CGPoint(x: size / 2, y: size / 2), startRadius: 0,
    endCenter: CGPoint(x: size / 2, y: size / 2), endRadius: size * 0.48,
    options: []
)

// MARK: - Subtle grid

cg.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.04))
cg.setLineWidth(1)
let step = size / 8
for i in 1..<8 {
    let v = step * CGFloat(i)
    cg.move(to: CGPoint(x: v, y: 0)); cg.addLine(to: CGPoint(x: v, y: size))
    cg.move(to: CGPoint(x: 0, y: v)); cg.addLine(to: CGPoint(x: size, y: v))
}
cg.strokePath()

// MARK: - Barbell

let cx = size / 2
let cy = size / 2 - size * 0.02   // slightly above center to leave room for text
let barHalfLen: CGFloat = size * 0.29
let plateHalf: CGFloat = size * 0.19   // half height of plates
let plateWidth: CGFloat = size * 0.055
let barWidth: CGFloat = size * 0.040
let collar: CGFloat = size * 0.034      // thicker section near plates

// Orange-to-amber gradient for barbell strokes
let barbellColors = [
    CGColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1),
    CGColor(red: 1.0, green: 0.80, blue: 0.2, alpha: 1)
]
let barbellGrad = CGGradient(colorsSpace: colorSpace, colors: barbellColors as CFArray, locations: [0, 1] as [CGFloat])!

func strokeWithGradient(path: CGPath, lineWidth: CGFloat) {
    cg.saveGState()
    cg.addPath(path)
    cg.replacePathWithStrokedPath(lineWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 10)
    cg.clip()
    cg.drawLinearGradient(barbellGrad,
                          start: CGPoint(x: cx - barHalfLen, y: cy),
                          end: CGPoint(x: cx + barHalfLen, y: cy),
                          options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    cg.restoreGState()
}

// Bar (horizontal rod)
let barPath = CGMutablePath()
barPath.move(to: CGPoint(x: cx - barHalfLen, y: cy))
barPath.addLine(to: CGPoint(x: cx + barHalfLen, y: cy))
strokeWithGradient(path: barPath, lineWidth: barWidth)

// Plates — two per side
let plateOffsets: [(outer: CGFloat, inner: CGFloat)] = [
    (barHalfLen - plateWidth * 0.5, barHalfLen - plateWidth * 1.7),
    (-(barHalfLen - plateWidth * 0.5), -(barHalfLen - plateWidth * 1.7))
]
for pair in plateOffsets {
    for offset in [pair.outer, pair.inner] {
        let platePath = CGMutablePath()
        platePath.move(to: CGPoint(x: cx + offset, y: cy - plateHalf))
        platePath.addLine(to: CGPoint(x: cx + offset, y: cy + plateHalf))
        let lw = (offset == pair.outer) ? plateWidth : plateWidth * 0.65
        strokeWithGradient(path: platePath, lineWidth: lw)
    }
}

// Collars (slight thickening near plates)
for sign: CGFloat in [-1, 1] {
    let collarX = cx + sign * (barHalfLen - plateWidth * 2.5)
    let collarPath = CGMutablePath()
    collarPath.move(to: CGPoint(x: collarX, y: cy - plateHalf * 0.45))
    collarPath.addLine(to: CGPoint(x: collarX, y: cy + plateHalf * 0.45))
    strokeWithGradient(path: collarPath, lineWidth: collar)
}

// MARK: - "IRONLOG" text

let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.alignment = .center

let font = NSFont.systemFont(ofSize: size * 0.075, weight: .black)
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white,
    .paragraphStyle: paragraphStyle,
    .kern: size * 0.008
]
let text = "IRONLOG" as NSString
let textSize = text.size(withAttributes: attrs)
let textRect = CGRect(
    x: (size - textSize.width) / 2,
    y: size * 0.09,
    width: textSize.width,
    height: textSize.height
)
text.draw(in: textRect, withAttributes: attrs)

// MARK: - Save PNG

NSGraphicsContext.restoreGraphicsState()

guard let pngData = rep.representation(using: .png, properties: [:]) else {
    print("❌ Failed to encode PNG"); exit(1)
}

let url = URL(fileURLWithPath: outputPath)
try! FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                         withIntermediateDirectories: true)
try! pngData.write(to: url)
print("✅ Saved \(Int(size))×\(Int(size)) app icon → \(outputPath)")
print("   Re-run after any design changes. Drag the PNG into Xcode if needed.")

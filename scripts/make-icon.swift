// Vẽ icon app và xuất Resources/AppIcon.icns
// Chạy: swift scripts/make-icon.swift
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = root.appendingPathComponent("build/AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func color(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

func draw(size: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = size / 1024
    NSGraphicsContext.current!.cgContext.scaleBy(x: s, y: s)

    // Nền: squircle theo lưới icon macOS (824pt trong khung 1024)
    let bg = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.shadowBlurRadius = 24
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    color(0xC8603E).setFill()
    bg.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(starting: color(0xEE9670), ending: color(0xB9532F))!.draw(in: bg, angle: -90)

    // Ba "cửa sổ" xếp chồng = nhiều instance
    func card(_ x: CGFloat, _ y: CGFloat, alpha: CGFloat) -> NSBezierPath {
        let r = NSRect(x: x, y: y, width: 470, height: 360)
        let p = NSBezierPath(roundedRect: r, xRadius: 56, yRadius: 56)
        NSGraphicsContext.saveGraphicsState()
        let sh = NSShadow()
        sh.shadowColor = NSColor.black.withAlphaComponent(0.18)
        sh.shadowOffset = NSSize(width: 0, height: -8)
        sh.shadowBlurRadius = 18
        sh.set()
        NSColor.white.withAlphaComponent(alpha).setFill()
        p.fill()
        NSGraphicsContext.restoreGraphicsState()
        return p
    }
    _ = card(340, 430, alpha: 0.38)
    _ = card(270, 340, alpha: 0.62)
    _ = card(200, 250, alpha: 1.0)

    // Thanh tiêu đề của cửa sổ trước
    let frontRect = NSRect(x: 200, y: 250, width: 470, height: 360)
    for (i, hex) in [0xEE6A5F, 0xF5BD4F, 0x61C454].enumerated() {
        color(UInt32(hex)).setFill()
        NSBezierPath(ovalIn: NSRect(x: frontRect.minX + 44 + CGFloat(i) * 46, y: frontRect.maxY - 66, width: 28, height: 28)).fill()
    }

    // Nút play
    let cx = frontRect.midX + 8, cy = frontRect.midY - 22
    let tri = NSBezierPath()
    tri.move(to: NSPoint(x: cx - 62, y: cy + 82))
    tri.line(to: NSPoint(x: cx - 62, y: cy - 82))
    tri.line(to: NSPoint(x: cx + 82, y: cy))
    tri.close()
    tri.lineJoinStyle = .round
    tri.lineWidth = 34
    color(0xD06A45).setFill()
    color(0xD06A45).setStroke()
    tri.fill()
    tri.stroke()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let px = CGFloat(base * scale)
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        let data = draw(size: px).representation(using: .png, properties: [:])!
        try! data.write(to: iconset.appendingPathComponent(name))
    }
}
try! draw(size: 1024).representation(using: .png, properties: [:])!
    .write(to: root.appendingPathComponent("Resources/AppIcon.png"))

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", root.appendingPathComponent("Resources/AppIcon.icns").path]
try! task.run()
task.waitUntilExit()
print(task.terminationStatus == 0 ? "✅ Resources/AppIcon.icns" : "❌ iconutil failed")

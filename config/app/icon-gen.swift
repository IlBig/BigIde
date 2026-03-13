import AppKit

func createIcon(size: CGFloat, outputPath: String) {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    
    // Background — Tokyo Night Storm
    let bg = NSColor(red: 0.118, green: 0.125, blue: 0.188, alpha: 1.0)
    bg.set()
    let radius = size * 0.22
    let path = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: size, height: size),
                            xRadius: radius, yRadius: radius)
    path.fill()
    
    // Subtle border glow
    let accent = NSColor(red: 0.478, green: 0.635, blue: 0.969, alpha: 0.25)
    accent.set()
    path.lineWidth = size * 0.015
    path.stroke()
    
    // "B" letter
    let fontSize = size * 0.52
    let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
    let blue = NSColor(red: 0.478, green: 0.635, blue: 0.969, alpha: 1.0)
    
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: blue
    ]
    let letter = "B" as NSString
    let textSize = letter.size(withAttributes: attrs)
    let x = (size - textSize.width) / 2
    let y = (size - textSize.height) / 2 + size * 0.04
    letter.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)
    
    // "IDE" subtitle
    let smallSize = size * 0.13
    let smallFont = NSFont.systemFont(ofSize: smallSize, weight: .medium)
    let dim = NSColor(red: 0.337, green: 0.373, blue: 0.537, alpha: 0.9)
    let smallAttrs: [NSAttributedString.Key: Any] = [
        .font: smallFont,
        .foregroundColor: dim
    ]
    let ide = "IDE" as NSString
    let ideSize = ide.size(withAttributes: smallAttrs)
    let ideX = (size - ideSize.width) / 2
    let ideY = y - ideSize.height * 0.7
    ide.draw(at: NSPoint(x: ideX, y: ideY), withAttributes: smallAttrs)
    
    img.unlockFocus()
    
    // Export PNG
    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { return }
    try? png.write(to: URL(fileURLWithPath: outputPath))
}

// Create iconset
let iconset = "/tmp/BigIDE.iconset"
try? FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)

let sizes: [CGFloat] = [16, 32, 64, 128, 256, 512, 1024]
for s in sizes {
    createIcon(size: s, outputPath: "\(iconset)/icon_\(Int(s))x\(Int(s)).png")
    if s <= 512 {
        createIcon(size: s * 2, outputPath: "\(iconset)/icon_\(Int(s))x\(Int(s))@2x.png")
    }
}
print("OK")

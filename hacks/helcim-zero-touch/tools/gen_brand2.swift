import AppKit

let outDir = "/Users/aobsiye/Downloads/Helcim-Brand/okta"

func rgb(_ h: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((h >> 16) & 0xFF) / 255,
            green: CGFloat((h >> 8) & 0xFF) / 255,
            blue: CGFloat(h & 0xFF) / 255, alpha: 1)
}

func gradient(_ size: NSSize, _ colors: [NSColor], _ locs: [CGFloat], angle: CGFloat, path: String) {
    let img = NSImage(size: size)
    img.lockFocus()
    var locations = locs
    let g = NSGradient(colors: colors, atLocations: &locations, colorSpace: .deviceRGB)!
    g.draw(in: NSRect(origin: .zero, size: size), angle: angle)
    img.unlockFocus()
    let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
    print("wrote \(path)")
}

let size = NSSize(width: 1920, height: 1080)

// Plum family gradient: Plum -> L-1 -> L-2 -> L-3 (adjacents as blend stops within one family)
gradient(size, [rgb(0x4F1B86), rgb(0x6121A4), rgb(0x7227C1), rgb(0x8436D6)], [0, 0.4, 0.7, 1], angle: -55,
         path: outDir + "/bg-plum-1920.png")

// Navy family gradient: Navy -> L-1 -> L-2 -> L-3
gradient(size, [rgb(0x1A0F4C), rgb(0x1E166A), rgb(0x1F1C89), rgb(0x242CA6)], [0, 0.4, 0.7, 1], angle: -55,
         path: outDir + "/bg-navy-1920.png")

import AppKit

let outDir = "/Users/aobsiye/Downloads/Helcim-Brand/okta"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func rgb(_ h: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((h >> 16) & 0xFF) / 255,
            green: CGFloat((h >> 8) & 0xFF) / 255,
            blue: CGFloat(h & 0xFF) / 255, alpha: 1)
}

func lighten(_ c: NSColor, _ f: CGFloat) -> NSColor {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    c.usingColorSpace(.deviceRGB)!.getRed(&r, green: &g, blue: &b, alpha: &a)
    return NSColor(srgbRed: r + (1 - r) * f, green: g + (1 - g) * f, blue: b + (1 - b) * f, alpha: 1)
}

func gradient(_ size: NSSize, _ colors: [NSColor], _ locs: [CGFloat], angle: CGFloat, path: String) {
    let img = NSImage(size: size)
    img.lockFocus()
    let rect = NSRect(origin: .zero, size: size)
    var locations = locs
    let g = NSGradient(colors: colors, atLocations: &locations, colorSpace: .deviceRGB)!
    g.draw(in: rect, angle: angle)
    img.unlockFocus()
    let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
    let png = rep.representation(using: .png, properties: [:])!
    try! png.write(to: URL(fileURLWithPath: path))
    print("wrote \(path)")
}

let size = NSSize(width: 1920, height: 1080)

// Bold: poster palette — violet -> magenta-mauve -> salmon (diagonal)
gradient(size, [rgb(0x6E00DD), rgb(0xB14EBC), rgb(0xE8A8A5)], [0, 0.55, 1], angle: -55,
         path: outDir + "/bg-bold-1920.png")

// Soft: same hues washed toward white
gradient(size, [lighten(rgb(0x6E00DD), 0.82), lighten(rgb(0xB14EBC), 0.80), lighten(rgb(0xF3959A), 0.72)], [0, 0.55, 1], angle: -55,
         path: outDir + "/bg-soft-1920.png")

// Favicon from BIMI round
if let img = NSImage(contentsOfFile: "/Users/aobsiye/Downloads/Helcim-Brand/helcim-bimi-round-smaller.png") {
    let small = NSImage(size: NSSize(width: 48, height: 48))
    small.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    img.draw(in: NSRect(x: 0, y: 0, width: 48, height: 48))
    small.unlockFocus()
    let rep = NSBitmapImageRep(data: small.tiffRepresentation!)!
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: outDir + "/favicon-48.png"))
    print("wrote \(outDir)/favicon-48.png")
}

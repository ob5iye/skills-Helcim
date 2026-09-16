import AppKit

let outDir = "/Users/aobsiye/Downloads/Helcim-Brand/okta"

func rgb(_ h: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((h >> 16) & 0xFF) / 255,
            green: CGFloat((h >> 8) & 0xFF) / 255,
            blue: CGFloat(h & 0xFF) / 255, alpha: 1)
}

func radial(_ size: NSSize, colors: [NSColor], locs: [CGFloat], center: NSPoint, path: String) {
    let img = NSImage(size: size)
    img.lockFocus()
    let cgColors = colors.map { $0.cgColor } as CFArray
    var locations = locs
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let grad = CGGradient(colorsSpace: space, colors: cgColors, locations: &locations)!
    let ctx = NSGraphicsContext.current!.cgContext
    let c = CGPoint(x: size.width * center.x, y: size.height * center.y)
    let radius = max(size.width, size.height) * 0.85
    ctx.drawRadialGradient(grad, startCenter: c, startRadius: 0, endCenter: c, endRadius: radius,
                           options: [.drawsAfterEndLocation])
    img.unlockFocus()
    let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
    print("wrote \(path)")
}

let size = NSSize(width: 1920, height: 1080)

// Website-style radial glow: bright L-3 violet center -> L-2 -> L-1 -> Plum edges
// center slightly above middle, like the helcim.com hero
radial(size,
       colors: [rgb(0x8436D6), rgb(0x7227C1), rgb(0x6121A4), rgb(0x4F1B86)],
       locs: [0, 0.35, 0.65, 1.0],
       center: NSPoint(x: 0.5, y: 0.58),
       path: outDir + "/bg-plum-radial-1920.png")

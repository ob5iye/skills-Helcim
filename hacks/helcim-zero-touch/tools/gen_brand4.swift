import AppKit

let outDir = "/Users/aobsiye/Downloads/Helcim-Brand/okta"

func rgb(_ h: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((h >> 16) & 0xFF) / 255,
            green: CGFloat((h >> 8) & 0xFF) / 255,
            blue: CGFloat(h & 0xFF) / 255, alpha: 1)
}

let size = NSSize(width: 1920, height: 1080)
let img = NSImage(size: size)
img.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext
let space = CGColorSpace(name: CGColorSpace.sRGB)!

// Punchier site-style: brighter violet core, plum mid, deep dark-plum corners (vignette)
let colors = [rgb(0x9A4FE8), rgb(0x8436D6), rgb(0x6121A4), rgb(0x4F1B86), rgb(0x38125F)].map { $0.cgColor } as CFArray
var locs: [CGFloat] = [0, 0.25, 0.55, 0.8, 1.0]
let grad = CGGradient(colorsSpace: space, colors: colors, locations: &locs)!
let c = CGPoint(x: size.width * 0.5, y: size.height * 0.60)
ctx.drawRadialGradient(grad, startCenter: c, startRadius: 0, endCenter: c,
                       endRadius: max(size.width, size.height) * 0.78,
                       options: [.drawsAfterEndLocation])
img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: outDir + "/bg-plum-radial-punchy-1920.png"))
print("done")

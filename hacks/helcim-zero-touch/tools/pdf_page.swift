import PDFKit
import AppKit

let url = URL(fileURLWithPath: CommandLine.arguments[1])
let pageNum = Int(CommandLine.arguments[2]) ?? 1
let outPath = CommandLine.arguments[3]
guard let doc = PDFDocument(url: url), let page = doc.page(at: pageNum - 1) else { print("fail"); exit(1) }
let bounds = page.bounds(for: .mediaBox)
let img = NSImage(size: bounds.size)
img.lockFocus()
if let ctx = NSGraphicsContext.current?.cgContext {
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fill(CGRect(origin: .zero, size: bounds.size))
    page.draw(with: .mediaBox, to: ctx)
}
img.unlockFocus()
if let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try png.write(to: URL(fileURLWithPath: outPath))
    print("wrote \(outPath)")
}

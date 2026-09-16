import AppKit

func loadBitmap(_ path: String) -> (NSBitmapImageRep, Int, Int)? {
    guard let img = NSImage(contentsOfFile: path),
          let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
    let rep = NSBitmapImageRep(cgImage: cg)
    return (rep, rep.pixelsWide, rep.pixelsHigh)
}

func hex(_ rep: NSBitmapImageRep, _ x: Int, _ y: Int) -> String {
    guard let c = rep.colorAt(x: x, y: y) else { return "?" }
    let r = Int((c.redComponent * 255).rounded())
    let g = Int((c.greenComponent * 255).rounded())
    let b = Int((c.blueComponent * 255).rounded())
    return String(format: "#%02X%02X%02X", r, g, b)
}

for path in CommandLine.arguments.dropFirst() {
    guard let (rep, w, h) = loadBitmap(path) else { print("cannot load \(path)"); continue }
    print("== \(URL(fileURLWithPath: path).lastPathComponent) (\(w)x\(h))")
    let pts: [(String, Double, Double)] = [
        ("top-center    ", 0.5, 0.05),
        ("top-left      ", 0.05, 0.05),
        ("top-right     ", 0.95, 0.05),
        ("center        ", 0.5, 0.5),
        ("center-h-left ", 0.42, 0.45),
        ("bottom-center ", 0.5, 0.95),
        ("bottom-left   ", 0.05, 0.95),
        ("bottom-right  ", 0.95, 0.95),
        ("mid-left      ", 0.05, 0.5),
        ("mid-right     ", 0.95, 0.5),
    ]
    for (name, fx, fy) in pts {
        let x = min(Int(Double(w) * fx), w - 1), y = min(Int(Double(h) * fy), h - 1)
        print("  \(name) \(hex(rep, x, y))")
    }
}

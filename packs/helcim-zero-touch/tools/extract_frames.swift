import AVFoundation
import AppKit

let args = CommandLine.arguments
let url = URL(fileURLWithPath: args[1])
let outDir = args[2]
let stepSeconds = args.count > 3 ? Double(args[3]) ?? 2.0 : 2.0

try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let asset = AVAsset(url: url)
let duration = CMTimeGetSeconds(asset.duration)
print("Duration: \(duration)s")

let gen = AVAssetImageGenerator(asset: asset)
gen.appliesPreferredTrackTransform = true
gen.requestedTimeToleranceBefore = CMTime(seconds: 0.5, preferredTimescale: 600)
gen.requestedTimeToleranceAfter = CMTime(seconds: 0.5, preferredTimescale: 600)
gen.maximumSize = CGSize(width: 1280, height: 1280)

var t = 0.0
var i = 0
while t < duration {
    let time = CMTime(seconds: t, preferredTimescale: 600)
    do {
        let cg = try gen.copyCGImage(at: time, actualTime: nil)
        let rep = NSBitmapImageRep(cgImage: cg)
        if let data = rep.representation(using: .png, properties: [:]) {
            let path = String(format: "%@/frame_%03d.png", outDir, i)
            try data.write(to: URL(fileURLWithPath: path))
            print("wrote \(path) @ \(t)s")
        }
    } catch {
        print("skip @ \(t)s: \(error.localizedDescription)")
    }
    i += 1
    t += stepSeconds
}
print("done")

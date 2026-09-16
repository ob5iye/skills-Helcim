import PDFKit
import Foundation

let url = URL(fileURLWithPath: CommandLine.arguments[1])
guard let doc = PDFDocument(url: url) else { print("cannot open"); exit(1) }
print("PAGES: \(doc.pageCount)")
for i in 0..<doc.pageCount {
    if let page = doc.page(at: i), let text = page.string {
        print("===== PAGE \(i+1) =====")
        print(text)
    }
}

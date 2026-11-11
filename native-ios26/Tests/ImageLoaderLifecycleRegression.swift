// Host-only image stand-in: exercise the production loader's cancellation,
// cache and result-ordering logic without requiring an iPhone or UIKit.
import Foundation
import CoreGraphics
import Combine

final class UIImage {
    let marker: UInt8
    let size = CGSize(width: 16, height: 16)
    let scale: CGFloat = 1
    struct Bitmap { let bytesPerRow = 64; let height = 16 }
    var cgImage: Bitmap? { Bitmap() }
    init?(data: Data) {
        guard let first = data.first else { return nil }
        marker = first
    }
}
enum AppRuntime { static let isRunningForPreview = false }

@main
struct ImageLoaderLifecycleRegression {
    @MainActor static func settle() async {
        try? await Task.sleep(for: .milliseconds(150))
    }
    @MainActor static func main() async {
        let first = Data(repeating: 65, count: 256).base64EncodedString()
        let second = Data(repeating: 66, count: 256).base64EncodedString()
        let loader = ImageLoader()

        loader.load(from: first)
        loader.cancel()
        await settle()
        precondition(loader.image == nil, "Cancelled decode updated a disappeared view")

        loader.load(from: first)
        loader.load(from: second)
        await settle()
        precondition(loader.image?.marker == 66, "Old request replaced the new image")
        let original = loader.image!

        let another = ImageLoader()
        another.load(from: second)
        precondition(another.image === original, "Live images should reuse the cache")

        loader.load(from: nil)
        precondition(loader.image == nil, "Removed URL retained stale image")

        ImageLoader.clearCache()
        another.load(from: second)
        await settle()
        precondition(another.image != nil && another.image !== original, "Memory warning did not clear cache")

        for _ in 0..<100 {
            loader.load(from: first)
            loader.cancel()
        }
        await settle()
        precondition(loader.image == nil, "Repeated open/close accepted a stale decode")
        print("PASS: cancellation, replacement, cache reuse, missing URL, memory purge, 100 reopen/cancel cycles")
    }
}

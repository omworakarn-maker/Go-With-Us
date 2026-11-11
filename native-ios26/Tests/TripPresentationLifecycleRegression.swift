import Foundation
import CoreGraphics

@main
private enum TripCreationRegression {
    static func require(_ condition: @autoclosure () -> Bool, _ message: String) {
        precondition(condition(), message)
    }

    static func main() {
        var page = TripCreationState()
        var used = Set<UUID>()
        for _ in 0..<50 {
            let id = page.open()
            require(used.insert(id).inserted, "Every reopened form must have a fresh identity")
            page.close(id)
            require(page.id == nil, "Cancel must synchronously remove the active page")
        }

        let first = page.open()
        require(page.open() == first, "Repeated + taps must not create a second page")
        page.close(first)
        let second = page.open()
        page.close(first)
        require(page.id == second, "An old save/dismiss callback must not close a reopened form")
        page.reset()
        page.close(second)
        require(page.id == nil, "Logout reset must leave no page or controller to dismiss")

        let canvas = CGSize(width: 390, height: 810)
        let source = CGRect(x: 310, y: 738, width: 56, height: 56)
        require(TripCreationGeometry.frame(in: canvas, source: source, progress: 0) == source,
                "Expansion must originate at the actual + button bounds")
        require(TripCreationGeometry.frame(in: canvas, source: source, progress: 1) == CGRect(origin: .zero, size: canvas),
                "The settled page must fill the canvas without a second presentation")
        var previous = source
        for frame in 1...120 {
            let rect = TripCreationGeometry.frame(in: canvas, source: source, progress: CGFloat(frame) / 120)
            require(rect.width >= previous.width && rect.height >= previous.height,
                    "Expansion must not jump backwards or reveal an empty frame")
            previous = rect
        }

        let invalid = CGRect(x: CGFloat.nan, y: 0, width: 56, height: 56)
        let fallback = TripCreationGeometry.source(in: .zero, measured: invalid)
        let rect = TripCreationGeometry.frame(in: .zero, source: fallback, progress: 0.5)
        require(rect.midX.isFinite && rect.midY.isFinite && rect.width > 0 && rect.height > 0,
                "A missing first layout must have finite nonempty geometry")
        print("Trip creation: 8 regression scenarios passed, including 50 open/Cancel cycles")
    }
}

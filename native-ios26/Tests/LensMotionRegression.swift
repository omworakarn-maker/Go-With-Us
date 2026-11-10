import Foundation

@main
private enum LensMotionRegression {
    static func require(_ condition: @autoclosure () -> Bool, _ message: String) {
        precondition(condition(), message)
    }

    static func advance(_ motion: inout TabLensMotion, seconds: Double, fps: Int = 120) {
        for _ in 0..<Int(seconds * Double(fps)) {
            motion.advance(seconds: 1 / Double(fps), itemWidth: 70, reduceMotion: false)
        }
    }

    static func movingPointer(step: Double) -> TabLensMotion {
        var motion = TabLensMotion()
        motion.reset(at: 35)
        motion.point(at: 35, vertical: 0, time: 0, follows: false)
        for frame in 1...60 {
            let time = Double(frame) / 120
            motion.point(at: 35 + Double(frame) * step, vertical: 5, time: time, follows: true)
            motion.advance(seconds: 1 / 120, itemWidth: 70, reduceMotion: false)
        }
        return motion
    }

    static func main() {
        var sixty = TabLensMotion()
        sixty.reset(at: 35)
        sixty.destination = 245
        var oneTwenty = sixty
        advance(&sixty, seconds: 0.5, fps: 60)
        advance(&oneTwenty, seconds: 0.5, fps: 120)
        require(abs(sixty.horizontal.position - oneTwenty.horizontal.position) < 0.00001,
                "Tab landing must not depend on the display refresh rate")

        var fast = movingPointer(step: 10)
        let slow = movingPointer(step: 2)
        require(fast.elongation.position > slow.elongation.position + 0.02,
                "Fast dragging should stretch the lens more than slow dragging")
        require(fast.lean.position > 0, "Rightward motion must lean right")
        fast.point(at: fast.destination - 30, vertical: -5, time: 0.51, follows: true)
        let beforeRelease = fast.horizontal.position
        fast.settle(at: 175)
        require(fast.horizontal.position == beforeRelease, "Releasing must preserve the displayed position")
        fast.raised = false
        advance(&fast, seconds: 1.5)
        require(abs(fast.horizontal.position - 175) < 0.02, "Drag must settle on its committed tab")
        require(fast.isSettled, "The frame loop must be able to sleep after release")

        var interrupted = TabLensMotion()
        interrupted.reset(at: 35)
        interrupted.destination = 245
        advance(&interrupted, seconds: 0.1)
        let position = interrupted.horizontal.position
        let velocity = interrupted.horizontal.velocity
        interrupted.settle(at: 105)
        require(interrupted.horizontal.position == position && interrupted.horizontal.velocity == velocity,
                "A new destination must continue the current spring, not restart at a tab")
        advance(&interrupted, seconds: 1.5)
        require(abs(interrupted.horizontal.position - 105) < 0.02, "The latest destination must win")

        var held = movingPointer(step: 6)
        held.point(at: held.destination, vertical: 0, time: 0.51, follows: true)
        advance(&held, seconds: 1.5)
        require(held.isSettled && held.pressure.position > 0.99,
                "Holding still should keep the lens raised without an endless frame loop")

        var reduced = movingPointer(step: 8)
        reduced.settle(at: 315)
        reduced.raised = false
        reduced.advance(seconds: 0, itemWidth: 70, reduceMotion: true)
        require(reduced.horizontal.position == 315 && reduced.horizontal.velocity == 0,
                "Reduce Motion must land immediately")
        require(reduced.elongation.position == 0 && reduced.lean.position == 0,
                "Reduce Motion must disable deformation")

        var delayed = movingPointer(step: 10)
        delayed.advance(seconds: 100, itemWidth: 0, reduceMotion: false)
        require(delayed.horizontal.position.isFinite && delayed.elongation.position.isFinite,
                "A delayed frame or zero-width layout must not corrupt motion")
        print("Lens motion: 7 regression scenarios passed")
    }
}

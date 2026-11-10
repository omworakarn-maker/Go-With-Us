import Foundation

@main
private enum TripPresentationLifecycleRegression {
    static func require(_ condition: @autoclosure () -> Bool, _ message: String) {
        precondition(condition(), message)
    }
    static func requestedID(_ effect: TripPresentationLifecycle.Effect?) -> UUID {
        guard case let .attach(id) = effect else { fatalError("Expected one presentation attachment") }
        return id
    }
    static func open(_ state: inout TripPresentationLifecycle) -> UUID {
        let id = requestedID(state.request(true))
        require(state.beginPresentation(id), "Active attachment must be allowed to present")
        require(state.didPresent(id) == nil, "Visible page must not start another transition")
        return id
    }
    static func main() {
        var repeated = TripPresentationLifecycle()
        let first = open(&repeated)
        require(repeated.request(false) == .dismiss(first), "Closing must dismiss the current controller")
        require(repeated.activeID == first, "Controller ownership must remain until UIKit finishes dismissal")
        require(repeated.didDismiss(first) == nil, "Completed close must return to idle")
        let second = open(&repeated)
        require(second != first && repeated.phase == .visible(second), "Second tap must open a fresh page")

        var queued = TripPresentationLifecycle()
        let old = open(&queued)
        _ = queued.request(false)
        require(queued.request(true) == nil, "Rapid reopen must wait for the old dismissal")
        let next = requestedID(queued.didDismiss(old))
        require(next != old && queued.wantsVisible, "Queued reopen must preserve the user's open request")
        require(queued.didDismiss(old) == nil && queued.activeID == next, "Late dismissal must not clear the next attachment")

        require(queued.beginPresentation(next), "Queued attachment must present after the old controller closes")
        require(queued.didPresent(old) == nil && queued.phase == .presenting(next), "Old presentation completion must not affect the new page")
        _ = queued.didPresent(next)
        require(queued.didDismiss(old) == nil && queued.phase == .visible(next), "Old delegate callback must not dismiss the new page")

        var cancelled = TripPresentationLifecycle()
        let cancelledID = requestedID(cancelled.request(true))
        _ = cancelled.request(false)
        let replacement = requestedID(cancelled.request(true))
        require(!cancelled.beginPresentation(cancelledID), "Cancelled attachment must never flash on screen")
        cancelled.attachmentFailed(cancelledID)
        require(cancelled.activeID == replacement && cancelled.wantsVisible, "An old failed task must not reset its replacement")

        var gesture = TripPresentationLifecycle()
        let gestureID = open(&gesture)
        gesture.beginInteractiveDismissal(gestureID)
        require(!gesture.wantsVisible, "Interactive close must synchronize the binding")
        gesture.cancelInteractiveDismissal(gestureID)
        require(gesture.phase == .visible(gestureID) && gesture.wantsVisible, "Cancelled swipe must keep the existing page")
        require(gesture.request(true) == nil, "Cancelled swipe must not present a duplicate page")

        var earlyClose = TripPresentationLifecycle()
        let earlyID = requestedID(earlyClose.request(true))
        require(earlyClose.beginPresentation(earlyID), "Attachment must begin")
        require(earlyClose.request(false) == nil, "Do not dismiss during an in-flight presentation")
        require(earlyClose.didPresent(earlyID) == .dismiss(earlyID), "Close immediately after presentation completes")
        _ = earlyClose.didDismiss(earlyID)
        require(earlyClose.phase == .idle, "An early close must not leave a stuck controller")

        var detached = TripPresentationLifecycle()
        let failedID = requestedID(detached.request(true))
        detached.attachmentFailed(failedID)
        require(detached.phase == .idle && !detached.wantsVisible, "Missing window must allow retry")
        require(requestedID(detached.request(true)) != failedID, "Retry must have a fresh lifecycle")

        var cycles = TripPresentationLifecycle()
        var ids = Set<UUID>()
        for _ in 0..<25 {
            let id = open(&cycles)
            require(ids.insert(id).inserted, "Every presentation must own a unique controller lifecycle")
            for _ in 0..<10 { require(cycles.request(true) == nil, "Badge/render updates must not present again") }
            _ = cycles.request(false)
            _ = cycles.didDismiss(id)
            require(cycles.phase == .idle, "Every completed cycle must release ownership")
        }
        print("Trip presentation: 8 regression scenarios passed (including 25 open/close cycles)")
    }
}

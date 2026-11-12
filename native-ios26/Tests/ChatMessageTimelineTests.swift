import Foundation

// Compile with the production Models/Message.swift; no network or UIKit required.
@main
struct ChatMessageTimelineTests {
    static func message(_ id: String, state: MessageDeliveryState? = nil) -> Message {
        var message = Message(id: id, content: id, senderId: "self", recipientId: "friend",
                              tripId: nil, createdAt: Date(), sender: nil, recipient: nil, imageUrl: nil)
        message.deliveryState = state
        if state != nil { message.localID = id }
        return message
    }

    static func main() throws {
        let history = message("old")
        let first = message("local-first", state: .sending)
        let second = message("local-second", state: .sending)
        let initial = [history, first, second]
        let known = Set(initial.map(\.id))
        let staleRefresh = ChatMessageTimeline.merge([history], with: initial, knownIDs: known)
        assert(staleRefresh.map(\.displayID) == initial.map(\.displayID), "refresh must preserve pending sends")

        let serverSecond = message("server-second")
        let acknowledged = ChatMessageTimeline.acknowledge(serverSecond, replacing: second.displayID, in: initial)
        assert(acknowledged.last?.id == serverSecond.id)
        assert(acknowledged.last?.displayID == second.displayID, "acknowledgement must preserve scroll identity")
        assert(acknowledged.last?.deliveryState == .sent)
        assert(acknowledged[1].deliveryState == .sending, "concurrent sends keep independent status")
        let staleAfterAck = ChatMessageTimeline.merge([history], with: acknowledged, knownIDs: known)
        assert(staleAfterAck.count == 3, "response started before acknowledgement must not remove it")

        let echoed = initial + [serverSecond]
        let deduplicated = ChatMessageTimeline.acknowledge(serverSecond, replacing: second.displayID, in: echoed)
        assert(deduplicated.filter { $0.id == serverSecond.id }.count == 1)
        let confirmedRefresh = ChatMessageTimeline.merge([history, serverSecond], with: deduplicated, knownIDs: known)
        assert(confirmedRefresh.first { $0.id == serverSecond.id }?.displayID == second.displayID)

        let failed = message("local-failed", state: .failed)
        assert(ChatMessageTimeline.merge([], with: [failed], knownIDs: [failed.id]).first?.deliveryState == .failed)
        assert(first != message(first.id, state: .sent), "status changes must update the UI")

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ChatHistoryStore(directory: directory)
        let finished = DispatchSemaphore(value: 0)
        store.save([history, first], key: "account-1:person:friend") { finished.signal() }
        assert(finished.wait(timeout: .now() + 5) == .success)
        let restored = store.load(key: "account-1:person:friend")
        assert(restored?.first?.id == history.id, "cached history must survive recreating a chat")
        assert(restored?.last?.deliveryState == .failed, "interrupted sends must not spin forever")
        assert(store.load(key: "account-2:person:friend") == nil, "disk caches must be scoped to the account")

        let legacyJSON = #"{"id":"legacy","content":"hello","senderId":"friend","createdAt":0}"#
        let legacy = try JSONDecoder().decode(Message.self, from: Data(legacyJSON.utf8))
        assert(legacy.deliveryState == nil && legacy.displayID == "legacy")
        print("PASS: pending sends, concurrent acknowledgements, stable scroll identity, stale refresh, deduplication, failure states, disk history, account isolation, and legacy decoding")
    }
}

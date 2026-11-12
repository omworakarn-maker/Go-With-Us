import Foundation

// MARK: - Message Model
struct Message: Codable, Identifiable, Equatable {
    let id: String
    let content: String
    let senderId: String
    let recipientId: String?
    let tripId: String?
    let createdAt: Date
    let sender: ChatUser?
    let recipient: ChatUser?
    var isRead: Bool?
    var isSystem: Bool? = nil
    var imageUrl: String?
    var deliveryState: MessageDeliveryState? = nil
    var localID: String? = nil

    var displayID: String { localID ?? id }

    // Equatable for UI updates
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id && lhs.deliveryState == rhs.deliveryState && lhs.isRead == rhs.isRead && lhs.content == rhs.content && lhs.imageUrl == rhs.imageUrl && lhs.localID == rhs.localID
    }
}

// MARK: - Chat User (Simplified User for Chat)
struct ChatUser: Codable, Identifiable {
    let id: String
    let name: String
    let username: String? = nil
    let email: String
    var avatarUrl: String? // Future proofing
    var profileImage: String?
    var gallery: [String]?

    var displayHandle: String {
        guard let username = username?.trimmingCharacters(in: .whitespacesAndNewlines),
              !username.isEmpty else { return name }
        return username.hasPrefix("@") ? username : "@\(username)"
    }
}

// MARK: - Conversation Model
struct Conversation: Codable, Identifiable {
    var id: String { user.id } // Use partner's ID as conversation ID
    let user: ChatUser
    let lastMessage: Message
    let unreadCount: Int?
}

enum MessageDeliveryState: String, Codable {
    case sending, sent, failed
}

enum ChatMessageTimeline {
    static func acknowledge(_ server: Message, replacing localID: String, in messages: [Message]) -> [Message] {
        var confirmed = server
        confirmed.localID = localID
        confirmed.deliveryState = .sent
        return messages.compactMap { message in
            if message.displayID == localID { return confirmed }
            return message.id == server.id ? nil : message
        }
    }

    // Keep local sends while a history request is in flight. An older response
    // must not remove a pending message or an acknowledgement received after it began.
    static func merge(_ server: [Message], with current: [Message], knownIDs: Set<String>) -> [Message] {
        let currentByID = Dictionary(current.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
        let serverIDs = Set(server.map(\.id))
        var result = server.map { message -> Message in
            var updated = message
            if let previous = currentByID[message.id] {
                updated.localID = previous.localID
                updated.deliveryState = previous.deliveryState == nil ? nil : .sent
            }
            return updated
        }
        result += current.filter {
            !serverIDs.contains($0.id) &&
            ($0.deliveryState == .sending || $0.deliveryState == .failed ||
             ($0.deliveryState == .sent && !knownIDs.contains($0.id)))
        }
        return result
    }
}

final class ChatHistoryStore {
    static let shared = ChatHistoryStore()
    private let directory: URL
    private let writer = DispatchQueue(label: "GoWithUs.ChatHistory")

    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GoWithUsChatHistory", isDirectory: true)
    }

    private func fileURL(key: String) -> URL {
        let name = Data(key.utf8).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        return directory.appendingPathComponent(name).appendingPathExtension("json")
    }

    func load(key: String) -> [Message]? {
        guard let data = try? Data(contentsOf: fileURL(key: key)),
              let stored = try? JSONDecoder().decode([Message].self, from: data) else { return nil }
        return stored.map {
            var message = $0
            // A request from a previous process cannot still be sending.
            if message.deliveryState == .sending { message.deliveryState = .failed }
            return message
        }
    }

    func save(_ messages: [Message], key: String, completion: (() -> Void)? = nil) {
        let recent = Array(messages.suffix(150))
        let url = fileURL(key: key)
        let directory = directory
        writer.async {
            defer { completion?() }
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                let data = try JSONEncoder().encode(recent)
                try data.write(to: url, options: .atomic)
            } catch {
                // Disk caching is optional; the active conversation remains in memory.
            }
        }
    }
}

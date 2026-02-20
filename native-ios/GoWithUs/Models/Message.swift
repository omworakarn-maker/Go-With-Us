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
    
    // Equatable for UI updates
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Chat User (Simplified User for Chat)
struct ChatUser: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    var avatarUrl: String? // Future proofing
    var profileImage: String?
}

// MARK: - Conversation Model
struct Conversation: Codable, Identifiable {
    var id: String { user.id } // Use partner's ID as conversation ID
    let user: ChatUser
    let lastMessage: Message
    let unreadCount: Int?
}

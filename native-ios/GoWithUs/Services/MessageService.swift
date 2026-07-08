import Foundation

// MARK: - Message Service
class MessageService {
    static let shared = MessageService()
    
    private init() {}
    
    // MARK: - Get Conversations (Private Chats)
    func getConversations() async throws -> [Conversation] {
        struct ConversationsResponse: Decodable {
            let conversations: [Conversation]
        }
        
        let response: ConversationsResponse = try await APIService.shared.request(
            endpoint: "/messages/conversations",
            method: .get
        )
        
        return response.conversations
    }
    
    // MARK: - Get Private Messages
    func getPrivateMessages(userId: String) async throws -> [Message] {
        struct MessagesResponse: Decodable {
            let messages: [Message]
        }
        
        let response: MessagesResponse = try await APIService.shared.request(
            endpoint: "/messages/private/\(userId)",
            method: .get
        )
        
        return response.messages
    }
    
    // MARK: - Send Private Message
    func sendPrivateMessage(userId: String, content: String, imageUrl: String? = nil) async throws -> Message {
        struct MessageRequest: Encodable {
            let content: String
            let imageUrl: String?
        }
        
        struct MessageResponseWrapper: Decodable {
            let message: Message
        }
        
        let request = MessageRequest(content: content, imageUrl: imageUrl)
        
        let response: MessageResponseWrapper = try await APIService.shared.request(
            endpoint: "/messages/private/\(userId)",
            method: .post,
            body: request
        )
        
        return response.message
    }
    
    // MARK: - Get Trip Messages (Group Chat)
    func getTripMessages(tripId: String) async throws -> [Message] {
        struct MessagesResponse: Decodable {
            let messages: [Message]
        }
        
        let response: MessagesResponse = try await APIService.shared.request(
            endpoint: "/messages/trips/\(tripId)",
            method: .get
        )
        
        return response.messages
    }
    
    // MARK: - Send Trip Message
    func sendTripMessage(tripId: String, content: String, imageUrl: String? = nil) async throws -> Message {
        struct MessageRequest: Encodable {
            let content: String
            let imageUrl: String?
        }
        
        struct MessageResponseWrapper: Decodable {
            let message: Message
        }
        
        let request = MessageRequest(content: content, imageUrl: imageUrl)
        
        let response: MessageResponseWrapper = try await APIService.shared.request(
            endpoint: "/messages/trips/\(tripId)",
            method: .post,
            body: request
        )
        
        return response.message
    }
    
    // MARK: - Delete Message (Unsend)
    func deleteMessage(messageId: String) async throws {
        let _: MessageResponse = try await APIService.shared.request(
            endpoint: "/messages/\(messageId)",
            method: .delete
        )
    }
    
    // MARK: - Delete Conversation (Unmatch)
    func deleteConversation(userId: String) async throws {
        struct EmptyResponse: Decodable {}
        let _: EmptyResponse = try await APIService.shared.request(
            endpoint: "/messages/private/\(userId)",
            method: .delete
        )
    }
}

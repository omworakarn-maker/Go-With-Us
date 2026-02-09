import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    // List of conversations
    @Published var conversations: [Conversation] = []
    
    // Active chat messages
    @Published var messages: [Message] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Track last message count for detecting new messages
    private var lastMessageCount = 0
    
    // Current User ID
    private var currentUserId: String? {
        return AuthService.shared.getCurrentUserId()
    }
    
    // MARK: - Load Conversations
    func loadConversations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            conversations = try await MessageService.shared.getConversations()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Load Private Messages
    func loadPrivateMessages(userId: String) async {
        isLoading = true
        errorMessage = nil
        messages = [] // Clear previous messages
        
        do {
            messages = try await MessageService.shared.getPrivateMessages(userId: userId)
            lastMessageCount = messages.count
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Send Private Message
    func sendPrivateMessage(userId: String, content: String) async {
        guard !content.isEmpty else { return }
        
        do {
            let message = try await MessageService.shared.sendPrivateMessage(userId: userId, content: content)
            messages.append(message)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Load Trip Messages (Group Chat)
    func loadTripMessages(tripId: String) async {
        isLoading = true
        errorMessage = nil
        messages = []
        
        do {
            messages = try await MessageService.shared.getTripMessages(tripId: tripId)
            lastMessageCount = messages.count
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Send Trip Message
    func sendTripMessage(tripId: String, content: String) async {
        guard !content.isEmpty else { return }
        
        do {
            let message = try await MessageService.shared.sendTripMessage(tripId: tripId, content: content)
            messages.append(message)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Delete Conversation
    func deleteConversation(at offsets: IndexSet) {
        // Optimistic update
        let idsToDelete = offsets.map { conversations[$0].id }
        conversations.remove(atOffsets: offsets)
        
        Task {
            for id in idsToDelete {
                // TODO: specific API endpoint for deleting conversation if available
                // For now, we assume local hide or implementation on backend
                // await MessageService.shared.deleteConversation(id: id) 
            }
        }
    }
    
    // MARK: - Refresh Messages (Silent, for polling)
    func refreshPrivateMessages(userId: String) async {
        // Silent refresh without showing loading state
        do {
            let newMessages = try await MessageService.shared.getPrivateMessages(userId: userId)
            if newMessages.count > lastMessageCount {
                messages = newMessages
                lastMessageCount = newMessages.count
            }
        } catch {
            // Silently fail for polling
        }
    }
    
    func refreshTripMessages(tripId: String) async {
        // Silent refresh without showing loading state
        do {
            let newMessages = try await MessageService.shared.getTripMessages(tripId: tripId)
            if newMessages.count > lastMessageCount {
                messages = newMessages
                lastMessageCount = newMessages.count
            }
        } catch {
            // Silently fail for polling
        }
    }
    
    // MARK: - Helper
    func isFromCurrentUser(message: Message) -> Bool {
        return message.senderId == currentUserId
    }
}

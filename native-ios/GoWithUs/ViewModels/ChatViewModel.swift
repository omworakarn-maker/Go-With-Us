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
    // Local overrides to keep unread badges visible until user reads
    private var localUnreadOverrides: [String: Int] = [:]
    
    // Current User ID
    private var currentUserId: String? {
        return AuthService.shared.getCurrentUserId()
    }

    private var observersSet = false

    init() {
        // Subscribe once to conversation new-message events
        guard !observersSet else { return }
        observersSet = true
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ConversationNewMessage"), object: nil, queue: .main) { [weak self] note in
            guard let self = self else { return }
            if let info = note.userInfo, let partnerId = info["partnerId"] as? String {
                Task { await self.incrementUnread(for: partnerId) }
            }
        }
    }
    
    // MARK: - Load Conversations
    func loadConversations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let convs = try await MessageService.shared.getConversations()
            // Merge server conversations with local unread overrides so badge stays visible
            conversations = convs.map { conv in
                let pid = conv.user.id
                let serverCount = conv.unreadCount ?? 0
                let override = localUnreadOverrides[pid] ?? 0
                let display = max(serverCount, override)
                return Conversation(user: conv.user, lastMessage: conv.lastMessage, unreadCount: display)
            }
            print("🛰 ChatViewModel: loaded \(conversations.count) conversations")
            for c in conversations {
                print("  - conv user=\(c.user.name) id=\(c.user.id) unread=\(c.unreadCount ?? 0)")
            }
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
            // Persist last-seen message id for this partner so future starts know we've seen up to this message
            if let last = messages.last {
                // Use MessagePoller API to update both persistent and in-memory caches
                MessagePoller.shared.markConversationSeen(partnerId: userId, messageId: last.id)
            } else {
                MessagePoller.shared.markConversationSeen(partnerId: userId, messageId: nil)
            }
            // Clear local unread override for this partner since user opened the chat
            localUnreadOverrides.removeValue(forKey: userId)
            postLocalTotal()
            // Reload conversations to sync with server and remove badge
            Task { await loadConversations() }
            NotificationCenter.default.post(name: NSNotification.Name("NewMessageReceived"), object: nil)
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
            NotificationCenter.default.post(name: NSNotification.Name("NewMessageReceived"), object: nil)
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
            // For trip chats, reload conversations to sync read state
            Task { await loadConversations() }
            NotificationCenter.default.post(name: NSNotification.Name("NewMessageReceived"), object: nil)
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
            NotificationCenter.default.post(name: NSNotification.Name("NewMessageReceived"), object: nil)
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

    private func incrementUnread(for partnerId: String) async {
        // Increment local override for partner to keep badge visible until user opens chat
        let current = localUnreadOverrides[partnerId] ?? 0
        localUnreadOverrides[partnerId] = current + 1

        // Reflect override in the in-memory conversations if present
        if let idx = conversations.firstIndex(where: { $0.user.id == partnerId }) {
            var conv = conversations[idx]
            let serverCount = conv.unreadCount ?? 0
            let newCount = max(serverCount, localUnreadOverrides[partnerId] ?? 0)
            conv = Conversation(user: conv.user, lastMessage: conv.lastMessage, unreadCount: newCount)
            await MainActor.run {
                conversations[idx] = conv
            }
        } else {
            // If not found, reload conversations to pick it up (merge will apply override)
            await loadConversations()
        }
        postLocalTotal()
    }

    private func postLocalTotal() {
        let total = localUnreadOverrides.values.reduce(0, +)
        print("🔔 ChatViewModel: localOverrideTotal=\(total) overrides=\(localUnreadOverrides)")
        NotificationCenter.default.post(name: NSNotification.Name("LocalUnreadTotalChanged"), object: nil, userInfo: ["localTotal": total])
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

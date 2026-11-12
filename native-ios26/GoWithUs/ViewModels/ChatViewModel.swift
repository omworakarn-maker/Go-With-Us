import Foundation
import Combine
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    // List of conversations
    @Published var conversations: [Conversation] = []
    @Published var joinedTripChats: [Trip] = []

    private static var cachedRoomMessages: [String: [Message]] = [:]
    private static var dirtyRooms: Set<String> = []
    private var roomKey: String?
    private var roomUpdates: AnyCancellable?
    private var inboxUpdates: AnyCancellable?

    private func key(_ kind: String, _ id: String) -> String {
        "\(currentUserId ?? ""):\(kind):\(id)"
    }

    private func restoreRoom(_ key: String) -> Bool {
        roomKey = key
        if Self.cachedRoomMessages[key] == nil,
           let stored = ChatHistoryStore.shared.load(key: key) {
            Self.cachedRoomMessages[key] = stored
            Self.dirtyRooms.insert(key)
        }
        guard let saved = Self.cachedRoomMessages[key] else { return false }
        messages = saved
        lastMessageCount = saved.count
        return true
    }

    private func saveRoom() {
        guard let roomKey else { return }
        Self.cachedRoomMessages[roomKey] = messages
        ChatHistoryStore.shared.save(messages, key: roomKey)
    }

    func receiveMessage(_ message: Message) {
        guard !messages.contains(where: { $0.id == message.id }) else { return }
        messages.append(message)
        lastMessageCount = messages.count
        saveRoom()
    }

    // Active chat messages
    @Published var messages: [Message] = []

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var mutualMatches: [MatchUser] = []

    // Track last message count for detecting new messages
    private var lastMessageCount = 0
    // Static cache so it survives view destruction on tab switch
    private static var lastLoaded: Date? = nil
    private static var cachedConversations: [Conversation] = []
    private static var cachedMutualMatches: [MatchUser] = []
    private static var cachedJoinedTripChats: [Trip] = []

    static func invalidateCache() {
        lastLoaded = nil
        cachedConversations = []
        cachedMutualMatches = []
        cachedJoinedTripChats = []
        cachedRoomMessages = [:]
        dirtyRooms = []
    }

    // Local overrides to keep unread badges visible until user reads
    private var localUnreadOverrides: [String: Int] = [:]

    // Current User ID
    private var currentUserId: String? {
        return AuthService.shared.getCurrentUserId()
    }

    // MARK: - Load Initial Data (Concurrent)
    func loadInitialData(force: Bool = false) async {
        guard !AppRuntime.isRunningForPreview else {
            isLoading = false
            return
        }

        // Cache for 3 minutes (180 seconds)
        if !force, let lastLoaded = Self.lastLoaded, Date().timeIntervalSince(lastLoaded) < 180, (!conversations.isEmpty || !joinedTripChats.isEmpty || !mutualMatches.isEmpty) {
            return // Skip reloading if recently loaded
        }

        isLoading = true
        errorMessage = nil

        async let fetchConversations: () = loadConversationsInternal()
        async let fetchMutualMatches: () = loadMutualMatchesInternal()
        async let fetchTripChats: () = loadJoinedTripChatsInternal()

        _ = await (fetchConversations, fetchMutualMatches, fetchTripChats)

        Self.lastLoaded = Date()
        isLoading = false
    }

    // MARK: - Load Mutual Matches
    func loadMutualMatches() async {
        guard !AppRuntime.isRunningForPreview else { return }
        await loadMutualMatchesInternal()
    }

    private func loadMutualMatchesInternal() async {
        do {
            let response = try await MatchService.shared.getMutualMatches()
            await MainActor.run {
                self.mutualMatches = response.matches
                Self.cachedMutualMatches = response.matches
            }
        } catch {
            print("Failed to fetch mutual matches in ChatViewModel: \(error)")
        }
    }

    private var conversationUpdates: AnyCancellable?

    init() {
        // Load from static cache instantly
        self.conversations = Self.cachedConversations
        self.mutualMatches = Self.cachedMutualMatches
        self.joinedTripChats = Self.cachedJoinedTripChats

        inboxUpdates = NotificationCenter.default.publisher(for: .init("ConversationsUpdated"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] note in
                guard let self, let updated = note.userInfo?["conversations"] as? [Conversation] else { return }
                self.conversations = updated
                Self.cachedConversations = updated
                for conversation in updated {
                    let key = self.key("person", conversation.user.id)
                    if let cached = Self.cachedRoomMessages[key], cached.last?.id != conversation.lastMessage.id {
                        Self.dirtyRooms.insert(key)
                    }
                }
            }
        roomUpdates = NotificationCenter.default.publisher(for: .init("WebSocketNewMessage"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] note in
                guard let self, let message = note.userInfo?["message"] as? Message else { return }
                let key: String
                if let tripId = message.tripId { key = self.key("trip", tripId) }
                else {
                    let partnerId = message.senderId == self.currentUserId ? message.recipientId : message.senderId
                    guard let partnerId else { return }
                    key = self.key("person", partnerId)
                }
                Self.dirtyRooms.insert(key)
                if var cached = Self.cachedRoomMessages[key], !cached.contains(where: { $0.id == message.id }) {
                    cached.append(message)
                    Self.cachedRoomMessages[key] = cached
                }
            }

        // Subscribe once to conversation new-message events
        conversationUpdates = NotificationCenter.default.publisher(for: NSNotification.Name("ConversationNewMessage"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] note in
                guard let self else { return }
                if let info = note.userInfo, let partnerId = info["partnerId"] as? String {
                    Task { await self.incrementUnread(for: partnerId) }
                }
            }
    }

    private func loadJoinedTripChatsInternal() async {
        guard let userId = currentUserId else { return }

        do {
            let trips = try await TripService.shared.getAllTrips(participantId: userId)
            let joined = trips.filter { trip in
                trip.participants?.contains {
                    $0.userId == userId && $0.status == "going"
                } == true
            }
            joinedTripChats = joined
            Self.cachedJoinedTripChats = joined
        } catch {
            print("Failed to fetch joined trip chats: \(error)")
        }
    }

    func includeJoinedTrip(_ trip: Trip) {
        joinedTripChats.removeAll { $0.id == trip.id }
        joinedTripChats.insert(trip, at: 0)
        Self.cachedJoinedTripChats = joinedTripChats
    }

    func removeTripChat(id: String) {
        joinedTripChats.removeAll { $0.id == id }
        Self.cachedJoinedTripChats = joinedTripChats
    }

    // MARK: - Load Conversations
    func loadConversations() async {
        guard !AppRuntime.isRunningForPreview else {
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil
        await loadConversationsInternal()
        isLoading = false
    }

    private func loadConversationsInternal() async {
        do {
            let convs = try await MessageService.shared.getConversations()
            // Merge server conversations with local unread overrides so badge stays visible
            let mappedConvs = convs.map { conv in
                let pid = conv.user.id
                let serverCount = conv.unreadCount ?? 0
                let override = localUnreadOverrides[pid] ?? 0
                let display = max(serverCount, override)
                return Conversation(user: conv.user, lastMessage: conv.lastMessage, unreadCount: display)
            }
            await MainActor.run {
                self.conversations = mappedConvs
                Self.cachedConversations = mappedConvs
            }
            print("🛰 ChatViewModel: loaded \(mappedConvs.count) conversations")
            for c in mappedConvs {
                print("  - conv user=\(c.user.name) id=\(c.user.id) unread=\(c.unreadCount ?? 0)")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Load Private Messages
    func loadPrivateMessages(userId: String) async {
        let cacheKey = key("person", userId)
        let restored = restoreRoom(cacheKey)
        if restored && !Self.dirtyRooms.contains(cacheKey) { return }
        defer {
            if errorMessage == nil {
                saveRoom()
                Self.dirtyRooms.remove(cacheKey)
            }
        }
        isLoading = !restored
        errorMessage = nil
        if !restored { messages = [] } // Clear previous messages

        do {
            let knownIDs = Set(messages.map(\.id))
            let received = try await MessageService.shared.getPrivateMessages(userId: userId)
            messages = ChatMessageTimeline.merge(received, with: messages, knownIDs: knownIDs)
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

            // Optimistically clear unread count for this conversation so badge disappears immediately
            if let idx = conversations.firstIndex(where: { $0.user.id == userId }) {
                var conv = conversations[idx]
                conv = Conversation(user: conv.user, lastMessage: conv.lastMessage, unreadCount: 0)
                conversations[idx] = conv
            }

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
    func sendPrivateMessage(userId: String, content: String, imageUrl: String? = nil) async {
        guard !content.isEmpty || imageUrl != nil else { return }
        roomKey = key("person", userId)
        let localID = "local-" + UUID().uuidString
        var pending = Message(id: localID, content: content, senderId: currentUserId ?? "",
                              recipientId: userId, tripId: nil,
                              createdAt: Date(), sender: nil, recipient: nil, imageUrl: imageUrl)
        pending.localID = localID
        pending.deliveryState = .sending
        messages.append(pending)
        saveRoom()
        await deliverMessage(localID: localID)
    }

    // MARK: - Load Trip Messages (Group Chat)
    func loadTripMessages(tripId: String) async {
        let cacheKey = key("trip", tripId)
        let restored = restoreRoom(cacheKey)
        if restored && !Self.dirtyRooms.contains(cacheKey) { return }
        defer {
            if errorMessage == nil {
                saveRoom()
                Self.dirtyRooms.remove(cacheKey)
            }
        }
        isLoading = !restored
        errorMessage = nil
        if !restored { messages = [] }

        do {
            let knownIDs = Set(messages.map(\.id))
            let received = try await MessageService.shared.getTripMessages(tripId: tripId)
            messages = ChatMessageTimeline.merge(received, with: messages, knownIDs: knownIDs)
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
    func sendTripMessage(tripId: String, content: String, imageUrl: String? = nil) async {
        guard !content.isEmpty || imageUrl != nil else { return }
        roomKey = key("trip", tripId)
        let localID = "local-" + UUID().uuidString
        var pending = Message(id: localID, content: content, senderId: currentUserId ?? "",
                              recipientId: nil, tripId: tripId,
                              createdAt: Date(), sender: nil, recipient: nil, imageUrl: imageUrl)
        pending.localID = localID
        pending.deliveryState = .sending
        messages.append(pending)
        saveRoom()
        await deliverMessage(localID: localID)
    }

    private func deliverMessage(localID: String) async {
        guard let pending = messages.first(where: { $0.displayID == localID }) else { return }
        defer { saveRoom() }
        do {
            let server: Message
            if let tripId = pending.tripId {
                server = try await MessageService.shared.sendTripMessage(tripId: tripId, content: pending.content, imageUrl: pending.imageUrl)
            } else if let partnerId = pending.recipientId {
                server = try await MessageService.shared.sendPrivateMessage(userId: partnerId, content: pending.content, imageUrl: pending.imageUrl)
            } else { return }
            messages = ChatMessageTimeline.acknowledge(server, replacing: localID, in: messages)
            NotificationCenter.default.post(name: NSNotification.Name("NewMessageReceived"), object: nil)
        } catch {
            if let index = messages.firstIndex(where: { $0.displayID == localID }) {
                messages[index].deliveryState = .failed
            }
            errorMessage = error.localizedDescription
        }
    }

    func retryMessage(_ message: Message) {
        guard message.deliveryState == .failed,
              let index = messages.firstIndex(where: { $0.displayID == message.displayID }) else { return }
        messages[index].deliveryState = .sending
        Task { await deliverMessage(localID: message.displayID) }
    }

    func deleteMessage(_ message: Message) async {
        defer { saveRoom() }
        do {
            try await MessageService.shared.deleteMessage(messageId: message.id)
            messages.removeAll { $0.id == message.id }
            lastMessageCount = messages.count // Update lastMessageCount so polling doesn't break
            NotificationCenter.default.post(name: NSNotification.Name("NewMessageReceived"), object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete Conversation
    func deleteConversation(at offsets: IndexSet) {
        // Optimistic update
        let idsToDelete = offsets.map { conversations[$0].user.id }
        conversations.remove(atOffsets: offsets)

        Task {
            for id in idsToDelete {
                do {
                    try await MessageService.shared.deleteConversation(userId: id)
                } catch {
                    print("Failed to delete conversation: \(error)")
                }
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
        roomKey = key("person", userId)
        defer { saveRoom() }
        // Silent refresh without showing loading state
        do {
            let knownIDs = Set(messages.map(\.id))
            let newMessages = try await MessageService.shared.getPrivateMessages(userId: userId)
            Self.dirtyRooms.remove(key("person", userId))
            MessagePoller.shared.markConversationSeen(partnerId: userId, messageId: newMessages.last?.id)
            let merged = ChatMessageTimeline.merge(newMessages, with: messages, knownIDs: knownIDs)
            if merged != messages {
                messages = merged
                lastMessageCount = newMessages.count
            }
        } catch {
            // Silently fail for polling
        }
    }

    func refreshTripMessages(tripId: String) async {
        roomKey = key("trip", tripId)
        defer { saveRoom() }
        // Silent refresh without showing loading state
        do {
            let knownIDs = Set(messages.map(\.id))
            let newMessages = try await MessageService.shared.getTripMessages(tripId: tripId)
            Self.dirtyRooms.remove(key("trip", tripId))
            let merged = ChatMessageTimeline.merge(newMessages, with: messages, knownIDs: knownIDs)
            if merged != messages {
                messages = merged
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

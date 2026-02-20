import SwiftUI

struct ChatDetailView: View {
    @StateObject private var viewModel = ChatViewModel()
    let chatTitle: String
    let tripId: String? // If set, it's a group chat
    let partnerId: String? // If set, it's a private chat
    @State private var messageText = ""
    @State private var pollingTask: Task<Void, Never>?
    @State private var showPartnerProfile = false
    @State private var partnerUser: User? = nil
    @Environment(\.dismiss) private var dismiss
    
    init(chatTitle: String, tripId: String? = nil, partnerId: String? = nil, initialPartnerUser: User? = nil) {
        self.chatTitle = chatTitle
        self.tripId = tripId
        self.partnerId = partnerId
        self._partnerUser = State(initialValue: initialPartnerUser)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.adaptiveText)
                }
                
                // Profile avatar + name (tappable for private chat)
                if partnerId != nil {
                    Button(action: {
                        if partnerUser != nil {
                            showPartnerProfile = true
                        } else if let pid = partnerId {
                            // Create minimal user from what we have
                            partnerUser = User(
                                id: pid,
                                name: chatTitle.isEmpty ? "ผู้ใช้" : chatTitle,
                                email: ""
                            )
                            showPartnerProfile = true
                        }
                    }) {
                        HStack(spacing: 10) {
                            UserAvatarView(user: partnerUser, size: 36)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(chatTitle)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.adaptiveText)
                                    .lineLimit(1)
                                
                                Text("ดูโปรไฟล์")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.appPrimary)
                            }
                        }
                    }
                } else {
                    // Group chat — just show title
                    Text(chatTitle.isEmpty ? "แชทกลุ่ม" : chatTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.adaptiveText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Profile icon button (for private chats)
                if partnerId != nil {
                    Button(action: {
                        if partnerUser != nil {
                            showPartnerProfile = true
                        } else if let pid = partnerId {
                            partnerUser = User(
                                id: pid,
                                name: chatTitle.isEmpty ? "ผู้ใช้" : chatTitle,
                                email: ""
                            )
                            showPartnerProfile = true
                        }
                    }) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.appPrimary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.adaptiveBackground)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.08)),
                alignment: .bottom
            )
            
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                isCurrentUser: viewModel.isFromCurrentUser(message: message),
                                onTapAvatar: {
                                    // Tap on avatar to view sender profile
                                    if let sender = message.sender,
                                       !viewModel.isFromCurrentUser(message: message) {
                                        partnerUser = User(
                                            id: sender.id,
                                            name: sender.name,
                                            email: sender.email
                                        )
                                        showPartnerProfile = true
                                    }
                                }
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                    .id("Bottom")
                }
                .onChange(of: viewModel.messages) { _, _ in
                    withAnimation {
                        proxy.scrollTo("Bottom", anchor: .bottom)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .background(Color(UIColor.systemGroupedBackground))
            
            // Input Bar
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    TextField("พิมพ์ข้อความ...", text: $messageText)
                        .padding(12)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(24)

                    Button(action: {
                        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !content.isEmpty else { return }
                        messageText = ""
                        Task { await sendMessageWithContent(content) }
                    }) {
                        Circle()
                            .fill(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : Color.adaptiveText)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .white.opacity(0.5) : Color.adaptiveBackground)
                                    .offset(x: -2, y: 2)
                            )
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(12)
                .background(Color.adaptiveBackground)
            }
            .background(Color.adaptiveBackground)
        }
        .navigationBarHidden(true)
        .hideTabBar(true)
        .onAppear {
            // Initial load
            if let tripId = tripId {
                Task { await viewModel.loadTripMessages(tripId: tripId) }
            } else if let partnerId = partnerId {
                Task { await viewModel.loadPrivateMessages(userId: partnerId) }
            }
            
            // Fetch partner profile if it's a private chat
            if let pid = partnerId {
                Task {
                    if let user = try? await AuthService.shared.fetchPublicProfile(userId: pid) {
                        partnerUser = user
                    }
                }
            }
            
            // Start polling for new messages every 2.5 seconds
            pollingTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    
                    if let tripId = tripId {
                        await viewModel.refreshTripMessages(tripId: tripId)
                    } else if let partnerId = partnerId {
                        await viewModel.refreshPrivateMessages(userId: partnerId)
                    }
                }
            }
        }
        .onDisappear {
            pollingTask?.cancel()
            pollingTask = nil
        }
        .sheet(isPresented: $showPartnerProfile) {
            if let user = partnerUser {
                UserProfileView(user: user)
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let content = messageText
        messageText = ""
        
        Task {
            if let tripId = tripId {
                await viewModel.sendTripMessage(tripId: tripId, content: content)
            } else if let partnerId = partnerId {
                await viewModel.sendPrivateMessage(userId: partnerId, content: content)
            }
        }
    }

    private func sendMessageWithContent(_ content: String) async {
        if let tripId = tripId {
            await viewModel.sendTripMessage(tripId: tripId, content: content)
        } else if let partnerId = partnerId {
            await viewModel.sendPrivateMessage(userId: partnerId, content: content)
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    var onTapAvatar: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isCurrentUser {
                // Sender Avatar — tappable to view profile
                Button(action: { onTapAvatar?() }) {
                    let senderUser = message.sender.map { chatUser in
                        User(id: chatUser.id, name: chatUser.name, email: chatUser.email, profileImage: chatUser.profileImage ?? chatUser.avatarUrl)
                    }
                    UserAvatarView(user: senderUser, size: 32)
                }
            } else {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    // Sender name — tappable to view profile
                    Button(action: { onTapAvatar?() }) {
                        Text(message.sender?.name ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.appPrimary)
                            .padding(.leading, 4)
                    }
                }
                
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        isCurrentUser ?
                        AnyShapeStyle(Color.adaptiveText) :
                            AnyShapeStyle(Color.adaptiveCardBackground)
                    )
                    .foregroundColor(isCurrentUser ? Color.adaptiveBackground : .adaptiveText)
                    .clipShape(
                        RoundedCorner(
                            radius: 20,
                            corners: isCurrentUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight]
                        )
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
            }
            
            if !isCurrentUser {
                Spacer()
            } else {
                let senderUser = message.sender.map { chatUser in
                    User(id: chatUser.id, name: chatUser.name, email: chatUser.email, profileImage: chatUser.profileImage ?? chatUser.avatarUrl)
                }
                UserAvatarView(user: senderUser, size: 32)
            }
        }
    }
}

// Helper for specific corner rounding


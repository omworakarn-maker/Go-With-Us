import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var selectedConversation: Conversation? = nil
    @State private var selectedPartnerId: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.conversations.isEmpty {
                    ProgressView()
                        .tint(.adaptiveText)
                } else if viewModel.conversations.isEmpty && viewModel.mutualMatches.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "message")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("ยังไม่มีการสนทนา")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        // NEW MATCHES SECTION
                        if !viewModel.mutualMatches.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("เพื่อนใหม่ที่แมตช์กัน")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.adaptiveSecondaryText)
                                    .padding(.horizontal, 16)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 20) {
                                        ForEach(viewModel.mutualMatches) { match in
                                            Button(action: {
                                                selectedPartnerId = match.id
                                            }) {
                                                VStack(spacing: 8) {
                                                    UserAvatarView(user: match.toUser(), size: 60)
                                                        .overlay(
                                                            Circle()
                                                                .stroke(Color.rainbowGradient, lineWidth: 2)
                                                        )
                                                    Text(match.name)
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(.adaptiveText)
                                                        .lineLimit(1)
                                                        .frame(width: 70)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.vertical, 16)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }

                        // CONVERSATIONS SECTION
                        Section {
                            ForEach(viewModel.conversations) { conversation in
                                Button(action: {
                                    selectedConversation = conversation
                                }) {
                                    ConversationRow(conversation: conversation)
                                }
                            }
                            .onDelete(perform: viewModel.deleteConversation)
                        } header: {
                            if !viewModel.conversations.isEmpty && !viewModel.mutualMatches.isEmpty {
                                Text("ข้อความล่าสุด")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.adaptiveSecondaryText)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.loadInitialData(force: true)
                    }
                }
            }
            // Hidden navigation link activated when a conversation is set
            NavigationLink(destination: Group {
                if let conv = selectedConversation {
                    let partnerUser = User(id: conv.user.id, name: conv.user.name, email: conv.user.email, profileImage: conv.user.profileImage ?? conv.user.avatarUrl)
                    ChatDetailView(chatTitle: conv.user.name, tripId: nil, partnerId: conv.user.id, initialPartnerUser: partnerUser)
                } else if let pid = selectedPartnerId {
                    ChatDetailView(chatTitle: "", tripId: nil, partnerId: pid)
                } else {
                    EmptyView()
                }
            }, isActive: Binding(get: { selectedConversation != nil || selectedPartnerId != nil }, set: { active in
                if !active {
                    selectedConversation = nil
                    selectedPartnerId = nil
                }
            })) {
                EmptyView()
            }
            .padding(.bottom, 80) // Space for TabBar
            .navigationTitle("ข้อความ")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task { await viewModel.loadInitialData() }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewNotificationReceived"))) { _ in
                Task { await viewModel.loadInitialData() }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewMessageReceived"))) { _ in
                Task { await viewModel.loadConversations() }
            }
            .onAppear {
                print("👀 ChatView appeared - subscribing to message updates")
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenChatDetail"))) { note in
                if let info = note.userInfo {
                    if let partnerId = info["partnerId"] as? String {
                        // open partner chat
                        selectedPartnerId = partnerId
                    } else if let tripId = info["tripId"] as? String {
                        // If notification refers to a trip chat, attempt to map to a conversation partner later
                        // For now open chat tab and let user select
                        // Could be improved by resolving trip->conversation on server
                    }
                }
            }
            .navigationDestination(for: String.self) { partnerId in
                ChatDetailView(chatTitle: "", tripId: nil, partnerId: partnerId)
            }
            .hideTabBar(false)
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            let user = User(id: conversation.user.id, name: conversation.user.name, email: conversation.user.email, profileImage: conversation.user.profileImage ?? conversation.user.avatarUrl)
            UserAvatarView(user: user, size: 48)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.user.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.adaptiveText)
                
                Text(conversation.lastMessage.content.isEmpty && conversation.lastMessage.imageUrl != nil ? "รูปภาพ" : conversation.lastMessage.content)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 8) {
                    Text(timeAgoDisplay(date: conversation.lastMessage.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)

                    // Unread badge: circular near the time
                    if let unreadCount = conversation.unreadCount, unreadCount > 0 {
                        if unreadCount < 10 {
                            Text("\(unreadCount)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(Color.red)
                                .clipShape(Circle())
                                .transition(.scale)
                        } else {
                            let display = unreadCount > 99 ? "99+" : "\(unreadCount)"
                            Text(display)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red)
                                .clipShape(Capsule())
                                .transition(.scale)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // Simple helper for time display
    func timeAgoDisplay(date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ChatView()
}

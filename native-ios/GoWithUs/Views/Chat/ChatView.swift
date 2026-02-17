import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var selectedPartnerId: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.conversations.isEmpty {
                    ProgressView()
                        .tint(.adaptiveText)
                } else if viewModel.conversations.isEmpty {
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
                        ForEach(viewModel.conversations) { conversation in
                            Button(action: {
                                selectedPartnerId = conversation.user.id
                            }) {
                                ConversationRow(conversation: conversation)
                            }
                        }
                        .onDelete(perform: viewModel.deleteConversation)
                    }
                    .listStyle(.plain)
                }
            }
            // Hidden navigation link activated when a partnerId is set
            NavigationLink(destination: Group {
                if let pid = selectedPartnerId {
                    ChatDetailView(chatTitle: "", tripId: nil, partnerId: pid)
                } else {
                    EmptyView()
                }
            }, isActive: Binding(get: { selectedPartnerId != nil }, set: { active in
                if !active { selectedPartnerId = nil }
            })) {
                EmptyView()
            }
            .padding(.bottom, 80) // Space for TabBar
            .navigationTitle("ข้อความ")
            .onAppear {
                Task { await viewModel.loadConversations() }
            }

            .refreshable {
                await viewModel.loadConversations()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewNotificationReceived"))) { _ in
                Task { await viewModel.loadConversations() }
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
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(conversation.user.name.prefix(1)))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.adaptiveText)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.user.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.adaptiveText)
                
                Text(conversation.lastMessage.content)
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

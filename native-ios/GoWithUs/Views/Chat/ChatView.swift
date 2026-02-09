import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.conversations.isEmpty {
                    ProgressView()
                        .tint(.black)
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
                            NavigationLink(destination: ChatDetailView(
                                chatTitle: conversation.user.name,
                                tripId: nil,
                                partnerId: conversation.user.id
                            )) {
                                ConversationRow(conversation: conversation)
                            }
                        }
                        .onDelete(perform: viewModel.deleteConversation)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("ข้อความ")
            .onAppear {
                Task { await viewModel.loadConversations() }
            }
            .refreshable {
                await viewModel.loadConversations()
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
                        .foregroundColor(.black)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.user.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    Spacer()
                    Text(timeAgoDisplay(date: conversation.lastMessage.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Unread badge
                    if let unreadCount = conversation.unreadCount, unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
                
                Text(conversation.lastMessage.content)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
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

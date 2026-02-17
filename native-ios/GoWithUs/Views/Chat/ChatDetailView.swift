import SwiftUI

struct ChatDetailView: View {
    @StateObject private var viewModel = ChatViewModel()
    let chatTitle: String
    let tripId: String? // If set, it's a group chat
    let partnerId: String? // If set, it's a private chat
    @State private var messageText = ""
    @State private var pollingTask: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                }
                
                Text(chatTitle)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding()
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.1)),
                alignment: .bottom
            )
            
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message, isCurrentUser: viewModel.isFromCurrentUser(message: message))
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
            
            // Input Bar (directly inline for pixel-perfect keyboard fit)
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    TextField("พิมพ์ข้อความ...", text: $messageText)
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(24)

                    Button(action: {
                        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !content.isEmpty else { return }
                        messageText = ""
                        Task { await sendMessageWithContent(content) }
                    }) {
                        Circle()
                            .fill(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : Color.black)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .offset(x: -2, y: 2)
                            )
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(12)
                .background(Color.white)
            }
            .background(Color.white)
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
            
            // Start polling for new messages every 2.5 seconds
            pollingTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
                    
                    if let tripId = tripId {
                        await viewModel.refreshTripMessages(tripId: tripId)
                    } else if let partnerId = partnerId {
                        await viewModel.refreshPrivateMessages(userId: partnerId)
                    }
                }
            }
        }
        .onDisappear {
            // Cancel polling when leaving chat
            pollingTask?.cancel()
            pollingTask = nil
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

    // Helper used by accessory send (keeps previous behavior)
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
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isCurrentUser {
                // Sender Avatar
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(message.sender?.name.prefix(1) ?? "?"))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
            } else {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.sender?.name ?? "Unknown")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                }
                
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        isCurrentUser ?
                        AnyShapeStyle(Color.black) :
                            AnyShapeStyle(Color.white)
                    )
                    .foregroundColor(isCurrentUser ? .white : .black)
                    .clipShape(
                        RoundedCorner(
                            radius: 20,
                            corners: isCurrentUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight]
                        )
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
}

// Helper for specific corner rounding


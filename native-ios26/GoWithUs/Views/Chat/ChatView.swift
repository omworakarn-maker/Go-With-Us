import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var selectedConversation: Conversation? = nil
    @State private var selectedPartnerId: String? = nil
    @State private var selectedTrip: Trip? = nil

    private var inboxItems: [ChatInboxItem] {
        (viewModel.conversations.map(ChatInboxItem.person) +
         viewModel.joinedTripChats.map(ChatInboxItem.trip))
            .sorted {
                if $0.date == $1.date { return $0.id < $1.id }
                return $0.date > $1.date
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.conversations.isEmpty {
                    ProgressView()
                        .tint(.appPrimary)
                } else if viewModel.conversations.isEmpty && viewModel.mutualMatches.isEmpty && viewModel.joinedTripChats.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "message")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text(SettingsManager.shared.text(thai: "ยังไม่มีการสนทนา", english: "No conversations yet"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        // NEW MATCHES SECTION
                        if !viewModel.mutualMatches.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(SettingsManager.shared.text(thai: "เพื่อนใหม่ที่แมตช์กัน", english: "New matches"))
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

                        ForEach(inboxItems) { item in
                            switch item {
                            case .trip(let trip):
                                Button { selectedTrip = trip } label: {
                                    TripChatRow(trip: trip)
                                }
                            case .person(let conversation):
                                Button { selectedConversation = conversation } label: {
                                    ConversationRow(conversation: conversation)
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        if let index = viewModel.conversations.firstIndex(where: { $0.id == conversation.id }) {
                                            viewModel.deleteConversation(at: IndexSet(integer: index))
                                        }
                                    } label: {
                                        Label(tr("ลบ", "Delete"), systemImage: "trash")
                                    }
                                }
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
                    let partnerUser = User(id: conv.user.id, name: conv.user.name, username: conv.user.username, email: conv.user.email, profileImage: conv.user.profileImage ?? conv.user.avatarUrl)
                    ChatDetailView(chatTitle: conv.user.name, tripId: nil, partnerId: conv.user.id, initialPartnerUser: partnerUser)
                } else if let pid = selectedPartnerId {
                    ChatDetailView(chatTitle: "", tripId: nil, partnerId: pid)
                } else if let trip = selectedTrip {
                    ChatDetailView(chatTitle: trip.title, tripId: trip.id, partnerId: nil)
                } else {
                    EmptyView()
                }
            }, isActive: Binding(get: { selectedConversation != nil || selectedPartnerId != nil || selectedTrip != nil }, set: { active in
                if !active {
                    selectedConversation = nil
                    selectedPartnerId = nil
                    selectedTrip = nil
                }
            })) {
                EmptyView()
            }

            .navigationTitle(SettingsManager.shared.text(thai: "ข้อความ", english: "Messages"))
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
            .onReceive(NotificationCenter.default.publisher(for: .init("TripJoined"))) { note in
                if let trip = note.object as? Trip {
                    viewModel.includeJoinedTrip(trip)
                } else {
                    Task { await viewModel.loadInitialData(force: true) }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("TripLeft"))) { note in
                if let id = note.object as? String { viewModel.removeTripChat(id: id) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("TripDeleted"))) { note in
                if let id = note.object as? String { viewModel.removeTripChat(id: id) }
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
                        selectedTrip = viewModel.joinedTripChats.first { $0.id == tripId }
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

private enum ChatInboxItem: Identifiable {
    case person(Conversation)
    case trip(Trip)

    var id: String {
        switch self {
        case .person(let conversation): return "person:" + conversation.id
        case .trip(let trip): return "trip:" + trip.id
        }
    }

    var date: Date {
        switch self {
        case .person(let conversation): return conversation.lastMessage.createdAt
        case .trip(let trip): return trip.updatedAt ?? trip.createdAt ?? .distantPast
        }
    }
}

struct TripChatRow: View {
    let trip: Trip

    var body: some View {
        HStack(spacing: 16) {
            Group {
                if let imageUrl = trip.imageUrl, !imageUrl.isEmpty {
                    CustomAsyncImage(url: imageUrl, contentMode: .fill)
                } else {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.appPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.appPrimary.opacity(0.12))
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.adaptiveText)
                    .lineLimit(1)
                Text(trip.destination)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(.gray.opacity(0.6))
        }
        .padding(.vertical, 8)
    }
}

struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            let user = User(id: conversation.user.id, name: conversation.user.name, username: conversation.user.username, email: conversation.user.email, profileImage: conversation.user.profileImage ?? conversation.user.avatarUrl)
            UserAvatarView(user: user, size: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.user.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.adaptiveText)

                Text(conversation.lastMessage.content.isEmpty && conversation.lastMessage.imageUrl != nil ? tr("รูปภาพ", "Photo") : conversation.lastMessage.content)
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

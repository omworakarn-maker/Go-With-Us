import SwiftUI
import PhotosUI

struct ChatDetailView: View {
    @StateObject private var viewModel = ChatViewModel()
    let chatTitle: String
    let tripId: String? // If set, it's a group chat
    let partnerId: String? // If set, it's a private chat
    @State private var messageText = ""
    @State private var showPartnerProfile = false
    @State private var partnerUser: User? = nil
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var isSendingImage = false
    @State private var isChatVisible = false
    @Environment(\.dismiss) private var dismiss

    init(chatTitle: String, tripId: String? = nil, partnerId: String? = nil, initialPartnerUser: User? = nil, isModal: Bool = false) {
        self.isModal = isModal
        self.chatTitle = chatTitle
        self.tripId = tripId
        self.partnerId = partnerId
        self._partnerUser = State(initialValue: initialPartnerUser)
    }

    var isModal = false

    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages, id: \.displayID) { message in
                            if message.isSystem == true {
                                Text(message.content)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .id(message.displayID)
                            } else {
                            MessageBubble(
                                message: message,
                                isCurrentUser: viewModel.isFromCurrentUser(message: message),
                                onRetry: { viewModel.retryMessage(message) },
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
                            .id(message.displayID)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = message.content
                                    HapticManager.shared.notification(type: .success)
                                } label: {
                                    Label(tr("คัดลอกข้อความ", "Copy message"), systemImage: "doc.on.doc")
                                }

                                if viewModel.isFromCurrentUser(message: message), message.deliveryState != .sending, message.deliveryState != .failed {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteMessage(message)
                                        }
                                    } label: {
                                        Label(tr("ยกเลิกข้อความ", "Unsend message"), systemImage: "trash")
                                    }
                                }
                            }
                            }
                        }
                        Color.clear.frame(height: 1).id("ChatBottom")
                    }
                    .padding()
                }
                .refreshable {
                    if let tripId = tripId {
                        await viewModel.refreshTripMessages(tripId: tripId)
                    } else if let partnerId = partnerId {
                        await viewModel.refreshPrivateMessages(userId: partnerId)
                    }
                }
                .defaultScrollAnchor(.bottom)
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    Task { @MainActor in
                        await Task.yield()
                        proxy.scrollTo("ChatBottom", anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.messages.map(\.displayID)) { oldIDs, newIDs in
                    guard oldIDs.last != newIDs.last else { return }
                    Task { @MainActor in
                        await Task.yield()
                        withAnimation(.easeOut(duration: 0.22)) {
                            proxy.scrollTo("ChatBottom", anchor: .bottom)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                    Task { @MainActor in
                        await Task.yield()
                        withAnimation(.easeOut(duration: 0.22)) {
                            proxy.scrollTo("ChatBottom", anchor: .bottom)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .background(Color(UIColor.systemGroupedBackground))

            // Input Bar
            VStack(spacing: 0) {
                if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                    HStack {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                                .clipped()

                            Button(action: {
                                selectedImageData = nil
                                selectedItem = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .background(Color.white.clipShape(Circle()))
                            }
                            .offset(x: 8, y: -8)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }

                GlassEffectContainer(spacing: 10) {
                    HStack(alignment: .bottom, spacing: 10) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .frame(width: 22, height: 22)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .controlSize(.large)
                        .accessibilityLabel(tr("แนบรูปภาพ", "Attach photo"))
                        .disabled(isSendingImage)

                        TextField(tr("พิมพ์ข้อความ...", "Type a message…"), text: $messageText, axis: .vertical)
                            .lineLimit(1...5)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(minHeight: 48)
                            .foregroundStyle(Color.adaptiveText)
                            .appGlass(in: RoundedRectangle(cornerRadius: 25))

                        Button {
                            let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !isSendingImage, !content.isEmpty || selectedImageData != nil else { return }
                            SettingsManager.shared.triggerSelection()
                            messageText = ""
                            selectedItem = nil
                            let dataToSend = selectedImageData
                            selectedImageData = nil
                            Task {
                                await sendMessage(content: content, imageUrl: dataToSend?.base64EncodedString())
                            }
                        } label: {
                            ZStack {
                                if isSendingImage {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 20, weight: .semibold))
                                }
                            }
                            .frame(width: 22, height: 22)
                        }
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.circle)
                        .controlSize(.large)
                        .tint(.appSecondary)
                        .disabled(isSendingImage || (messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImageData == nil))
                        .accessibilityLabel(tr("ส่งข้อความ", "Send message"))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(Color(UIColor.systemGroupedBackground).opacity(0.35))
        }
        .navigationTitle(chatTitle.isEmpty ? tr("แชท", "Chat") : chatTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            if let tripId {
                ToolbarItem(placement: .principal) {
                    NavigationLink {
                        TripDetailView(tripId: tripId)
                    } label: {
                        HStack(spacing: 5) {
                            Text(chatTitle.isEmpty ? tr("แชททริป", "Trip chat") : chatTitle)
                                .font(.headline)
                                .lineLimit(1)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(Color.adaptiveText)
                    }
                    .accessibilityLabel(tr("ดูรายละเอียดทริป", "View trip details"))
                }
            }
            if isModal {
                ToolbarItem(placement: .topBarLeading) {
                    Button(tr("ปิด", "Close"), systemImage: "xmark") { dismiss() }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if let partnerId {
                    Button(tr("ดูโปรไฟล์", "View profile"), systemImage: "person.crop.circle") {
                        if partnerUser == nil {
                            partnerUser = User(id: partnerId, name: chatTitle.isEmpty ? tr("ผู้ใช้", "User") : chatTitle, email: "")
                        }
                        showPartnerProfile = true
                    }
                }
            }
        }
        .hideTabBar(true)
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task { await prepareImage(from: item) }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            guard isChatVisible else { return }
            Task {
                if let tripId { await viewModel.refreshTripMessages(tripId: tripId) }
                else if let partnerId { await viewModel.refreshPrivateMessages(userId: partnerId) }
            }
        }
        .onAppear {
            isChatVisible = true
            if let partnerId { viewModel.beginReadingPrivateChat(partnerID: partnerId) }
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
            // WebSocket automatically pushes new messages via NSNotification "WebSocketNewMessage"
            // No more polling required!
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WebSocketNewMessage"))) { notification in
            if let message = notification.userInfo?["message"] as? Message {
                // Ensure the message belongs to this chat before appending
                let isForThisChat = (tripId != nil && message.tripId == tripId) ||
                                    (tripId == nil && message.tripId == nil && partnerId != nil && (message.senderId == partnerId || message.recipientId == partnerId))

                if isChatVisible && UIApplication.shared.applicationState == .active &&
                    isForThisChat && !viewModel.messages.contains(where: { $0.id == message.id }) {
                    viewModel.receiveMessage(message)
                    Task {
                        if let tripId { await viewModel.refreshTripMessages(tripId: tripId) }
                        else if let partnerId { await viewModel.refreshPrivateMessages(userId: partnerId) }
                    }
                }
            }
        }
        .onDisappear {
            viewModel.endReadingPrivateChat()
            isChatVisible = false
        }
        .sheet(isPresented: $showPartnerProfile) {
            if let user = partnerUser {
                NavigationStack {
                    UserProfileView(user: user, isModal: true)
                }
            }
        }
    }

    private func sendMessage(content: String, imageUrl: String?) async {
        if let tripId = tripId {
            await viewModel.sendTripMessage(tripId: tripId, content: content, imageUrl: imageUrl)
        } else if let partnerId = partnerId {
            await viewModel.sendPrivateMessage(userId: partnerId, content: content, imageUrl: imageUrl)
        }
    }

    @MainActor
    private func prepareImage(from item: PhotosPickerItem) async {
        isSendingImage = true
        defer { isSendingImage = false }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let source = UIImage(data: data) else {
            selectedItem = nil
            return
        }

        let longestSide = max(source.size.width, source.size.height)
        let scale = min(1, 1400 / max(longestSide, 1))
        let size = CGSize(width: source.size.width * scale, height: source.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            source.draw(in: CGRect(origin: .zero, size: size))
        }
        selectedImageData = resized.jpegData(compressionQuality: 0.78)
        if selectedImageData == nil { selectedItem = nil }
    }
}

struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    var onRetry: (() -> Void)? = nil
    var onTapAvatar: (() -> Void)? = nil

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private var timeString: String {
        return Self.timeFormatter.string(from: message.createdAt)
    }

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

                // Time for current user (left of bubble)
                Text(timeString)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
                    .padding(.bottom, 4)
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


                if let base64String = message.imageUrl,
                   let data = Data(base64Encoded: base64String),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: 220)
                        .cornerRadius(12)
                        .padding(.horizontal, isCurrentUser ? 0 : 8)
                        .padding(.vertical, 4)
                }

                if !message.content.isEmpty {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            isCurrentUser ?
                            AnyShapeStyle(LinearGradient(gradient: Gradient(colors: [Color.appPrimary, Color.appPrimary.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)) :
                                AnyShapeStyle(Color.adaptiveCardBackground)
                        )
                        .foregroundColor(isCurrentUser ? .white : .adaptiveText)
                        .clipShape(
                            RoundedCorner(
                                radius: 20,
                                corners: isCurrentUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight]
                            )
                        )
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                }

                if isCurrentUser, message.isRead != true {
                    switch message.deliveryState {
                    case .sending:
                        Text(tr("กำลังส่ง", "Sending"))
                            .font(.caption2).foregroundStyle(.secondary)
                    case .sent:
                        Text(tr("ส่งแล้ว", "Sent"))
                            .font(.caption2).foregroundStyle(.secondary)
                    case .failed:
                        Button { onRetry?() } label: {
                            Label(tr("ส่งไม่สำเร็จ · ลองอีกครั้ง", "Failed · Retry"), systemImage: "exclamationmark.circle")
                                .font(.caption2)
                        }
                        .foregroundStyle(.red)
                    case nil:
                        EmptyView()
                    }
                }
            }

            if !isCurrentUser {
                // Time for other user (right of bubble)
                Text(timeString)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
                    .padding(.bottom, 4)

                Spacer()
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    // Current User Avatar
                    let senderUser = message.sender.map { chatUser in
                        User(id: chatUser.id, name: chatUser.name, email: chatUser.email, profileImage: chatUser.profileImage ?? chatUser.avatarUrl)
                    }
                    UserAvatarView(user: senderUser, size: 32)

                    // Read receipt
                    if message.isRead == true {
                        Text(tr("อ่านแล้ว", "Read"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.top, 2)
                    }
                }
            }
        }
    }
}

// Helper for specific corner rounding

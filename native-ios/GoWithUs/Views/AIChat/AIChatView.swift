import SwiftUI

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Binding var showSideMenu: Bool
    @State private var showCreateTrip = false
    @State private var isAutoCreating = false
    @State private var showAutoCreateSuccess = false
    @State private var sendTask: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        withAnimation {
                            showSideMenu.toggle()
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.adaptiveText)
                    }

                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text(SettingsManager.shared.localizedString(for: "ai_header"))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.adaptiveText)
                    }
                    
                    Spacer()
                    
                    // Clear chat
                    Button(action: {
                        viewModel.clearChat()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
                .padding()
                .background(Color.adaptiveBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                .zIndex(1)
                
                // Chat Area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                VStack(alignment: .leading, spacing: 10) {
                                    ChatMessageView(message: message)
                                    if !message.isUser, let draft = message.tripDraft {
                                        draftCard(draft)
                                            .padding(.leading, 36)
                                    }
                                }
                                .id(message.id)
                            }
                            
                            if viewModel.isLoading {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        TypingIndicatorView()
                                        Text(tr("กำลังคิดคำตอบ…", "Thinking…"))
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .id("TypingIndicator")
                            }
                            Color.clear.frame(height: 1).id("AIChatBottom")
                        }
                        .padding()
                    }
                    .onTapGesture {
                        hideKeyboard()
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onAppear { proxy.scrollTo("AIChatBottom", anchor: .bottom) }
                    .onChange(of: viewModel.messages.count) { _ in
                        Task { @MainActor in
                            await Task.yield()
                            withAnimation(.easeOut(duration: 0.22)) {
                                proxy.scrollTo("AIChatBottom", anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isLoading) { _ in
                        Task { @MainActor in
                            await Task.yield()
                            withAnimation(.easeOut(duration: 0.22)) {
                                proxy.scrollTo("AIChatBottom", anchor: .bottom)
                            }
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                        withAnimation(.easeOut(duration: 0.22)) {
                            proxy.scrollTo("AIChatBottom", anchor: .bottom)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .background(Color(UIColor.systemGroupedBackground))
                
                // Input Bar (directly inline)
                HStack(alignment: .bottom, spacing: 0) {
                    TextField(SettingsManager.shared.localizedString(for: "ai_input_placeholder"), text: $viewModel.inputText, axis: .vertical)
                        .lineLimit(1...5)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .foregroundColor(.adaptiveText)

                    if !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading {
                        Button(action: {
                            if viewModel.isLoading {
                                sendTask?.cancel()
                            } else {
                                sendTask = Task { await viewModel.sendMessage() }
                            }
                        }) {
                            if viewModel.isLoading {
                                Image(systemName: "stop.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.appPrimary)
                                    .frame(width: 34, height: 34)
                                    .padding(.trailing, 6)
                                    .padding(.bottom, 6)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color.appPrimary)
                                    .padding(.trailing, 6)
                                    .padding(.bottom, 4)
                                    .shadow(color: Color.appPrimary.opacity(0.3), radius: 3, x: 0, y: 2)
                            }
                        }
                        .accessibilityLabel(viewModel.isLoading ? tr("หยุดคำตอบ", "Stop response") : tr("ส่งข้อความ", "Send message"))
                    }
                }
                .background(Color.adaptiveCardBackground)
                .cornerRadius(22)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.adaptiveBackground)
            }
            .onDisappear { sendTask?.cancel() }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCreateTrip) {
                if let draft = viewModel.tripDraft {
                    CreateTripView(draft: draft)
                } else {
                    CreateTripView()
                }
            }
        }
        .alert(tr("สร้างทริปสำเร็จ! 🎉", "Trip created! 🎉"), isPresented: $showAutoCreateSuccess) {
            Button(tr("ตกลง", "OK"), role: .cancel) {}
        } message: {
            Text(tr("ทริปของคุณถูกสร้างแล้ว ไปดูได้ที่หน้าแรกเลย!", "Your trip has been created. View it on the Home screen!"))
        }
    }

    private func draftCard(_ draft: TripDraft) -> some View {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(SettingsManager.shared.localizedString(for: "ai_draft_ready"))
                                    .font(.headline)
                                    .foregroundColor(.adaptiveText)
                                Text(draft.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.appPrimary)
                            }
                            Spacer()
                            Image(systemName: "map.fill")
                                .foregroundStyle(Color.appPrimary)
                        }
                        
                        Text(draft.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let days = draft.itinerary, !days.isEmpty {
                            DisclosureGroup(tr("ดูแผนการเดินทาง", "View itinerary")) {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(days) { day in
                                        Text("\(tr("วันที่", "Day")) \(day.day)")
                                            .font(.subheadline.bold())
                                        ForEach(day.activities) { activity in
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text("\(activity.time)  \(activity.name)")
                                                    .font(.subheadline.weight(.medium))
                                                if !activity.location.isEmpty {
                                                    Text(activity.location).font(.caption).foregroundStyle(.secondary)
                                                }
                                                if !activity.description.isEmpty {
                                                    Text(activity.description).font(.caption).foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                            }
                            .font(.subheadline)
                            .tint(.appPrimary)
                        }

                        // Draft Details
                        VStack(spacing: 8) {
                            HStack(spacing: 16) {
                                DraftInfoPill(icon: "mappin", text: draft.destination, color: .appAccent)
                                DraftInfoPill(icon: "calendar", text: draft.endDate != nil ? "\(draft.startDate) → \(draft.endDate!)" : draft.startDate, color: .appPrimary)
                            }
                            HStack(spacing: 16) {
                                DraftInfoPill(icon: "banknote", text: "\(draft.budget) ฿", color: Color(hex: "#2ECC71"))
                                DraftInfoPill(icon: "person.2", text: "\(tr("สูงสุด", "Up to")) \(draft.maxParticipants) \(tr("คน", "people"))", color: .appSecondary)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            // Auto-create button
                            Button(action: {
                                autoCreateTrip(draft: draft)
                            }) {
                                HStack(spacing: 4) {
                                    if isAutoCreating {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(0.8)
                                    }
                                    Text(SettingsManager.shared.localizedString(for: "ai_create_now"))
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.appPrimary)
                                .cornerRadius(8)
                            }
                            .disabled(isAutoCreating)
                            
                            // Edit before creating
                            Button(action: {
                                viewModel.tripDraft = draft
                                showCreateTrip = true
                            }) {
                                Text(SettingsManager.shared.localizedString(for: "ai_edit_before"))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.adaptiveText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.adaptiveCardBackground)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .disabled(isAutoCreating)
                        }
                    }
                    .padding()
                    .background(Color.adaptiveCardBackground)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func autoCreateTrip(draft: TripDraft) {
        isAutoCreating = true
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.isLenient = false

        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let parsedStart = formatter.date(from: String(draft.startDate.prefix(10)))
        let startWasInvalidOrPast = parsedStart == nil || parsedStart! < today
        let start = startWasInvalidOrPast ? tomorrow : parsedStart!

        let parsedEnd = draft.endDate.flatMap { formatter.date(from: String($0.prefix(10))) }
        let end: Date? = {
            guard let parsedEnd else { return nil }
            if startWasInvalidOrPast, let parsedStart {
                let tripLength = max(0, calendar.dateComponents([.day], from: parsedStart, to: parsedEnd).day ?? 0)
                return calendar.date(byAdding: .day, value: tripLength, to: start)
            }
            return parsedEnd >= start ? parsedEnd : start
        }()
        
        // Append tags as hashtags to description
        let tagsString = (draft.tags ?? []).isEmpty ? "" : "\n" + (draft.tags ?? []).map { "#\($0)" }.joined(separator: " ")
        let fullDescription = draft.description + tagsString
        
        Task {
            do {
                // Synchronize the visible account with the owner encoded in the auth token.
                await authViewModel.loadCurrentUser()
                let createdTrip = try await TripService.shared.createTrip(
                    title: draft.title,
                    destination: draft.destination,
                    description: fullDescription,
                    startDate: start,
                    endDate: end,
                    budget: draft.budget,
                    budgetType: draft.budgetType,
                    maxParticipants: draft.maxParticipants,
                    category: draft.category,
                    interestTags: draft.interestTags ?? [],
                    isPublic: true,
                    itinerary: draft.itinerary,
                    activityStyle: draft.activityStyle,
                    timeOfDay: draft.timeOfDay
                )
                await MainActor.run {
                    isAutoCreating = false
                    viewModel.showDraftAlert = false
                    showAutoCreateSuccess = true
                    NotificationCenter.default.post(name: NSNotification.Name("TripCreated"), object: createdTrip)
                }
            } catch {
                await MainActor.run {
                    isAutoCreating = false
                    viewModel.messages.append(ChatMessage(content: "\(tr("เกิดข้อผิดพลาดในการสร้างทริป", "Unable to create trip")): \(error.localizedDescription)", isUser: false))
                }
            }
        }
    }
}

// MARK: - Draft Info Pill
struct DraftInfoPill: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.adaptiveText)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.08))
        .cornerRadius(8)
    }
}


struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.appPrimary, Color.appPrimary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight, .bottomLeft]))
                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        // Minimalist AI icon
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.appAccent, Color.appAccent.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        Text(message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.adaptiveCardBackground)
                            .foregroundColor(.adaptiveText)
                            .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight, .bottomRight]))
                            .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                    }
                }
                Spacer()
            }
        }
    }
}

@MainActor
class AIChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [] {
        didSet { saveMessages() }
    }
    @Published var inputText: String = ""
    @Published var isLoading = false
    
    private let chatStorageKey = "AIChatHistory"
    
    init() {
        loadMessages()
    }
    
    private func loadMessages() {
        if let data = UserDefaults.standard.data(forKey: chatStorageKey),
           let savedMessages = try? JSONDecoder().decode([ChatMessage].self, from: data),
           !savedMessages.isEmpty {
            self.messages = savedMessages.map { message in
                guard !message.isUser, message.content.contains("{") else { return message }
                let parsed = AITripResponse.parse(message.content)
                if let draft = parsed.draft { tripDraft = draft; showDraftAlert = true }
                return ChatMessage(id: message.id, content: parsed.message, isUser: false, timestamp: message.timestamp, draft: parsed.draft)
            }
        } else {
            self.messages = [ChatMessage(id: UUID(), content: SettingsManager.shared.localizedString(for: "ai_welcome_message"), isUser: false, timestamp: Date())]
        }
    }
    
    private func saveMessages() {
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: chatStorageKey)
        }
    }
    
    @Published var tripDraft: TripDraft?
    @Published var showDraftAlert = false
    
    func clearChat() {
        guard !isLoading else { return }
        messages = [ChatMessage(id: UUID(), content: SettingsManager.shared.localizedString(for: "ai_welcome_message"), isUser: false, timestamp: Date())]
        tripDraft = nil
        showDraftAlert = false
        inputText = ""
    }

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }
        defer { isLoading = false }
        
        let userMessage = ChatMessage(content: text, isUser: true)
        
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        
        do {
            // Pass conversation history (skip welcome message and current message which is sent separately)
            let history = Array(messages.dropFirst().dropLast().suffix(12))
            let responseText = try await GeminiService.shared.chat(message: text, history: history)
            
            try Task.checkCancellation()
            let parsed = AITripResponse.parse(responseText)
            self.tripDraft = parsed.draft
            self.showDraftAlert = parsed.draft != nil

            let aiMessage = ChatMessage(content: parsed.message, isUser: false, draft: parsed.draft)
            
            await MainActor.run {
                messages.append(aiMessage)
                isLoading = false
            }
        } catch is CancellationError {
        } catch let error as URLError where error.code == .cancelled {
        } catch {
            guard !Task.isCancelled else { return }
            await MainActor.run {
                messages.append(ChatMessage(content: "\(tr("เกิดข้อผิดพลาด", "Error")): \(error.localizedDescription)", isUser: false))
                isLoading = false
            }
        }
    }
}

struct TypingIndicatorView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 7, height: 7)
                    .foregroundColor(.gray.opacity(0.6))
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .padding(12)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onAppear {
            isAnimating = true
        }
    }
}

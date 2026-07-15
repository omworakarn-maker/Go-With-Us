import SwiftUI

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @Binding var showSideMenu: Bool
    @State private var showCreateTrip = false
    @State private var isAutoCreating = false
    @State private var showAutoCreateSuccess = false
    
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
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.adaptiveSecondaryText)
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
                                ChatMessageView(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isLoading {
                                HStack {
                                    TypingIndicatorView()
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .id("TypingIndicator")
                            }
                        }
                        .padding()
                    }
                    .onTapGesture {
                        hideKeyboard()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessage = viewModel.messages.last {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onChange(of: viewModel.isLoading) { _ in
                        if viewModel.isLoading {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo("TypingIndicator", anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .background(Color(UIColor.systemGroupedBackground))
                
                // Draft Alert (above input bar)
                if let draft = viewModel.tripDraft, viewModel.showDraftAlert {
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
                            Button(action: {
                                withAnimation { viewModel.showDraftAlert = false }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Draft Details
                        VStack(spacing: 8) {
                            HStack(spacing: 16) {
                                DraftInfoPill(icon: "mappin", text: draft.destination, color: .appAccent)
                                DraftInfoPill(icon: "calendar", text: draft.endDate != nil ? "\(draft.startDate) → \(draft.endDate!)" : draft.startDate, color: .appPrimary)
                            }
                            HStack(spacing: 16) {
                                DraftInfoPill(icon: "banknote", text: "\(draft.budget) ฿", color: Color(hex: "#2ECC71"))
                                DraftInfoPill(icon: "person.2", text: "สูงสุด \(draft.maxParticipants) คน", color: .purple)
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
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Input Bar (directly inline)
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 12) {
                        TextField(SettingsManager.shared.localizedString(for: "ai_input_placeholder"), text: $viewModel.inputText)
                            .padding(12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(24)

                        Button(action: {
                            Task { await viewModel.sendMessage() }
                        }) {
                            Circle()
                                .fill(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : Color.adaptiveText)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color.adaptiveBackground)
                                        .offset(x: -2, y: 2)
                                )
                        }
                        .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(12)
                    .background(Color.adaptiveBackground)
                }
                .background(Color.adaptiveBackground)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCreateTrip) {
                if let draft = viewModel.tripDraft {
                    CreateTripView(draft: draft)
                } else {
                    CreateTripView()
                }
            }
        }
        .alert("สร้างทริปสำเร็จ! 🎉", isPresented: $showAutoCreateSuccess) {
            Button("ตกลง", role: .cancel) {}
        } message: {
            Text("ทริปของคุณถูกสร้างแล้ว ไปดูได้ที่หน้าแรกเลย!")
        }
    }
    
    private func autoCreateTrip(draft: TripDraft) {
        isAutoCreating = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let start = formatter.date(from: draft.startDate) ?? Date()
        let end = draft.endDate.flatMap { formatter.date(from: $0) }
        
        // Append tags as hashtags to description
        let tagsString = (draft.tags ?? []).isEmpty ? "" : "\n" + (draft.tags ?? []).map { "#\($0)" }.joined(separator: " ")
        let fullDescription = draft.description + tagsString
        
        Task {
            do {
                _ = try await TripService.shared.createTrip(
                    title: draft.title,
                    destination: draft.destination,
                    description: fullDescription,
                    startDate: start,
                    endDate: end,
                    budget: draft.budget,
                    maxParticipants: draft.maxParticipants,
                    category: draft.category,
                    isPublic: true,
                    itinerary: draft.itinerary
                )
                await MainActor.run {
                    isAutoCreating = false
                    viewModel.showDraftAlert = false
                    showAutoCreateSuccess = true
                    NotificationCenter.default.post(name: NSNotification.Name("TripCreated"), object: nil)
                }
            } catch {
                await MainActor.run {
                    isAutoCreating = false
                    viewModel.messages.append(ChatMessage(content: "เกิดข้อผิดพลาดในการสร้างทริป: \(error.localizedDescription)", isUser: false))
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
                    .padding()
                    .background(Color.adaptiveText)
                    .foregroundColor(Color.adaptiveBackground)
                    .cornerRadius(16)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        // Minimalist AI icon
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.appPrimary, Color.appSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text("AI")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.white)
                            )
                        
                        Text(message.content)
                            .padding()
                            .background(Color.adaptiveCardBackground)
                            .foregroundColor(.adaptiveText)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                    }
                }
                Spacer()
            }
        }
    }
}

class AIChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading = false
    
    init() {
        self.messages = [ChatMessage(id: UUID(), content: SettingsManager.shared.localizedString(for: "ai_welcome_message"), isUser: false, timestamp: Date())]
    }
    
    @Published var tripDraft: TripDraft?
    @Published var showDraftAlert = false
    
    func clearChat() {
        messages = [ChatMessage(id: UUID(), content: SettingsManager.shared.localizedString(for: "ai_welcome_message"), isUser: false, timestamp: Date())]
        tripDraft = nil
        showDraftAlert = false
        inputText = ""
    }

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let userMessage = ChatMessage(content: text, isUser: true)
        
        await MainActor.run {
            messages.append(userMessage)
            inputText = ""
            isLoading = true
        }
        
        do {
            // Pass conversation history (skip welcome message and current message which is sent separately)
            let history = Array(messages.dropFirst().dropLast())
            let responseText = try await GeminiService.shared.chat(message: text, history: history)
            
            // Check for JSON Block (Robust multiple lines & markdown support)
            // Use greedy regex to match from the first { to the last }
            let pattern = "(\\{[\\s\\S]*\\})"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: responseText, options: [], range: NSRange(location: 0, length: responseText.utf16.count)) {
                
                if let range = Range(match.range, in: responseText) {
                    let jsonString = String(responseText[range])
                    
                    if let data = jsonString.data(using: .utf8),
                       let draft = try? JSONDecoder().decode(TripDraft.self, from: data) {
                        
                        await MainActor.run {
                            self.tripDraft = draft
                            self.showDraftAlert = true
                            
                            // Clean up display text
                            var cleanText = responseText.replacingOccurrences(of: jsonString, with: "")
                            cleanText = cleanText.replacingOccurrences(of: "```json", with: "")
                            cleanText = cleanText.replacingOccurrences(of: "```", with: "")
                            cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            let displayContent = cleanText.isEmpty ? "ผมได้ร่างทริปให้คุณแล้วครับ กดดูรายละเอียดด้านล่างได้เลย! 👇" : cleanText
                            
                            messages.append(ChatMessage(content: displayContent, isUser: false))
                            isLoading = false
                        }
                        return
                    }
                }
            }
            
            let aiMessage = ChatMessage(content: responseText, isUser: false)
            
            await MainActor.run {
                messages.append(aiMessage)
                isLoading = false
            }
        } catch {
            await MainActor.run {
                messages.append(ChatMessage(content: "เกิดข้อผิดพลาด: \(error.localizedDescription)", isUser: false))
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

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
                        Text("ที่ปรึกษา")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.adaptiveText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.clear)
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
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages) { _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
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
                            VStack(alignment: .leading) {
                                Text("🎉 ร่างทริปพร้อมแล้ว!")
                                    .font(.headline)
                                    .foregroundColor(.adaptiveText)
                                Text(draft.title)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
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
                                    } else {
                                        Image(systemName: "bolt.fill")
                                            .font(.system(size: 12))
                                    }
                                    Text("สร้างเลย")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.appPrimary)
                                .cornerRadius(12)
                            }
                            .disabled(isAutoCreating)
                            
                            // Edit before creating
                            Button(action: {
                                showCreateTrip = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 12))
                                    Text("ดูและแก้ไข")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(.adaptiveText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
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
                        TextField("พิมพ์ข้อความ...", text: $viewModel.inputText)
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
        let end = formatter.date(from: draft.endDate) ?? Date().addingTimeInterval(86400)
        
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
                    isPublic: true
                )
                await MainActor.run {
                    isAutoCreating = false
                    viewModel.showDraftAlert = false
                    showAutoCreateSuccess = true
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
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(.purple)
                            .padding(8)
                            .background(Color.purple.opacity(0.1))
                            .clipShape(Circle())
                        
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
        self.messages = [ChatMessage(id: UUID(), content: "สวัสดีครับ! ผมคือที่ปรึกษาการท่องเที่ยว มีอะไรให้ผมช่วยแนะนำหรือวางแผนทริปไหมครับ?", isUser: false, timestamp: Date())]
    }
    
    @Published var tripDraft: TripDraft?
    @Published var showDraftAlert = false
    

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
            let responseText = try await GeminiService.shared.chat(message: text, history: [])
            
            // Check for JSON Block (Robust multiple lines & markdown support)
            // Look for optional markdown fences, then curly braces
            let pattern = "(\\{[\\s\\S]*?\\})"
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

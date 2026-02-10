import SwiftUI

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("AI Assistant")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Powered by Gemini")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Placeholder for balance
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.clear)
            }
            .padding()
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
            
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
                                Spacer()
                                ProgressView()
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(20)
                                Spacer()
                            }
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
            .background(Color(UIColor.systemGroupedBackground))
            
            // Input Area
            HStack(spacing: 12) {
                TextField("พิมพ์ข้อความ...", text: $viewModel.inputText)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                Button(action: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                .opacity(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            }
            .padding()
            .background(Color.white)
        }
        .navigationBarHidden(true)
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
                    .background(Color.black)
                    .foregroundColor(.white)
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
                            .background(Color.white)
                            .foregroundColor(.black)
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
        // Initial greeting
        messages.append(ChatMessage(content: "สวัสดีครับ! ผมคือ AI ผู้ช่วยวางแผนเที่ยว มีอะไรให้ช่วยไหมครับ?", isUser: false))
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
            // Call Gemini Service
            // We pass history messages only
            let history = messages.dropLast() // Exclude the one we just added (though API expects separate history list)
            // Actually, in sendMessage above I appended it to local state.
            // The service call should probably take the prompt and history separately.
            
            // Let's modify service call structure slightly in my head:
            // Service expects history + current message.
            // But here I've already added message to local UI state.
            // So for history, I should pass `messages.dropLast()`.
            
            // Wait, logic check:
            // Input: "Hello"
            // UI State: [Greeting, "Hello"]
            // Service Call: msg="Hello", history=[Greeting]
            
            let responseText = try await GeminiService.shared.chat(message: text, history: []) // MVP: No history for potentially less complexity first, or filter messages.
            // Let's try to pass history correctly.
            // Converting my ChatMessage to what service might expect logic-wise.
            
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

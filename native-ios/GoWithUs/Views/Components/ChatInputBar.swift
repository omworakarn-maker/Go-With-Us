import SwiftUI

// Safe area helper
func getSafeAreaBottom() -> CGFloat {
    guard let window = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first?.windows
        .first else {
        return 0
    }
    return window.safeAreaInsets.bottom
}

struct ChatInputBar: View {
    @Binding var text: String
    var onSend: (String) -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("พิมพ์ข้อความ...", text: $text)
                .foregroundColor(.black)
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(24)

            Button(action: {
                let content = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !content.isEmpty else { return }
                onSend(content)
                text = ""
            }) {
                Circle()
                    .fill(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : Color.black)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .offset(x: -2, y: 2)
                    )
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
        // inputAccessoryView handles safe area automatically
    }
}

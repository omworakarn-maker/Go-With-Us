import SwiftUI

func getSafeAreaBottom() -> CGFloat {
    guard let window = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene }).first?.windows.first else { return 0 }
    return window.safeAreaInsets.bottom
}

func getSafeAreaTop() -> CGFloat {
    guard let window = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene }).first?.windows.first else { return 0 }
    return window.safeAreaInsets.top
}

struct ChatInputBar: View {
    @Binding var text: String
    var onSend: (String) -> Void

    private var content: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                TextField(tr("พิมพ์ข้อความ...", "Type a message…"), text: $text)
                    .foregroundStyle(Color.adaptiveText)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 48)
                    .appGlass(in: Capsule())
                    .submitLabel(.send)
                    .onSubmit(send)

                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .tint(.appSecondary)
                .disabled(content.isEmpty)
                .accessibilityLabel(tr("ส่งข้อความ", "Send message"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func send() {
        guard !content.isEmpty else { return }
        SettingsManager.shared.triggerSelection()
        onSend(content)
        text = ""
    }
}

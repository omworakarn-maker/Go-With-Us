import SwiftUI

struct ChatView: View {
    var body: some View {
        VStack {
            Image(systemName: "message.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Chat")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            Text("Coming Soon")
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    ChatView()
}

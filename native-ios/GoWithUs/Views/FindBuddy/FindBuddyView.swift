import SwiftUI

struct FindBuddyView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Icon
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.2")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(.black)
                        )
                    
                    // Text
                    VStack(spacing: 12) {
                        Text("หาเพื่อนร่วมทาง")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.black)
                            .tracking(-0.5)
                        
                        Text("ฟีเจอร์นี้กำลังพัฒนา\nเร็วๆ นี้...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("หาเพื่อน")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    FindBuddyView()
}

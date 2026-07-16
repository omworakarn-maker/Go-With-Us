import SwiftUI

struct ModernSplashView: View {
    @State private var size = 0.8
    @State private var opacity = 0.0
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                Image("LaunchImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    .scaleEffect(size)
                    .opacity(opacity)
            }
            .onAppear {
                // Phase 1: Spring animation for scale and fade
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    self.opacity = 1.0
                    self.size = 1.0
                }
            }
        }
    }
}

#Preview {
    ModernSplashView()
}

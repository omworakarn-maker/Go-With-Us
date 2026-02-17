import SwiftUI

struct SplashView: View {
    @State private var size = 1.0
    @State private var opacity = 0.0
    @State private var textOpacity = 0.0
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.black)
                    .scaleEffect(size)
                    .opacity(opacity)
            }
            .onAppear {
                // Phase 1: Fade in everything
                withAnimation(.easeIn(duration: 0.6)) {
                    self.opacity = 1.0
                    self.textOpacity = 1.0
                }
                
                // Phase 2: Zoom in (Twitter style)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    // Quick fade for text
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.textOpacity = 0.0
                    }
                    
                    // Massive scale for logo
                    withAnimation(.easeInOut(duration: 0.8)) {
                        self.size = 50.0 // Zoom in massively
                        self.opacity = 0.0 // Fade out simultaneously
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
}

import SwiftUI

struct ModernSplashView: View {
    @State private var size = 0.8
    @State private var opacity = 0.0
    @State private var rotation: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .foregroundStyle(Color.appAccent)
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(size)
                    .opacity(opacity)
            }
            .onAppear {
                // Phase 1: Fade in and Rotate
                withAnimation(.easeOut(duration: 1.0)) {
                    self.opacity = 1.0
                    self.size = 1.0
                    self.rotation = 360.0
                }
            }
        }
    }
}

#Preview {
    ModernSplashView()
}

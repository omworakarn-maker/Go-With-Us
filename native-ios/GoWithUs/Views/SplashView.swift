import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                VStack {
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.black)
                    
                    Text("Go With Us")
                        .font(.custom("AvenirNext-Bold", size: 32)) // Using a nice system font
                        .foregroundColor(.black.opacity(0.80))
                        .padding(.top, 8)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 0.9
                        self.opacity = 1.00
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
}

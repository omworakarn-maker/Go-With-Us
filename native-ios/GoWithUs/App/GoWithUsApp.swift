import SwiftUI

@main
struct GoWithUsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                } else {
                    ContentView()
                        .environmentObject(authViewModel)
                        .zIndex(0)
                        .transition(.opacity)
                }
            }
            .onAppear {
                NotificationPoller.shared.startPolling()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        self.showSplash = false
                    }
                }
            }
        }
    }
}

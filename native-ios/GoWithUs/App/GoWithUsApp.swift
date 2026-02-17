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
                    ModernSplashView()
                        .zIndex(1)
                        .transition(.move(edge: .top))
                } else {
                    ContentView()
                        .environmentObject(authViewModel)
                        .zIndex(0)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom),
                            removal: .identity
                        ))
                }
            }
            .ignoresSafeArea(edges: .top)
            .animation(.easeInOut(duration: 0.8), value: showSplash)
            .onAppear {
                NotificationPoller.shared.startPolling()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showSplash = false
                }
            }
        }
    }
}

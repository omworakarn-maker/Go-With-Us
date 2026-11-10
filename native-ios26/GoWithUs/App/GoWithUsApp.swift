import SwiftUI

@main
struct GoWithUsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var settings = SettingsManager.shared
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.white.ignoresSafeArea()
                if showSplash {
                    SplashView(onFinished: { showSplash = false })
                        .zIndex(1)
                        .transition(.opacity)
                } else {
                    ContentView()
                        .environmentObject(authViewModel)
                        .environmentObject(settings)
                        .environment(\.locale, Locale(identifier: settings.currentLanguage.rawValue))
                        .zIndex(0)
                        .transition(.opacity)
                }
            }
            .ignoresSafeArea(edges: .top)
            .tint(.appPrimary)
            .animation(.easeOut(duration: 0.22), value: showSplash)
            .onAppear {
                NotificationPoller.shared.startPolling()
            }
            .preferredColorScheme(.light) // Force light mode globally
        }
    }
}

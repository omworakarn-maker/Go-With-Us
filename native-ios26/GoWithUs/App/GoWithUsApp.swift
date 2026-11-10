import SwiftUI

@main
struct GoWithUsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var settings = SettingsManager.shared
    @State private var showSplash = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                        .transition(.asymmetric(
                            insertion: reduceMotion ? .opacity : .scale(scale: 0.94).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .ignoresSafeArea(edges: .top)
            .tint(.appPrimary)
            .animation(reduceMotion ? .easeOut(duration: 0.22) : .spring(duration: 0.58, bounce: 0), value: showSplash)
            .onAppear {
                NotificationPoller.shared.startPolling()
            }
            .preferredColorScheme(.light) // Force light mode globally
        }
    }
}

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
                // Mount the app while the splash plays so layout and initial work
                // do not compete with the reveal animation.
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(settings)
                    .environment(\.locale, Locale(identifier: settings.currentLanguage.rawValue))
                    .scaleEffect(showSplash && !reduceMotion ? 0.975 : 1)
                    .opacity(showSplash ? 0 : 1)
                    .allowsHitTesting(!showSplash)
                    .accessibilityHidden(showSplash)
                    .animation(reduceMotion ? .easeOut(duration: 0.18) : .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.30), value: showSplash)

                if showSplash {
                    SplashView(onFinished: {
                        withAnimation(.easeOut(duration: 0.18)) { showSplash = false }
                    })
                        .background(Color.white.ignoresSafeArea())
                        .zIndex(1)
                        .transition(.opacity.animation(.easeOut(duration: 0.18)))
                }
            }
            .ignoresSafeArea(edges: .top)
            .tint(.appPrimary)
            .onAppear {
                NotificationPoller.shared.startPolling()
            }
            .preferredColorScheme(.light) // Force light mode globally
        }
    }
}

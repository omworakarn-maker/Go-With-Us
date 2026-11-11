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
            GeometryReader { viewport in
              ZStack {
                Color.white.ignoresSafeArea()
                // Mount the app while the splash plays so layout and initial work
                // do not compete with the reveal animation.
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(settings)
                    .environment(\.locale, Locale(identifier: settings.currentLanguage.rawValue))
                    .offset(x: showSplash && !reduceMotion ? viewport.size.width : 0)
                    .opacity(reduceMotion && showSplash ? 0 : 1)
                    .zIndex(1)
                    .allowsHitTesting(!showSplash)
                    .accessibilityHidden(showSplash)
                    .animation(reduceMotion ? .easeOut(duration: 0.18) : .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.28), value: showSplash)

                if showSplash {
                    SplashView(onFinished: {
                        withAnimation(reduceMotion ? .easeOut(duration: 0.18) : .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.28)) { showSplash = false }
                    }, isReady: {
                        authViewModel.startupAuthResolved &&
                        (!authViewModel.isAuthenticated || authViewModel.showOTPVerification ||
                         TripListViewModel.startupHomeResolved)
                    })
                        .background(Color.white.ignoresSafeArea())
                        .zIndex(0)
                        .transition(.asymmetric(
                            insertion: .identity,
                            removal: reduceMotion ? .opacity : .offset(x: -viewport.size.width * 0.25)
                        ))
                }
              }
            }
            .ignoresSafeArea(edges: .top)
            .tint(.appPrimary)
            .overlay {
                PromotionStartupOverlay(ready: !showSplash)
                    .environmentObject(authViewModel)
                    .environment(\.locale, Locale(identifier: settings.currentLanguage.rawValue))
            }
            .onAppear {
                NotificationPoller.shared.startPolling()
            }
            .preferredColorScheme(.light) // Force light mode globally
        }
    }
}

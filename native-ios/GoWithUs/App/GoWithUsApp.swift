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
                    // ปรับเปลี่ยน SplashScreen ที่นี่:
                    // - ModernSplashView(): ตัวปัจจุบัน (โลโก้หมุน พรีเมียม)
                    // - SplashView(): ตัวเก่า (ไอคอนเครื่องบิน ซูมเข้า)
                    ModernSplashView()
                        .zIndex(1)
                        .transition(.move(edge: .top))
                } else {
                    ContentView()
                        .environmentObject(authViewModel)
                        .environmentObject(SettingsManager.shared)
                        .environment(\.locale, Locale(identifier: SettingsManager.shared.currentLanguage.rawValue))
                        .zIndex(0)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom),
                            removal: .identity
                        ))
                }
            }
            .ignoresSafeArea(edges: .top)
            .animation(.easeInOut(duration: 0.5), value: showSplash)
            .onAppear {
                NotificationPoller.shared.startPolling()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    showSplash = false
                }
            }
            .preferredColorScheme(.light) // Force light mode globally
        }
    }
}

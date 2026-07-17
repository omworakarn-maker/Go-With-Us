import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.scenePhase) private var scenePhase

    // State for navigation
    @State private var currentScreen: AppScreen = SettingsManager.shared.homeLayoutPreference
    @State private var showSideMenu = false
    @State private var showingCreateTrip = false
    @State private var badgeCounts: [Tab: Int] = [:]
    @State private var activeTransition: AnyTransition = .identity
    @State private var showTabBarWithAnimation = false
    /// Timestamp when the app moved to background — used to decide whether to force-refresh
    @State private var backgroundedAt: Date? = nil
    /// Force-refresh token passed down to persistent tab views
    @State private var forceRefreshToken: UUID = UUID()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                ZStack(alignment: .bottom) {
                // ── Persistent tab views (never destroyed on tab switch) ──
                // Shown/hidden via opacity so state & cache survive
                ZStack {
                    // Home Tab Container
                    ZStack(alignment: .top) {
                        HomeView(showSideMenu: $showSideMenu, currentScreen: $currentScreen)
                            .offset(x: settings.homeLayoutPreference == .homeGrid ? -UIScreen.main.bounds.width : 0)
                            .allowsHitTesting(currentScreen == .home)
                            .id("home-\(forceRefreshToken)")

                        HomeGridView(showSideMenu: $showSideMenu, currentScreen: $currentScreen)
                            .offset(x: settings.homeLayoutPreference == .home ? UIScreen.main.bounds.width : 0)
                            .allowsHitTesting(currentScreen == .homeGrid)
                            .id("homeGrid-\(forceRefreshToken)")
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.9, blendDuration: 0), value: settings.homeLayoutPreference)
                    .opacity((currentScreen == .home || currentScreen == .homeGrid) ? 1 : 0)

                    MatchTripView(showSideMenu: $showSideMenu)
                        .opacity(currentScreen == .matchTrip ? 1 : 0)
                        .allowsHitTesting(currentScreen == .matchTrip)
                        .id("match-\(forceRefreshToken)")

                    ChatView()
                        .opacity(currentScreen == .chat ? 1 : 0)
                        .allowsHitTesting(currentScreen == .chat)
                        .id("chat-\(forceRefreshToken)")

                    ProfileView()
                        .opacity(currentScreen == .profile ? 1 : 0)
                        .allowsHitTesting(currentScreen == .profile)
                        .id("profile-\(forceRefreshToken)")

                    // ── Non-tab screens rendered normally (destroy on leave is fine) ──
                    if !isMainTabScreen {
                        Group {
                            switch currentScreen {
                            case .findBuddy:
                                FindBuddyView(showSideMenu: $showSideMenu)
                            case .favorites:
                                MyTripsView(showSideMenu: $showSideMenu, initialTab: 2)
                            case .myTrips:
                                MyTripsView(showSideMenu: $showSideMenu, initialTab: 0)
                            case .aiChat:
                                AIChatView(showSideMenu: $showSideMenu)
                            default:
                                EmptyView()
                            }
                        }
                        .transition(activeTransition)
                        .id(currentScreen)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if shouldShowTabBar && showTabBarWithAnimation {
                    CustomTabBar(
                        selectedTab: selectedTabBinding,
                        onCreateTap: { showingCreateTrip = true },
                        badgeCounts: badgeCounts
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        showTabBarWithAnimation = true
                    }
                }
            }
            .overlay {
                // Side Menu Backdrop
                if showSideMenu {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) { showSideMenu = false }
                        }
                        .transition(.opacity)
                }
            }
            .overlay(alignment: .leading) {
                // Side Menu Panel
                SideMenuView(isShowing: $showSideMenu, currentScreen: $currentScreen, transition: $activeTransition)
                    .frame(width: min(UIScreen.main.bounds.width * 0.8, 320))
                    .offset(x: showSideMenu ? 0 : -UIScreen.main.bounds.width)
                    .animation(.easeInOut(duration: 0.3), value: showSideMenu)
            }
            .sheet(isPresented: $showingCreateTrip) {
                CreateTripView()
            }

            .onPreferenceChange(TabBarHiddenKey.self) { hidden in
                withAnimation(.easeInOut(duration: 0.3)) {
                    isChildViewHidingTabBar = hidden
                }
            }
            .task {
                await fetchUnreadCounts()
            }
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .background:
                    // Record when we went to background
                    backgroundedAt = Date()
                case .active:
                    // If we were backgrounded for 10+ minutes, force full refresh
                    if let bg = backgroundedAt, Date().timeIntervalSince(bg) > 600 {
                        // Reset all caches
                        TripListViewModel.invalidateCache()
                        ChatViewModel.invalidateCache()
                        MatchTripViewModel.invalidateCache()
                        // Swap token to force view recreation
                        forceRefreshToken = UUID()
                    }
                    backgroundedAt = nil
                default:
                    break
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewNotificationReceived"))) { _ in
                Task { await fetchUnreadCounts() }
            }
            // Poll every 10 seconds for chat badges
            .onReceive(Timer.publish(every: 10, on: .main, in: .common).autoconnect()) { _ in
                Task { await fetchUnreadCounts() }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewMessageReceived"))) { _ in
                Task { await fetchUnreadCounts() }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LocalUnreadTotalChanged"))) { note in
                if let info = note.userInfo, let local = info["localTotal"] as? Int {
                    print("🔔 ContentView: received LocalUnreadTotalChanged local=\(local) serverLast=\(lastUnreadCount)")
                    Task { await MainActor.run {
                        localOverrideTotal = local
                        let display = max(lastUnreadCount, localOverrideTotal)
                        badgeCounts[.chat] = display
                        UNUserNotificationCenter.current().setBadgeCount(display) { error in
                            if let error = error { print("❌ Failed to set badge count: \(error)") }
                        }
                    }}
                }
            }
        } else {
            LoginView()
        }
        }
        .fullScreenCover(isPresented: $authViewModel.needsOnboarding) {
            NavigationStack {
                QuestionnaireView(isOnboarding: true)
                    .environmentObject(authViewModel)
            }
        }
        .fullScreenCover(isPresented: $authViewModel.showOTPVerification) {
            OTPVerificationView()
                .environmentObject(authViewModel)
        }
    }
    
    @State private var lastUnreadCount: Int = 0
    @State private var localOverrideTotal: Int = 0
    
    private func fetchUnreadCounts() async {
        do {
            let conversations = try await MessageService.shared.getConversations()
            let totalUnread = conversations.compactMap { $0.unreadCount }.reduce(0, +)
            
                await MainActor.run {
                    print("🔔 ContentView: totalUnread=\(totalUnread)")
                    for c in conversations {
                        print("   conv: \(c.user.name) unread=\(c.unreadCount ?? 0)")
                    }

                    // Trigger notification if count increased (and > 0)
                    if totalUnread > lastUnreadCount {
                        let newMessages = totalUnread - lastUnreadCount
                        if newMessages > 0 {
                            triggerLocalNotification(count: newMessages)
                            NotificationCenter.default.post(name: NSNotification.Name("NewNotificationReceived"), object: nil)
                        }
                    }

                    // Use local override total if it's higher than server total
                    lastUnreadCount = totalUnread
                    let display = max(totalUnread, localOverrideTotal)
                    badgeCounts[.chat] = display

                    // Update App Icon Badge
                    UNUserNotificationCenter.current().setBadgeCount(display) { error in
                        if let error = error {
                            print("❌ Failed to set badge count: \(error)")
                        }
                    }
                }
        } catch {
            print("Failed to fetch badge counts: \(error)")
        }
    }

    
    private func triggerLocalNotification(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "ข้อความใหม่"
        content.body = "คุณมี \(count) ข้อความใหม่ที่ยังไม่ได้อ่าน"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification Error: \(error)")
            }
        }
    }

    
    // Bridge AppScreen <-> Tab
    private var selectedTabBinding: Binding<Tab> {
        Binding<Tab>(
            get: {
                switch currentScreen {
                case .home, .homeGrid: return .home
                case .matchTrip: return .matchTrip
                case .favorites, .myTrips: return .home // Highlight home for side menu items
                case .chat: return .chat
                case .profile: return .profile
                default: return .home // Default to home highlight for others
                }
            },
            set: { newTab in
                // Taps on Tab Bar should have a subtle cross-fade animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    activeTransition = .opacity.combined(with: .scale(scale: 0.98))
                    currentScreen = {
                        switch newTab {
                        case .home: return settings.homeLayoutPreference
                        case .matchTrip: return .matchTrip
                        case .chat: return .chat
                        case .profile: return .profile
                        case .create: return currentScreen
                        }
                    }()
                }
            }
        )
    }
    
    private var shouldShowTabBar: Bool {
        if isChildViewHidingTabBar { return false }
        switch currentScreen {
        case .home, .homeGrid, .matchTrip, .chat, .profile:
            return true
        default:
            return false
        }
    }

    private var isMainTabScreen: Bool {
        switch currentScreen {
        case .home, .homeGrid, .matchTrip, .chat, .profile:
            return true
        default:
            return false
        }
    }

    // Add state to track preference
    @State private var isChildViewHidingTabBar = false
}

// Add extension to listen
extension ContentView {
    // We need to attach this to the main ZStack or Group
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}

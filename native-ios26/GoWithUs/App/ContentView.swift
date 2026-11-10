import Combine
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.scenePhase) private var scenePhase

    // State for navigation
    @State private var currentScreen: AppScreen = SettingsManager.shared.homeLayoutPreference
    @State private var showSideMenu = false
    @State private var showingCreateTrip = false
    @State private var profileSettingsRequest: UUID?
    @State private var badgeCounts: [Tab: Int] = [:]
    @State private var nativeIconPulse = UUID()
    @State private var activeTransition: AnyTransition = .identity
    /// Timestamp when the app moved to background — used to decide whether to force-refresh
    @State private var backgroundedAt: Date? = nil
    /// Force-refresh token passed down to persistent tab views
    @State private var forceRefreshToken: UUID = UUID()

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                ZStack {
                    nativeTabs

                    if !isMainTabScreen {
                        Group {
                            switch currentScreen {
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
                SideMenuView(isShowing: $showSideMenu, currentScreen: $currentScreen, transition: $activeTransition,
                             settingsRequest: profileSettingsRequest)
                    .frame(width: min(UIScreen.main.bounds.width * 0.8, 320))
                    .offset(x: showSideMenu ? 0 : -UIScreen.main.bounds.width)
                    .animation(.easeInOut(duration: 0.3), value: showSideMenu)
            }
            .sheet(isPresented: $showingCreateTrip) {
                CreateTripView()
            }

            .task {
                WebSocketService.shared.connect()
                NotificationPoller.shared.startPolling()
                await fetchUnreadCounts()
            }
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .background:
                    WebSocketService.shared.disconnect()
                    NotificationPoller.shared.stopPolling()
                    MessagePoller.shared.stopPolling()
                    // Record when we went to background
                    backgroundedAt = Date()
                case .active:
                    WebSocketService.shared.connect()
                    NotificationPoller.shared.startPolling()
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
        .onReceive(NotificationCenter.default.publisher(for: .init("SessionRevoked"))) { _ in
            authViewModel.logout()
        }
        .fullScreenCover(isPresented: $authViewModel.needsOnboarding) {
            NavigationStack {
                QuestionnaireView(isOnboarding: true)
                    .environmentObject(authViewModel)
            }
        }
        .fullScreenCover(isPresented: $authViewModel.showOTPVerification) {
            NavigationStack {
                OTPVerificationView()
                    .environmentObject(authViewModel)
            }
        }
    }

    @State private var lastUnreadCount: Int = 0
    @State private var localOverrideTotal: Int = 0

    @State private var isFetchingUnread = false

    private func fetchUnreadCounts() async {
        guard authViewModel.isAuthenticated, scenePhase == .active, !isFetchingUnread else { return }
        let token = KeychainService.shared.getToken()
        isFetchingUnread = true
        defer { isFetchingUnread = false }
        do {
            let conversations = try await MessageService.shared.getConversations()
            guard KeychainService.shared.getToken() == token else { return }
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


    // iOS owns the tab bar material, selection effects, and layout.
    private var nativeTabs: some View {
        TabView(selection: selectedTabBinding) {
            SwiftUI.Tab(value: Tab.home) {
                Group {
                    if settings.homeLayoutPreference == .homeGrid {
                        HomeGridView(showSideMenu: $showSideMenu, currentScreen: $currentScreen)
                            .id("homeGrid-\(forceRefreshToken)")
                    } else {
                        HomeView(showSideMenu: $showSideMenu, currentScreen: $currentScreen)
                            .id("home-\(forceRefreshToken)")
                    }
                }
            } label: {
                Label(settings.localizedString(for: "home"), systemImage: "house")
            }

            SwiftUI.Tab(value: Tab.matchTrip) {
                MatchTripView(showSideMenu: $showSideMenu)
                    .id("match-\(forceRefreshToken)")
            } label: {
                Label(tr("แมตช์ทริป", "Match Trip"), systemImage: "arrow.triangle.2.circlepath")
            }

            SwiftUI.Tab(value: Tab.chat) {
                ChatView().id("chat-\(forceRefreshToken)")
            } label: {
                Label(tr("แชท", "Chat"), systemImage: "message")
            }
            .badge(badgeCounts[.chat] ?? 0)

            SwiftUI.Tab(value: Tab.profile) {
                ProfileView().id("profile-\(forceRefreshToken)")
            } label: {
                Label(settings.localizedString(for: "profile"), systemImage: "person")
            }

            // The native detached trailing slot keeps Apple's glass and layout.
            // Its action is intercepted below, rather than selecting an empty page.
            if currentScreen == .home || currentScreen == .homeGrid || currentScreen == .profile {
                SwiftUI.Tab(value: Tab.create, role: .search) {
                    Color.clear
                } label: {
                    Label(currentScreen == .profile
                          ? settings.localizedString(for: "settings")
                          : settings.localizedString(for: "create"),
                          systemImage: currentScreen == .profile ? "gearshape" : "plus")
                }
            }
        }
        .tint(.appSecondary)
        .background {
            NativeTabIconFeedback(
                selection: Tab.mainTabs.firstIndex(of: selectedTabBinding.wrappedValue) ?? 0,
                tab: selectedTabBinding.wrappedValue,
                pulse: nativeIconPulse,
                active: isMainTabScreen && scenePhase == .active
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .toolbar(isMainTabScreen ? .automatic : .hidden, for: .tabBar)
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
                if newTab == .create {
                    SettingsManager.shared.triggerSelection()
                    if currentScreen == .profile {
                        profileSettingsRequest = UUID()
                        withAnimation(.smooth(duration: 0.25)) { showSideMenu = true }
                    } else if currentScreen == .home || currentScreen == .homeGrid {
                        showingCreateTrip = true
                    }
                    return
                }
                SettingsManager.shared.triggerSelection()
                // Let the native tab bar own its selection animation.
                currentScreen = {
                    switch newTab {
                    case .home: return settings.homeLayoutPreference
                    case .matchTrip: return .matchTrip
                    case .chat: return .chat
                    case .profile: return .profile
                    case .create: return currentScreen
                    }
                }()
                nativeIconPulse = UUID()
            }
        )
    }

    private var isMainTabScreen: Bool {
        switch currentScreen {
        case .home, .homeGrid, .matchTrip, .chat, .profile:
            return true
        default:
            return false
        }
    }

}

// Add extension to listen
extension ContentView {
    // We need to attach this to the main ZStack or Group
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}

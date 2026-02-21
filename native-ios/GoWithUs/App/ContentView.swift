import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // State for navigation
    @State private var currentScreen: AppScreen = .home
    @State private var showSideMenu = false
    @State private var showingCreateTrip = false
    @State private var badgeCounts: [Tab: Int] = [:]
    @State private var activeTransition: AnyTransition = .identity 
    @State private var showTabBarWithAnimation = false
    
    var body: some View {
        if authViewModel.isAuthenticated {
            ZStack(alignment: .bottom) {
                // Main Content Area with Fade Transition
                Group {
                    switch currentScreen {
                    case .home:
                        HomeView(showSideMenu: $showSideMenu, currentScreen: $currentScreen)
                    case .homeGrid:
                        HomeGridView(showSideMenu: $showSideMenu, currentScreen: $currentScreen)
                    case .findBuddy:
                        FindBuddyView()
                    case .chat:
                        ChatView()
                    case .profile:
                        ProfileView()
                    case .matchTrip:
                        MatchTripView(showSideMenu: $showSideMenu)
                    case .myTrips:
                        MyTripsView(showSideMenu: $showSideMenu)
                    case .aiChat:
                        AIChatView(showSideMenu: $showSideMenu)
                    default:
                        Text("Coming Soon")
                    }
                }
                .transition(activeTransition)
                .id(currentScreen) // Force transition when state changes
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
                    .frame(width: UIScreen.main.bounds.width * 0.8)
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
                case .home: return .home
                case .findBuddy: return .buddy
                case .chat: return .chat
                case .profile: return .profile
                default: return .home // Default to home highlight for others
                }
            },
            set: { newTab in
                // Taps on Tab Bar should have NO animation
                activeTransition = .identity
                currentScreen = {
                    switch newTab {
                    case .home: return .home
                    case .buddy: return .findBuddy
                    case .chat: return .chat
                    case .profile: return .profile
                    case .create: return currentScreen // Handled by sheet
                    }
                }()
            }
        )
    }
    
    private var shouldShowTabBar: Bool {
        // Show tab bar only on main tab screens AND if not hidden by child view
        if isChildViewHidingTabBar { return false }
        
        switch currentScreen {
        case .home, .findBuddy, .chat, .profile:
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

import Combine
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // State for navigation
    @State private var currentScreen: AppScreen = SettingsManager.shared.homeLayoutPreference
    @State private var showSideMenu = false
    @State private var tripCreation = TripCreationState()
    @State private var createdTripToOpen: Trip?
    @State private var creationCanvas = CGSize(width: 390, height: 800)
    @State private var plusButtonFrame: CGRect?
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
                        .allowsHitTesting(tripCreation.id == nil)
                        .accessibilityHidden(tripCreation.id != nil)

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
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                if size.width > 0 && size.height > 0 { creationCanvas = size }
            }
            .overlay {
                NativePlusButtonFrameReader { plusButtonFrame = $0 }
                    .frame(width: creationCanvas.width, height: creationCanvas.height)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .overlay(alignment: .topLeading) {
                GeometryReader { viewport in
                    if let session = tripCreation.id {
                        CreateTripView(onClose: { closeTripCreation(session) })
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.adaptiveBackground.ignoresSafeArea(.container))
                            .id(session)
                            .transition(creationTransition(canvas: viewport.size))
                    }
                }
                // One viewport owns both the page and the home-indicator
                // background. Keyboard avoidance remains enabled for the form.
                .ignoresSafeArea(.container, edges: .bottom)
                .allowsHitTesting(tripCreation.id != nil)
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
                    .opacity(showSideMenu ? 1 : 0)
                    .allowsHitTesting(showSideMenu)
                    .accessibilityHidden(!showSideMenu)
                    .animation(.easeInOut(duration: 0.3), value: showSideMenu)
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
                        // Refresh data in place. Recreating every tab here caused
                        // the home screen to flash after returning to the app.
                        NotificationCenter.default.post(name: .init("AppDataRefreshRequested"), object: nil)
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
        .onChange(of: authViewModel.isAuthenticated) { _, authenticated in
            if !authenticated { tripCreation.reset() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("SessionRevoked"))) { _ in
            authViewModel.logout()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("TripCreated"))) { note in
            guard tripCreation.id != nil, let trip = note.object as? Trip else { return }
            tripCreation.reset()
            Task {
                try? await Task.sleep(for: .milliseconds(320))
                guard !Task.isCancelled else { return }
                createdTripToOpen = trip
            }
        }
        .sheet(item: $createdTripToOpen) { trip in
            NavigationStack {
                TripDetailView(tripId: trip.id)
            }
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
            if showsTrailingAction {
                SwiftUI.Tab(value: Tab.create, role: .search) {
                    Color.clear
                } label: {
                    Label(settings.localizedString(for: "create"), systemImage: "plus")
                }
            }
        }
        .tint(.appSecondary)
        // Animate native tab insertion/removal so the system can reshape its
        // glass grouping, instead of switching between two static layouts.
        .animation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.88),
                   value: showsTrailingAction)
        .background {
            NativeTabIconFeedback(
                selection: Tab.mainTabs.firstIndex(of: selectedTabBinding.wrappedValue) ?? 0,
                tab: selectedTabBinding.wrappedValue,
                separatedAction: showsTrailingAction,
                pulse: nativeIconPulse,
                active: isMainTabScreen && scenePhase == .active && tripCreation.id == nil
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
                    openTripCreation()
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

    private func creationTransition(canvas: CGSize) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
        let origin = TripCreationGeometry.source(in: canvas, measured: plusButtonFrame)
        return .modifier(
            active: TripCreationExpansion(progress: 0, canvas: canvas, origin: origin),
            identity: TripCreationExpansion(progress: 1, canvas: canvas, origin: origin)
        )
    }

    private func openTripCreation() {
        guard tripCreation.id == nil else { return }
        hideKeyboard()
        showSideMenu = false
        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .smooth(duration: 0.38)) {
            tripCreation.open()
        }
    }

    private func closeTripCreation(_ session: UUID) {
        guard tripCreation.id == session else { return }
        hideKeyboard()
        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .smooth(duration: 0.3)) {
            tripCreation.close(session)
        }
    }

    private var showsTrailingAction: Bool {
        isMainTabScreen
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

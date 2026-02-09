import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var showingCreateTrip = false
    @State private var isTabBarHidden = false
    
    // Hide default tab bar
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Main Content
                Group {
                    switch selectedTab {
                    case .home:
                        HomeView()
                    case .buddy:
                        FindBuddyView()
                    case .create:
                        EmptyView()
                    case .chat:
                        ChatView()
                    case .profile:
                        ProfileView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Custom Tab Bar
                if !isTabBarHidden {
                    CustomTabBar(selectedTab: $selectedTab, onCreateTap: {
                        showingCreateTrip = true
                    }, bottomPadding: geometry.safeAreaInsets.bottom)
                    .transition(.move(edge: .bottom))
                }
            }
            .edgesIgnoringSafeArea(.bottom) // Allow tab bar to extend to bottom
            .onPreferenceChange(TabBarHiddenKey.self) { hidden in
                withAnimation {
                    self.isTabBarHidden = hidden
                }
            }
            .sheet(isPresented: $showingCreateTrip) {
                CreateTripView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}

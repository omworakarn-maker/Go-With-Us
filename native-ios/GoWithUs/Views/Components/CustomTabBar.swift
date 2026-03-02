import SwiftUI

enum Tab: String, CaseIterable {
    case home = "Home"
    case matchTrip = "Match Trip"
    case create = "Create"
    case chat = "Chat"
    case profile = "Profile"
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    var onCreateTap: () -> Void
    var bottomPadding: CGFloat = 0
    var badgeCounts: [Tab: Int] = [:]
    
    private var fillImage: String {
        selectedTab.rawValue
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                // Tab Bar Background & Items
                HStack {
                    ForEach(Tab.allCases, id: \.rawValue) { tab in
                        Spacer()
                        if tab == .create {
                            // Invisible spacer for layout
                            Color.clear
                                .frame(width: 56, height: 44)
                        } else {
                            Button(action: {
                                withAnimation(.spring()) {
                                    selectedTab = tab
                                }
                            }) {
                                VStack(spacing: 4) {
                                    if let badgeCount = badgeCounts[tab], badgeCount > 0 {
                                        Image(systemName: getImageName(for: tab))
                                            .font(.system(size: 22))
                                            .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                                            .foregroundColor(selectedTab == tab ? .appAccent : .gray.opacity(0.6))
                                            .overlay(
                                                Text("\(min(badgeCount, 99))")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(4)
                                                    .background(Color.appAccent)
                                                    .clipShape(Circle())
                                                    .offset(x: 10, y: -10),
                                                alignment: .topTrailing
                                            )
                                    } else {
                                        Image(systemName: getImageName(for: tab))
                                            .font(.system(size: 22))
                                            .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                                            .foregroundColor(selectedTab == tab ? .appAccent : .gray.opacity(0.6))
                                    }
                                    
                                    Text(getThaiTitle(for: tab))
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(selectedTab == tab ? .appAccent : .gray.opacity(0.6))
                                }
                            }
                        }
                        Spacer()
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 12)
                .background(Color.adaptiveBackground)
                .shadow(color: Color.adaptiveText.opacity(0.06), radius: 10, x: 0, y: -2)
                
                // Floating Create Button
                Button(action: {
                    onCreateTap()
                }) {
                    ZStack {
                        Circle()
                            .foregroundColor(.appAccent)
                            .frame(width: 56, height: 56)
                            .overlay(
                                Circle()
                                    .stroke(Color.adaptiveBackground, lineWidth: 4)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .offset(y: -28) // Center of the bar
            }
        }
        .background(Color.adaptiveBackground)
        .ignoresSafeArea(edges: .bottom)

    }
    
    func getImageName(for tab: Tab) -> String {
        switch tab {
        case .home:
            return selectedTab == .home ? "house.fill" : "house"
        case .matchTrip:
            return selectedTab == .matchTrip ? "arrow.triangle.2.circlepath.circle.fill" : "arrow.triangle.2.circlepath.circle"
        case .create:
            return "plus"
        case .chat:
            return selectedTab == .chat ? "message.fill" : "message"
        case .profile:
            return selectedTab == .profile ? "person.fill" : "person"
        }
    }
    
    func getThaiTitle(for tab: Tab) -> String {
        switch tab {
        case .home: return SettingsManager.shared.localizedString(for: "home")
        case .matchTrip: return SettingsManager.shared.currentLanguage == .thai ? "แมตช์ทริป" : "Match Trip"
        case .create: return SettingsManager.shared.localizedString(for: "create")
        case .chat: return SettingsManager.shared.currentLanguage == .thai ? "แชท" : "Chat"
        case .profile: return SettingsManager.shared.localizedString(for: "profile")
        }
    }
}



#Preview {
    CustomTabBar(selectedTab: .constant(.home), onCreateTap: {})
}

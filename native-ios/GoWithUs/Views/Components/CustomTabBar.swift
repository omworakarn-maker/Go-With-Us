import SwiftUI

enum Tab: String, CaseIterable {
    case home = "Home"
    case buddy = "Buddy"
    case create = "Create"
    case chat = "Chat"
    case profile = "Profile"
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    var onCreateTap: () -> Void
    var bottomPadding: CGFloat = 0
    
    private var fillImage: String {
        selectedTab.rawValue
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Bar Background & Items
            HStack {
                ForEach(Tab.allCases, id: \.rawValue) { tab in
                    Spacer()
                    if tab == .create {
                        // Invisible spacer for layout
                        Color.clear
                            .frame(width: 56, height: 56)
                    } else {
                        Button(action: {
                            withAnimation(.spring()) {
                                selectedTab = tab
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: getImageName(for: tab))
                                    .font(.system(size: 24))
                                    .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                                    .foregroundColor(selectedTab == tab ? .black : .gray.opacity(0.8))
                                
                                Text(tab.rawValue)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(selectedTab == tab ? .black : .gray.opacity(0.8))
                            }
                        }
                    }
                    Spacer()
                }
            }
            .padding(.bottom, bottomPadding)
            .padding(.top, 10) // Internal padding
            .frame(width: UIScreen.main.bounds.width)
            .background(
                Color.white
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
            )
            
            // Floating Create Button (Z-Index is higher here)
            Button(action: {
                onCreateTap()
            }) {
                ZStack {
                    Circle()
                        .foregroundColor(.black)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -bottomPadding - 30) // Move up above the bar
        }
    }
    
    func getImageName(for tab: Tab) -> String {
        switch tab {
        case .home:
            return selectedTab == .home ? "house.fill" : "house"
        case .buddy:
            return selectedTab == .buddy ? "person.2.fill" : "person.2"
        case .create:
            return "plus"
        case .chat:
            return selectedTab == .chat ? "message.fill" : "message"
        case .profile:
            return selectedTab == .profile ? "person.fill" : "person"
        }
    }
}



#Preview {
    CustomTabBar(selectedTab: .constant(.home), onCreateTap: {})
}

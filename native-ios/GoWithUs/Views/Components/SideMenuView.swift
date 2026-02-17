import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @Binding var currentScreen: AppScreen
    @Binding var transition: AnyTransition
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showLogoutAlert = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            if isShowing {
                // Dimmed Background
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowing = false
                        }
                    }
                
                // Menu Content
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        if let user = authViewModel.currentUser {
                            // Profile image or initial
                            if let data = UserDefaults.standard.data(forKey: "local_profile_image"),
                               let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.appAccent)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Text(String(user.name.prefix(1)))
                                            .foregroundColor(.white)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.adaptiveText)
                                
                                if let handle = UserDefaults.standard.string(forKey: "user_handle"), !handle.isEmpty {
                                    Text("@\(handle)")
                                        .font(.caption)
                                        .foregroundColor(.appAccent)
                                } else {
                                    Text(user.email)
                                        .font(.caption)
                                        .foregroundColor(.adaptiveSecondaryText)
                                }
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.adaptiveSecondaryText)
                            Text("Guest")
                                .font(.headline)
                                .foregroundColor(.adaptiveText)
                        }
                    }
                    .padding(.top, 60)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    
                    Divider()
                        .padding(.bottom, 20)
                    
                    // Menu Items
                    VStack(alignment: .leading, spacing: 24) {
                        MenuButton(icon: "house", text: "หน้าแรก", targetScreen: .home, currentScreen: $currentScreen, isShowing: $isShowing, transition: $transition)
                        
                        MenuButton(icon: "arrow.triangle.2.circlepath", text: "แมตช์ทริป", targetScreen: .matchTrip, currentScreen: $currentScreen, isShowing: $isShowing, transition: $transition)
                        
                        MenuButton(icon: "suitcase", text: "ทริปของฉัน", targetScreen: .myTrips, currentScreen: $currentScreen, isShowing: $isShowing, transition: $transition)
                        
                        MenuButton(icon: "bubble.left.and.text.bubble.right", text: "คุยกับ AI", targetScreen: .aiChat, currentScreen: $currentScreen, isShowing: $isShowing, transition: $transition)
                        
                        MenuButton(icon: "person.crop.circle", text: "โปรไฟล์", targetScreen: .profile, currentScreen: $currentScreen, isShowing: $isShowing, transition: $transition)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Bottom Actions — Logout with confirmation
                    if authViewModel.currentUser != nil {
                        Button(action: {
                            showLogoutAlert = true
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "arrow.right.square")
                                    .font(.system(size: 20))
                                Text("ออกจากระบบ")
                                    .font(.headline)
                            }
                            .foregroundColor(.red)
                            .padding()
                            .padding(.bottom, 40)
                        }
                    }
                }
                .frame(width: UIScreen.main.bounds.width * 0.75)
                .background(Color.adaptiveBackground)
                .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isShowing)
        .ignoresSafeArea(.all)
        .alert("ออกจากระบบ", isPresented: $showLogoutAlert) {
            Button("ยกเลิก", role: .cancel) {}
            Button("ออกจากระบบ", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowing = false
                }
                authViewModel.logout()
            }
        } message: {
            Text("คุณต้องการออกจากระบบใช่หรือไม่?")
        }
    }
}

struct MenuButton: View {
    let icon: String
    let text: String
    let targetScreen: AppScreen
    @Binding var currentScreen: AppScreen
    @Binding var isShowing: Bool
    @Binding var transition: AnyTransition
    
    var body: some View {
        Button(action: {
            // Set sliding transition when navigating from Side Menu
            transition = .move(edge: .leading).combined(with: .opacity)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentScreen = targetScreen
                isShowing = false
            }
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(currentScreen == targetScreen ? .appAccent : .adaptiveSecondaryText)
                    .frame(width: 24)
                
                Text(text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(currentScreen == targetScreen ? .appAccent : .adaptiveSecondaryText)
                
                Spacer()
            }
        }
    }
}

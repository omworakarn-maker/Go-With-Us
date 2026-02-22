import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @Binding var currentScreen: AppScreen
    @Binding var transition: AnyTransition
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showLogoutAlert = false
    @State private var showLanguageAlert = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Menu Content
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    if let user = authViewModel.currentUser {
                        UserAvatarView(user: user, size: 70)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.name)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.adaptiveText)
                            
                            if let handle = UserDefaults.standard.string(forKey: "user_handle"), !handle.isEmpty {
                                Text("@\(handle)")
                                    .font(.caption)
                                    .foregroundColor(.adaptiveSecondaryText)
                            } else if let email = user.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.adaptiveSecondaryText)
                            }
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.adaptiveSecondaryText)
                        Text("Guest")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.adaptiveText)
                    }
                }
                .padding(.top, 70)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.adaptiveBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 5)
                .padding(.bottom, 20)
                
                // Menu Items
                VStack(alignment: .leading, spacing: 24) {
                    MenuButton(icon: "house", text: LanguageManager.shared.localizedString(for: "home"), targetScreen: .home, currentScreen: $currentScreen, isShowing: $isShowing, transition: $transition)
                    MenuButton(icon: "arrow.triangle.2.circlepath", text: LanguageManager.shared.localizedString(for: "match"), targetScreen: .matchTrip, currentScreen: $currentScreen, isShowing: $isShowing, transition: $transition)
                    MenuButton(icon: "suitcase", text: LanguageManager.shared.localizedString(for: "my_trips"), targetScreen: .myTrips, currentScreen: $currentScreen, isShowing: $isShowing, transition: $transition)
                    MenuButton(icon: "bubble.left.and.text.bubble.right", text: LanguageManager.shared.localizedString(for: "ai_chat"), targetScreen: .aiChat, currentScreen: $currentScreen, isShowing: $isShowing, transition: $transition)
                    MenuButton(icon: "person.crop.circle", text: LanguageManager.shared.localizedString(for: "profile"), targetScreen: .profile, currentScreen: $currentScreen, isShowing: $isShowing, transition: $transition)
                }
                .padding(.horizontal)
                
                Divider().padding(.vertical, 16)
                
                // Settings Header
                VStack(alignment: .leading, spacing: 16) {
                    Text(LanguageManager.shared.localizedString(for: "settings"))
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 24)
                    
                    HStack(spacing: 16) {
                        Image(systemName: "globe")
                            .font(.system(size: 20))
                            .foregroundColor(.adaptiveText)
                            .frame(width: 24)
                        
                        Text("\(LanguageManager.shared.localizedString(for: "language")) (Language)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.adaptiveText)
                        
                        Spacer()
                        
                        Menu {
                            Button(AppLanguage.thai.displayName) {
                                LanguageManager.shared.currentLanguage = .thai
                                showLanguageAlert = true
                            }
                            Button(AppLanguage.english.displayName) {
                                LanguageManager.shared.currentLanguage = .english
                                showLanguageAlert = true
                            }
                        } label: {
                            HStack {
                                Text(LanguageManager.shared.currentLanguage.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                if authViewModel.currentUser != nil {
                    Button(action: { showLogoutAlert = true }) {
                        HStack(spacing: 16) {
                            Image(systemName: "arrow.right.square")
                                .font(.system(size: 20))
                            Text(LanguageManager.shared.localizedString(for: "logout"))
                                .font(.headline)
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .padding(.bottom, 60)
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width * 0.8)
            .background(Color.adaptiveBackground)
        }
        .ignoresSafeArea(.container, edges: .top) // Keep top ignored for full height feel, but respect bottom
        .sheet(isPresented: $showLogoutAlert) {
            LogoutSheet {
                withAnimation {
                    isShowing = false
                }
            }
        }
        .alert(LanguageManager.shared.localizedString(for: "language_change_title"), isPresented: $showLanguageAlert) {
            Button(LanguageManager.shared.localizedString(for: "ok"), role: .cancel) {}
        } message: {
            Text(LanguageManager.shared.localizedString(for: "language_change_message"))
        }
        .tint(.black)
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
                    .foregroundColor(currentScreen == targetScreen ? .adaptiveText : .adaptiveSecondaryText)
                    .frame(width: 24)
                
                Text(text)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(currentScreen == targetScreen ? .adaptiveText : .adaptiveSecondaryText)
                
                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                Group {
                    if currentScreen == targetScreen {
                        Color.adaptiveText.opacity(0.05)
                            .cornerRadius(16)
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .padding(.horizontal, 8)
    }
}

struct LogoutSheet: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    var onLogout: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .font(.system(size: 60))
                .foregroundColor(.red)
                .padding(.top, 32)
            
            VStack(spacing: 8) {
                Text(LanguageManager.shared.localizedString(for: "logout"))
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.adaptiveText)
                
                Text(LanguageManager.shared.localizedString(for: "logout_confirm"))
                    .font(.system(size: 15))
                    .foregroundColor(.adaptiveSecondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            HStack(spacing: 16) {
                Button(action: {
                    dismiss()
                }) {
                    Text(LanguageManager.shared.localizedString(for: "cancel"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.black)
                        .cornerRadius(14)
                }
                
                Button(action: {
                    onLogout()
                    dismiss()
                    authViewModel.logout()
                }) {
                    Text(LanguageManager.shared.localizedString(for: "logout"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .cornerRadius(14)
                        .shadow(color: .red.opacity(0.2), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            
            Spacer()
        }
        .presentationDetents([.height(300)])
    }
}

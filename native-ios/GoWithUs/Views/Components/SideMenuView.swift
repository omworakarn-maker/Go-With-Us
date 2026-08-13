import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @Binding var currentScreen: AppScreen
    @Binding var transition: AnyTransition
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSettings = false
    @State private var showLogoutAlert = false
    @State private var showLanguageAlert = false
    @State private var showResetConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var accountActionMessage: String?
    @State private var isManagingAccount = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background for the entire side menu area - Opaque and covers full height
            Color.adaptiveBackground
                .ignoresSafeArea()
            
            mainMenu
                .disabled(showSettings)
            
            if showSettings {
                settingsMenu
                    .background(Color.adaptiveBackground)
                    .transition(.move(edge: .leading))
                    .zIndex(1)
            }
        }
        .frame(width: min(UIScreen.main.bounds.width * 0.8, 320))
        .background(Color.adaptiveBackground)
        .ignoresSafeArea(.all)
        .sheet(isPresented: $showLogoutAlert) {
            LogoutSheet {
                withAnimation {
                    isShowing = false
                }
            }
        }
        .alert(SettingsManager.shared.localizedString(for: "language_change_title"), isPresented: $showLanguageAlert) {
            Button(SettingsManager.shared.localizedString(for: "ok"), role: .cancel) {}
        } message: {
            Text(SettingsManager.shared.localizedString(for: "language_change_message"))
        }
        .confirmationDialog(
            "รีเซ็ตบัญชีหรือไม่?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("รีเซ็ตบัญชี", role: .destructive) { resetAccount() }
            Button("ยกเลิก", role: .cancel) {}
        } message: {
            Text("ระบบจะล้างโปรไฟล์ แบบสอบถาม ทริป การเข้าร่วม แชท และประวัติการใช้งาน แต่คุณยังเข้าสู่ระบบด้วยอีเมลเดิมได้")
        }
        .confirmationDialog(
            "ลบบัญชีถาวรหรือไม่?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("ลบบัญชีถาวร", role: .destructive) { deleteAccount() }
            Button("ยกเลิก", role: .cancel) {}
        } message: {
            Text("บัญชีและข้อมูลทั้งหมดจะถูกลบถาวรและไม่สามารถกู้คืนได้")
        }
        .alert("จัดการบัญชี", isPresented: Binding(
            get: { accountActionMessage != nil },
            set: { if !$0 { accountActionMessage = nil } }
        )) {
            Button("ตกลง", role: .cancel) { accountActionMessage = nil }
        } message: {
            Text(accountActionMessage ?? "")
        }
        .tint(.black)
    }
    
    // MARK: - Main Menu
    private var mainMenu: some View {
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
                        
                        if let username = user.username, !username.isEmpty {
                            Text("@\(username)")
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
                    Text(SettingsManager.shared.localizedString(for: "guest_user"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.adaptiveText)
                }
            }
            .padding(.top, 60)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.adaptiveBackground)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 5)
            .padding(.bottom, 10)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Menu Items
                    VStack(alignment: .leading, spacing: 16) {
                        MenuButton(icon: "house", text: SettingsManager.shared.localizedString(for: "home"), targetScreen: SettingsManager.shared.homeLayoutPreference, currentScreen: $currentScreen, isShowing: $isShowing, transition: $transition)
                        MenuButton(icon: "heart.fill", text: SettingsManager.shared.currentLanguage == .thai ? "รายการโปรด" : "Favorites", targetScreen: .favorites, currentScreen: $currentScreen, isShowing: $isShowing, transition: $transition)
                        MenuButton(icon: "person.2", text: SettingsManager.shared.currentLanguage == .thai ? "หาเพื่อน" : "Find Buddy", targetScreen: .findBuddy, currentScreen: $currentScreen, isShowing: $isShowing, transition: $transition)
                        MenuButton(icon: "suitcase", text: SettingsManager.shared.localizedString(for: "my_trips"), targetScreen: .myTrips, currentScreen: $currentScreen, isShowing: $isShowing, transition: $transition)
                        MenuButton(icon: "bubble.left.and.text.bubble.right", text: SettingsManager.shared.localizedString(for: "ai_chat"), targetScreen: .aiChat, currentScreen: $currentScreen, isShowing: $isShowing, transition: $transition)
                        MenuButton(icon: "person.crop.circle", text: SettingsManager.shared.localizedString(for: "profile"), targetScreen: .profile, currentScreen: $currentScreen, isShowing: $isShowing, transition: $transition)
                    }
                    .padding(.horizontal)
                    
                    Divider().padding(.vertical, 8)
                    
                    // Settings Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSettings = true
                        }
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 20))
                                .foregroundColor(.adaptiveText)
                                .frame(width: 24)
                            
                            Text(SettingsManager.shared.localizedString(for: "settings"))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.adaptiveText)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                    }
                    
                    if authViewModel.currentUser != nil {
                        Button(action: { showLogoutAlert = true }) {
                            HStack(spacing: 16) {
                                Image(systemName: "arrow.right.square")
                                    .font(.system(size: 20))
                                    .frame(width: 24)
                                
                                Text(SettingsManager.shared.localizedString(for: "logout"))
                                    .font(.system(size: 16, weight: .bold))
                                
                                Spacer()
                            }
                            .foregroundColor(.red)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 24)
                        }
                        .padding(.bottom, 40)
                    }
                }
                .padding(.top, 10)
            }
        }
    }
    
    // MARK: - Settings Menu
    private var settingsMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with Back Button
            VStack(alignment: .leading, spacing: 12) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSettings = false
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                        Text(SettingsManager.shared.localizedString(for: "settings"))
                            .font(.title3)
                            .fontWeight(.black)
                    }
                    .foregroundColor(.adaptiveText)
                }
            }
            .padding(.top, 60)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.adaptiveBackground)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 5)
            .padding(.bottom, 10)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Language Setting
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "globe")
                                .font(.system(size: 20))
                                .foregroundColor(.adaptiveText)
                                .frame(width: 24)
                            
                            Text("\(SettingsManager.shared.localizedString(for: "language"))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.adaptiveText)
                            
                            Spacer()
                            
                            Menu {
                                Button(AppLanguage.thai.displayName) {
                                    SettingsManager.shared.currentLanguage = .thai
                                    showLanguageAlert = true
                                }
                                Button(AppLanguage.english.displayName) {
                                    SettingsManager.shared.currentLanguage = .english
                                    showLanguageAlert = true
                                }
                            } label: {
                                HStack {
                                    Text(SettingsManager.shared.currentLanguage.displayName)
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
                    }
                    .padding(.horizontal, 24)
                    
                    // Vibration Setting
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 20))
                                .foregroundColor(.adaptiveText)
                                .frame(width: 24)
                            
                            Text(SettingsManager.shared.localizedString(for: "vibration"))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.adaptiveText)
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { SettingsManager.shared.isHapticEnabled },
                                set: { SettingsManager.shared.isHapticEnabled = $0 }
                            ))
                            .labelsHidden()
                            .tint(.black)
                        }
                    }
                    .padding(.horizontal, 24)

                    if authViewModel.currentUser != nil {
                        Divider()
                            .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("จัดการบัญชี")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.adaptiveSecondaryText)

                            Button {
                                showResetConfirmation = true
                            } label: {
                                accountManagementRow(
                                    icon: "arrow.counterclockwise.circle",
                                    title: "รีเซ็ตบัญชี",
                                    color: .orange
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isManagingAccount)

                            Button {
                                showDeleteConfirmation = true
                            } label: {
                                accountManagementRow(
                                    icon: "trash",
                                    title: "ลบบัญชีถาวร",
                                    color: .red
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isManagingAccount)

                            if isManagingAccount {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("กำลังดำเนินการ...")
                                        .font(.caption)
                                        .foregroundColor(.adaptiveSecondaryText)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.top, 10)
            }
        }
    }

    private func accountManagementRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .semibold))
                .frame(width: 24)
            Text(title)
                .font(.system(size: 16, weight: .bold))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .opacity(0.5)
        }
        .foregroundColor(color)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func resetAccount() {
        guard !isManagingAccount else { return }
        isManagingAccount = true
        Task {
            do {
                try await AuthService.shared.resetAccount()
                MatchTripViewModel.invalidateCache()
                await authViewModel.loadCurrentUser()
                await MainActor.run {
                    isManagingAccount = false
                    accountActionMessage = "รีเซ็ตบัญชีเรียบร้อยแล้ว กรุณาตอบแบบสอบถามใหม่เพื่อรับคำแนะนำทริป"
                }
            } catch {
                await MainActor.run {
                    isManagingAccount = false
                    accountActionMessage = "รีเซ็ตบัญชีไม่สำเร็จ กรุณาลองใหม่อีกครั้ง"
                }
            }
        }
    }

    private func deleteAccount() {
        guard !isManagingAccount else { return }
        isManagingAccount = true
        Task {
            do {
                try await AuthService.shared.deleteAccount()
                await MainActor.run {
                    isManagingAccount = false
                    showSettings = false
                    isShowing = false
                    authViewModel.logout()
                }
            } catch {
                await MainActor.run {
                    isManagingAccount = false
                    accountActionMessage = "ลบบัญชีไม่สำเร็จ กรุณาลองใหม่อีกครั้ง"
                }
            }
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
    
    private var isSelected: Bool {
        if targetScreen == .home || targetScreen == .homeGrid {
            return currentScreen == .home || currentScreen == .homeGrid
        }
        return currentScreen == targetScreen
    }

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
                    .foregroundColor(isSelected ? .adaptiveText : .adaptiveSecondaryText)
                    .frame(width: 24)
                
                Text(text)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? .adaptiveText : .adaptiveSecondaryText)
                
                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                Group {
                    if isSelected {
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
                Text(SettingsManager.shared.localizedString(for: "logout"))
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.adaptiveText)
                
                Text(SettingsManager.shared.localizedString(for: "logout_confirm"))
                    .font(.system(size: 15))
                    .foregroundColor(.adaptiveSecondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            HStack(spacing: 16) {
                Button(action: {
                    dismiss()
                }) {
                    Text(SettingsManager.shared.localizedString(for: "cancel"))
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
                    Text(SettingsManager.shared.localizedString(for: "logout"))
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

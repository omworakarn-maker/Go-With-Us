import SwiftUI

/// A read-only profile view for viewing other users' profiles
/// Fetches full profile from API using userId
struct UserProfileView: View {
    let user: User  // initial user object (may have incomplete data)
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var fullUser: User? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    // Moderation States
    @State private var showingActionSheet = false
    @State private var showingReportAlert = false
    @State private var reportReason = ""
    @State private var actionMessage = ""
    @State private var showingActionMessage = false
    
    var displayUser: User {
        fullUser ?? user
    }
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground
                .ignoresSafeArea()
            
            // ── Top Navigation Bar (safe area) ──
            VStack {
                HStack {
                    // Back Button
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.adaptiveText)
                            .frame(width: 40, height: 40)
                            .background(Color.adaptiveCardBackground)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    // Action Menu Button
                    if authViewModel.currentUser?.id != user.id {
                        Button(action: { showingActionSheet = true }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.adaptiveText)
                                .frame(width: 40, height: 40)
                                .background(Color.adaptiveCardBackground)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                Spacer()
            }
            .zIndex(100)
            
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.appPrimary)
                    Text("กำลังโหลดโปรไฟล์…")
                        .font(.system(size: 13))
                        .foregroundColor(.adaptiveSecondaryText)
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 40))
                        .foregroundColor(.adaptiveSecondaryText)
                    Text(error)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.adaptiveSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // ── Profile Header ──
                        VStack(spacing: 16) {
                            // Avatar with gradient ring
                            ZStack {
                                Circle()
                                    .strokeBorder(
                                        Color.adaptiveText.opacity(0.1),
                                        lineWidth: 4
                                    )
                                    .frame(width: 110, height: 110)
                                    .background(Circle().fill(Color.adaptiveBackground))
                            
                                UserAvatarView(user: displayUser, size: 100)
                                    .background(Circle().fill(Color.adaptiveBackground))
                            }
                            .padding(.top, 16)
                            
                            VStack(spacing: 5) {
                                Text(displayUser.name)
                                    .font(.system(size: 26, weight: .black))
                                    .foregroundColor(.adaptiveText)
                                
                                if let username = displayUser.username {
                                    Text("@\(username)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.appPrimary)
                                } else if let email = displayUser.email, !email.isEmpty {
                                    Text(email)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.adaptiveSecondaryText)
                                }
                            }
                            
                            if displayUser.role == .admin {
                                HStack(spacing: 5) {
                                    Image(systemName: "shield.checkered")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("ADMIN")
                                        .font(.system(size: 11, weight: .black))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(
                                    LinearGradient(colors: [Color.adaptiveText, Color.adaptiveText.opacity(0.8)],
                                                   startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(20)
                            }
                        }
                        
                        // Verification Status
                        if displayUser.isVerified == true {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                Text("ผู้ใช้งานที่ยืนยันตัวตนแล้ว")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(20)
                        }
                        
                        // ── User Info Cards ──
                        VStack(spacing: 14) {
                            // Gender & Age
                            if displayUser.gender != nil || displayUser.age != nil {
                                HStack(spacing: 12) {
                                    if let gender = displayUser.gender {
                                        infoCard(
                                            icon: "person.fill",
                                            iconColor: Color(hex: "#8B5CF6"),
                                            label: "เพศ",
                                            value: gender == "male" ? "ชาย" : gender == "female" ? "หญิง" : "อื่นๆ"
                                        )
                                    }
                                    
                                    if let age = displayUser.age {
                                        infoCard(
                                            icon: "calendar",
                                            iconColor: Color(hex: "#3B82F6"),
                                            label: "อายุ",
                                            value: "\(age) ปี"
                                        )
                                    }
                                }
                            }
                            
                            // Bio Section
                            if let bio = displayUser.bio, !bio.trimmingCharacters(in: .whitespaces).isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "doc.text.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(hex: "#EC4899"))
                                        Text("ประวัติส่วนตัว")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.adaptiveSecondaryText)
                                            .textCase(.uppercase)
                                    }
                                    
                                    Text(bio)
                                        .font(.system(size: 14))
                                        .foregroundColor(.adaptiveText)
                                        .lineSpacing(4)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.adaptiveCardBackground)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
                            }
                            
                            // Travel Style
                            if let style = displayUser.travelStyle {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "airplane")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(hex: "#0EA5E9"))
                                        Text("สไตล์การเดินทาง")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.adaptiveSecondaryText)
                                            .textCase(.uppercase)
                                    }
                                    
                                    let tags = [
                                        style.budget, style.pace, style.social, style.accommodation,
                                        style.food, style.nightlife, style.transport, style.photography
                                    ].compactMap { $0?.replacingOccurrences(of: "_", with: " ").capitalized }
                                    
                                    if !tags.isEmpty {
                                        FlowLayout(spacing: 8) {
                                            ForEach(tags, id: \.self) { tag in
                                                Text(tag)
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(
                                                        LinearGradient(
                                                            colors: [Color.appPrimary, Color.appSecondary],
                                                            startPoint: .leading, endPoint: .trailing
                                                        )
                                                    )
                                                    .cornerRadius(20)
                                            }
                                        }
                                    } else {
                                        Text("ยังไม่ได้ระบุสไตล์การเดินทาง")
                                            .font(.system(size: 14))
                                            .foregroundColor(.adaptiveSecondaryText)
                                    }
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.adaptiveCardBackground)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
                            }
                            
                            // Interests
                            if let interests = displayUser.interests, !interests.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(hex: "#F43F5E"))
                                        Text("ความสนใจ")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.adaptiveSecondaryText)
                                            .textCase(.uppercase)
                                    }
                                    
                                    FlowLayout(spacing: 8) {
                                        ForEach(interests, id: \.self) { interest in
                                            Text(interest)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.appPrimary)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 7)
                                                .background(Color.appPrimary.opacity(0.08))
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.adaptiveCardBackground)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadProfile()
        }
        .actionSheet(isPresented: $showingActionSheet) {
            var buttons: [ActionSheet.Button] = [
                .destructive(Text("รายงานผู้ใช้ (Report)")) {
                    showingReportAlert = true
                },
                .cancel(Text("ยกเลิก"))
            ]
            
            // If current user is Admin, they can Ban
            if authViewModel.currentUser?.role == .admin {
                buttons.insert(.destructive(Text("แบนผู้ใช้ (Ban)")) {
                    Task { await banUser() }
                }, at: 0)
            }
            
            return ActionSheet(title: Text("จัดการผู้ใช้"), message: nil, buttons: buttons)
        }
        .alert("รายงานผู้ใช้นี้", isPresented: $showingReportAlert) {
            TextField("ระบุเหตุผล (เช่น สแปม, ก้าวร้าว)", text: $reportReason)
            Button("ยกเลิก", role: .cancel) {
                reportReason = ""
            }
            Button("ส่งรายงาน") {
                Task { await reportUser() }
            }
        } message: {
            Text("โปรดระบุเหตุผลที่คุณต้องการรายงานผู้ใช้คนนี้ ข้อมูลจะถูกส่งไปยังแอดมินเพื่อตรวจสอบ")
        }
        .tint(.black)
        .alert(actionMessage, isPresented: $showingActionMessage) {
            Button("ตกลง", role: .cancel) { }
        }
    }
    
    // ── Info Card Helper ──
    @ViewBuilder
    private func infoCard(icon: String, iconColor: Color, label: String, value: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.adaptiveSecondaryText)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.adaptiveText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
    
    private func loadProfile() async {
        isLoading = true
        errorMessage = nil
        
        // If viewing own profile, bypass public fetch and show everything
        if user.id == authViewModel.currentUser?.id {
            if let currentUser = authViewModel.currentUser {
                self.fullUser = currentUser
                self.isLoading = false
                return
            }
        }
        
        do {
            let fetched = try await AuthService.shared.fetchPublicProfile(userId: user.id)
            fullUser = fetched
        } catch let error as APIError {
            switch error {
            case .httpError(403):
                errorMessage = "โปรไฟล์นี้ถูกตั้งเป็นส่วนตัว"
            case .httpError(404):
                errorMessage = "ไม่พบผู้ใช้คนนี้"
            default:
                errorMessage = "ไม่สามารถโหลดโปรไฟล์ได้"
            }
        } catch let error as URLError where error.code == .cancelled {
            return // Ignore cancellation
        } catch {
            errorMessage = "เกิดข้อผิดพลาดในการโหลดโปรไฟล์"
        }
        isLoading = false
    }
    
    // ── Moderation Handlers ──
    private func reportUser() async {
        guard !reportReason.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            try await AuthService.shared.reportUser(userId: user.id, reason: reportReason)
            actionMessage = "ส่งรายงานปัญหาสำเร็จ! แอดมินจะตรวจสอบเร็วๆนี้"
            showingActionMessage = true
            reportReason = ""
        } catch {
            actionMessage = "เกิดข้อผิดพลาดในการรายงาน"
            showingActionMessage = true
        }
    }
    
    private func banUser() async {
        do {
            try await AuthService.shared.banUser(userId: user.id, isBanned: true)
            actionMessage = "ทำการแบนผู้ใช้ท่านนี้เรียบร้อยแล้ว"
            showingActionMessage = true
        } catch {
            actionMessage = "เกิดข้อผิดพลาดในการแบนผู้ใช้"
            showingActionMessage = true
        }
    }
    
}

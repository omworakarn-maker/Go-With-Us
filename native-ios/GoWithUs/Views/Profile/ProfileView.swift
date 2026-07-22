import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEditProfile = false
    @State private var showAdminAlert = false
    @State private var showImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var localProfileImage: UIImage?
    @State private var showQuestionnaire = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                if let user = authViewModel.currentUser {
                    ScrollView {
                        VStack(spacing: 32) {
                            ProfileHeaderView(
                                user: user,
                                selectedItem: $selectedItem,
                                localProfileImage: $localProfileImage
                            )
                            
                            VerificationStatusView(user: user)
                            
                            UserInfoSectionView(
                                user: user,
                                showQuestionnaire: $showQuestionnaire
                            )
                            
                            if user.role == .admin {
                                AdminAlertButton(showAdminAlert: $showAdminAlert)
                            }
                            
                            UserTripsSectionView(user: user)
                            
                            Spacer()
                        }
                        .padding(24)
                        .padding(.bottom, 80) // Space for TabBar
                    }
                } else {
                    LoadingView()
                }
            }
            .navigationTitle(SettingsManager.shared.localizedString(for: "profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(SettingsManager.shared.localizedString(for: "edit")) {
                        showEditProfile = true
                    }
                    .foregroundColor(.appAccent)
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showAdminAlert) {
                AdminAlertView()
            }
            .sheet(isPresented: $showQuestionnaire) {
                QuestionnaireView(onComplete: {
                    Task {
                        await authViewModel.loadCurrentUser()
                    }
                })
                .environmentObject(authViewModel)
            }
            .onAppear {
                loadLocalProfileImage()
            }
        }
    }
    
    private func loadLocalProfileImage() {
        if let userId = authViewModel.currentUser?.id,
           let savedUserId = UserDefaults.standard.string(forKey: "local_profile_image_user_id"),
           userId == savedUserId,
           let data = UserDefaults.standard.data(forKey: "local_profile_image"),
           let image = UIImage(data: data) {
            localProfileImage = image
        } else {
            localProfileImage = nil
        }
    }
    
    // MARK: - Helpers
    static func decodeBase64Image(_ str: String) -> UIImage? {
        let base64Str: String
        if str.contains(",") {
            base64Str = String(str.split(separator: ",").last ?? "")
        } else {
            base64Str = str
        }
        guard let data = Data(base64Encoded: base64Str) else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - Extracted Subviews

struct ProfileHeaderView: View {
    let user: User
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var localProfileImage: UIImage?
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if let image = localProfileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else if let profileImageStr = user.profileImage, !profileImageStr.isEmpty,
                              let uiImage = ProfileView.decodeBase64Image(profileImageStr) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(String(user.name.prefix(1)))
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    Circle()
                        .fill(Color.appAccent)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                        )
                        .offset(x: 2, y: 2)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                handleImageSelection(newItem)
            }
            
            if localProfileImage != nil || (user.profileImage != nil && !user.profileImage!.isEmpty) {
                Button(action: deleteProfileImage) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                        Text(SettingsManager.shared.currentLanguage == .thai ? "ลบรูป" : "Delete")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(16)
                }
                .padding(.top, 4)
            }
            
            VStack(spacing: 4) {
                Text(user.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.adaptiveText)
                
                if let username = user.username {
                    Text("@\(username)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.appAccent)
                }
                
                if let email = user.email {
                    Text(email)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.adaptiveSecondaryText)
                }
            }
            
            if user.role == .admin {
                Text("ADMIN")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.adaptiveBackground)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.adaptiveText)
                    .cornerRadius(20)
            }
        }
        .padding(.top, 32)
    }
    
    private func handleImageSelection(_ newItem: PhotosPickerItem?) {
        Task {
            if let data = try? await newItem?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                localProfileImage = uiImage
                if let jpegData = uiImage.jpegData(compressionQuality: 0.5) {
                    UserDefaults.standard.set(jpegData, forKey: "local_profile_image")
                    UserDefaults.standard.set(user.id, forKey: "local_profile_image_user_id")
                    let base64Str = "data:image/jpeg;base64," + jpegData.base64EncodedString()
                    await authViewModel.updateProfile(
                        name: user.name,
                        interests: user.interests ?? [],
                        profileImage: base64Str
                    )
                }
            }
        }
    }
    
    private func deleteProfileImage() {
        Task {
            localProfileImage = nil
            UserDefaults.standard.removeObject(forKey: "local_profile_image")
            UserDefaults.standard.removeObject(forKey: "local_profile_image_user_id")
            await authViewModel.updateProfile(
                name: user.name,
                interests: user.interests ?? [],
                profileImage: ""
            )
        }
    }
}

struct VerificationStatusView: View {
    let user: User
    var body: some View {
        if user.isVerified == true {
            HStack(spacing: 5) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                Text(SettingsManager.shared.localizedString(for: "verified"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.green.opacity(0.1))
            .cornerRadius(20)
        } else if user.verificationStatus == "pending" {
            HStack(spacing: 5) {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                Text(SettingsManager.shared.currentLanguage == .thai ? "รอตรวจสอบข้อมูล" : "Pending")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(20)
        } else {
            let verificationURL: URL = {
                let base = "https://go-with-us-1.onrender.com/verify"
                guard let token = KeychainService.shared.getToken(),
                      var components = URLComponents(string: base) else {
                    return URL(string: base)!
                }
                components.queryItems = [URLQueryItem(name: "token", value: token)]
                return components.url ?? URL(string: base)!
            }()
            
            Link(destination: verificationURL) {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.shield.fill")
                    Text(SettingsManager.shared.localizedString(for: "not_verified") + (SettingsManager.shared.currentLanguage == .thai ? " (คลิกเพื่อยืนยัน)" : " (Click to verify)"))
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.appPrimary)
                .cornerRadius(20)
            }
            .shadow(color: .appPrimary.opacity(0.3), radius: 5, x: 0, y: 3)
        }
    }
}

struct UserInfoSectionView: View {
    let user: User
    @Binding var showQuestionnaire: Bool
    
    var body: some View {
        VStack(spacing: 14) {
            // Gender & Age
            if user.gender != nil || user.age != nil {
                HStack(spacing: 12) {
                    if let gender = user.gender {
                        infoCard(
                            icon: "person.fill",
                            iconColor: Color(hex: "#8B5CF6"),
                            label: SettingsManager.shared.localizedString(for: "gender"),
                            value: gender == "male" ? (SettingsManager.shared.currentLanguage == .thai ? "ชาย" : "Male") : gender == "female" ? (SettingsManager.shared.currentLanguage == .thai ? "หญิง" : "Female") : (SettingsManager.shared.currentLanguage == .thai ? "อื่นๆ" : "Other")
                        )
                    }
                    
                    if let age = user.age {
                        infoCard(
                            icon: "calendar",
                            iconColor: Color(hex: "#3B82F6"),
                            label: SettingsManager.shared.localizedString(for: "age"),
                            value: "\(age) \(SettingsManager.shared.currentLanguage == .thai ? "ปี" : "Years")"
                        )
                    }
                }
            }
            
            // Bio Section
            if let bio = user.bio, !bio.trimmingCharacters(in: .whitespaces).isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#EC4899"))
                        Text(SettingsManager.shared.localizedString(for: "bio"))
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
            
            // Interests
            if let interests = user.interests, !interests.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#F43F5E"))
                        Text(SettingsManager.shared.localizedString(for: "interests"))
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
            
            // Travel Style
            if let style = user.travelStyle, (style.budget != nil || style.activityStyle != nil || (style.timeOfDay != nil && !style.timeOfDay!.isEmpty)) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#10B981"))
                        Text("สไตล์การเที่ยว")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.adaptiveSecondaryText)
                            .textCase(.uppercase)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        if let b = style.budget {
                            HStack {
                                Text("งบประมาณ:").font(.system(size: 14)).foregroundColor(.secondary).frame(width: 80, alignment: .leading)
                                Text("\(b) ฿").font(.system(size: 14, weight: .semibold)).foregroundColor(.primary)
                            }
                        }
                        if let a = style.activityStyle {
                            HStack {
                                Text("ความลุย:").font(.system(size: 14)).foregroundColor(.secondary).frame(width: 80, alignment: .leading)
                                Text("\(a) / 10").font(.system(size: 14, weight: .semibold)).foregroundColor(.primary)
                            }
                        }
                        if let t = style.timeOfDay, !t.isEmpty {
                            HStack(alignment: .top) {
                                Text("ช่วงเวลา:").font(.system(size: 14)).foregroundColor(.secondary).frame(width: 80, alignment: .leading)
                                Text(timeString(t))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.adaptiveCardBackground)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
            }
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
}

struct AdminAlertButton: View {
    @Binding var showAdminAlert: Bool
    var body: some View {
        Button(action: { showAdminAlert = true }) {
            HStack(spacing: 8) {
                Image(systemName: "bell.badge.fill")
                Text("สร้างการแจ้งเตือน")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(Color.adaptiveBackground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.adaptiveText)
            .cornerRadius(12)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.adaptiveText)
            Text(SettingsManager.shared.currentLanguage == .thai ? "กำลังโหลด..." : "Loading...")
                .foregroundColor(.adaptiveSecondaryText)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}

// MARK: - UserTripsSectionView
struct UserTripsSectionView: View {
    let user: User
    @State private var createdTrips: [Trip] = []
    @State private var joinedTrips: [Trip] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                if !createdTrips.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ทริปที่สร้าง")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.adaptiveText)
                            .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(createdTrips) { trip in
                                    NavigationLink(destination: TripDetailView(tripId: trip.id)) {
                                        TripGridCardView(trip: trip)
                                            .frame(width: 200)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }
                
                if !joinedTrips.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ทริปที่เข้าร่วม")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.adaptiveText)
                            .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(joinedTrips) { trip in
                                    NavigationLink(destination: TripDetailView(tripId: trip.id)) {
                                        TripGridCardView(trip: trip)
                                            .frame(width: 200)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }
            }
        }
        .task {
            await loadTrips()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TripCreated"))) { _ in
            Task {
                await loadTrips()
            }
        }
    }
    
    private func loadTrips() async {
        do {
            async let createdTask = TripService.shared.getAllTrips(creatorId: user.id)
            async let joinedTask = TripService.shared.getAllTrips(participantId: user.id)
            
            let (created, joined) = try await (createdTask, joinedTask)
            
            await MainActor.run {
                self.createdTrips = created
                // Exclude created trips from joined trips
                self.joinedTrips = joined.filter { $0.creator.id != user.id }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            print("Error loading profile trips: \(error)")
        }
    }
    
    private func timeString(_ times: [String]) -> String {
        let map: [String: String] = [
            "morning": "เช้า",
            "noon": "กลางวัน",
            "evening": "เย็น",
            "night": "ดึก"
        ]
        return times.compactMap { map[$0] ?? $0 }.joined(separator: ", ")
    }
}

import SwiftUI
import AVFoundation
import Vision
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject private var settings = SettingsManager.shared
    @State private var showEditProfile = false
    @State private var showAdminAlert = false
    @State private var showImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var localProfileImage: UIImage?
    @State private var showQuestionnaire = false
    @State private var showIdentityVerification = false
    
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
                            
                            VerificationStatusView(user: user, showVerification: $showIdentityVerification)
                            
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
            .navigationTitle(settings.localizedString(for: "profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(settings.localizedString(for: "edit")) {
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
            .sheet(isPresented: $showIdentityVerification) {
                IdentityVerificationView()
                    .environmentObject(authViewModel)
            }
            .onAppear {
                loadLocalProfileImage()
            }
        }
        .id(settings.currentLanguage)
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
    @ObservedObject private var settings = SettingsManager.shared
    
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
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.appPrimary)
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
    @Binding var showVerification: Bool
    @ObservedObject private var settings = SettingsManager.shared
    var body: some View {
        if user.role == .admin {
            HStack(spacing: 5) {
                Image(systemName: "checkmark.shield.fill")
                Text(SettingsManager.shared.currentLanguage == .thai ? "ผู้ดูแลระบบ" : "Administrator")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(.appPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.appPrimary.opacity(0.1))
            .cornerRadius(20)
        } else if user.isVerified == true {
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
            Button {
                showVerification = true
            } label: {
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
    @ObservedObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 14) {
            // Gender & Age
            if user.gender != nil || user.age != nil {
                HStack(spacing: 12) {
                    if let gender = user.gender {
                        infoCard(
                            icon: "person.fill",
                            iconColor: Color.appSecondary,
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
                            .foregroundColor(Color.appSecondary)
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
                            Text(localizedInterestName(interest))
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
                Text(tr("สร้างการแจ้งเตือน", "Create notification"))
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.appPrimary)
            .cornerRadius(12)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.appPrimary)
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
    @ObservedObject private var settings = SettingsManager.shared
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
                        Text(SettingsManager.shared.text(thai: "ทริปที่สร้าง", english: "Created trips"))
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
                        Text(SettingsManager.shared.text(thai: "ทริปที่เข้าร่วม", english: "Joined trips"))
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
}

// MARK: - Identity verification
/// Performs an on-device active-liveness challenge with Apple Vision before
/// accepting a selfie. Email ownership is already verified during registration.
struct IdentityVerificationView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selfie: UIImage?
    @State private var showCamera = false
    @State private var livenessPassed = false
    @State private var isSubmitting = false
    @State private var message = ""
    @State private var showMessage = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    verificationHeader
                    faceVerificationCard
                    submitVerificationButton
                }
                .padding(24)
            }
            .background(Color.adaptiveBackground)
            .navigationTitle(tr("ยืนยันตัวตน", "Identity verification"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button(tr("ปิด", "Close")) { dismiss() } } }
        }
        .fullScreenCover(isPresented: $showCamera) {
            ActiveLivenessView(image: $selfie, passed: $livenessPassed)
        }
        .alert(tr("การยืนยันตัวตน", "Identity verification"), isPresented: $showMessage) {
            Button(tr("ตกลง", "OK")) { if message.contains("ส่งคำขอ") { dismiss() } }
        } message: { Text(message) }
    }

    private var canSubmit: Bool { selfie != nil && livenessPassed }

    private var verificationHeader: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 44))
                .foregroundColor(.appPrimary)
            Text(tr("ยืนยันตัวตนเพื่อความปลอดภัย", "Verify your identity for safety"))
                .font(.title2.bold())
            Text(tr("ทำตามคำแนะนำการขยับใบหน้า แล้วส่งคำขอให้ผู้ดูแลตรวจสอบ", "Follow the face movement instructions, then submit your request for review."))
                .font(.subheadline)
                .foregroundColor(.adaptiveSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    private var faceVerificationCard: some View {
        verificationStep(
            number: "1",
            icon: "person.crop.circle.badge.checkmark",
            title: tr("ตรวจสอบการมีตัวตนด้วยใบหน้า", "Face liveness check"),
            description: tr("ใช้กล้องหน้าในที่สว่าง แล้วทำตามคำแนะนำบนหน้าจอ ระบบจะตรวจการเคลื่อนไหวด้วย Apple Vision", "Use the front camera in a well-lit area and follow the on-screen instructions. Liveness is checked with Apple Vision.")
        ) {
            facePreparationNotice
            selfiePreview
            faceScanButton
        }
    }

    private var facePreparationNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(tr("ก่อนเริ่ม กรุณาถอดแว่น หน้ากาก และหมวก เพื่อให้กล้องมองเห็นใบหน้าอย่างชัดเจน", "Before starting, remove glasses, masks, and hats so your face is clearly visible."))
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color.adaptiveText)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var selfiePreview: some View {
        if let selfie {
            ZStack(alignment: .bottomLeading) {
                Image(uiImage: selfie)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 210)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Label(tr("ตรวจการเคลื่อนไหวผ่านแล้ว", "Liveness check passed"), systemImage: "checkmark.seal.fill")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.92))
                    .clipShape(Capsule())
                    .padding(12)
            }
        } else {
            VStack(spacing: 10) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 42))
                    .foregroundColor(.appSecondary)
                Text(tr("ยังไม่ได้ตรวจการเคลื่อนไหวใบหน้า", "Liveness check not completed"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.adaptiveSecondaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(Color.appSecondary.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var faceScanButton: some View {
        Button(selfie == nil ? tr("เริ่มตรวจใบหน้า", "Start face check") : tr("ตรวจใหม่", "Try again")) {
            showCamera = true
        }
        .font(.subheadline.bold())
        .foregroundColor(.appPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(Color.appPrimary.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var submitVerificationButton: some View {
        Button {
            submit()
        } label: {
            HStack {
                if isSubmitting { ProgressView().tint(.white) }
                Text(isSubmitting ? tr("กำลังส่งคำขอ…", "Submitting…") : tr("ส่งคำขอยืนยันตัวตน", "Submit verification request"))
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(canSubmit ? Color.appPrimary : Color.gray.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!canSubmit || isSubmitting)
    }

    private func verificationStep<Content: View>(number: String, icon: String, title: String, description: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Text(number)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.appPrimary)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 5) {
                    Label(title, systemImage: icon)
                        .font(.headline)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.adaptiveSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            content()
                .padding(.leading, 40)
        }
        .padding(18)
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func submit() {
        guard let selfie else { return }
        Task {
            isSubmitting = true
            defer { isSubmitting = false }
            do {
                try await AuthService.shared.submitIdentityVerification(selfie: selfie)
                await authViewModel.loadCurrentUser()
                message = "ส่งคำขอยืนยันตัวตนแล้ว กรุณารอผู้ดูแลตรวจสอบ"
            } catch {
                message = error.localizedDescription
            }
            showMessage = true
        }
    }
}

private struct ActiveLivenessView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?
    @Binding var passed: Bool
    @State private var instruction = tr("จัดใบหน้าให้อยู่ในกรอบและมองตรง", "Position your face inside the frame and look straight ahead")
    @State private var step = 0
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ActiveLivenessCamera(
                onStatus: { text, currentStep in
                    instruction = text
                    step = currentStep
                    errorMessage = nil
                },
                onComplete: { capturedImage in
                    image = capturedImage
                    passed = true
                    dismiss()
                },
                onError: { errorMessage = $0 }
            )
            .ignoresSafeArea()

            FaceGuideOverlay()
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.55))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(tr("ปิด", "Close"))
                    Spacer()
                }

                Spacer()

                VStack(spacing: 14) {
                    if let errorMessage {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text(errorMessage)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        Button {
                            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                            UIApplication.shared.open(settingsURL)
                        } label: {
                            Label(tr("เปิดการตั้งค่าเพื่ออนุญาตกล้อง", "Open Settings to allow camera access"), systemImage: "gear")
                                .font(.subheadline.bold())
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 11)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                    } else {
                        Text(SettingsManager.shared.currentLanguage == .thai
                             ? "ขั้นตอน \(min(step + 1, 5)) จาก 5"
                             : "Step \(min(step + 1, 5)) of 5")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.75))
                        ProgressView(value: Double(step), total: 5)
                            .tint(.green)
                        Text(instruction)
                            .font(.title3.bold())
                            .multilineTextAlignment(.center)
                    }
                }
                .foregroundColor(.white)
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(.black.opacity(0.68))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(20)
        }
        .onAppear {
            image = nil
            passed = false
        }
    }
}

private struct FaceGuideOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            let guideWidth = min(geometry.size.width * 0.70, 290)
            let guideHeight = min(guideWidth * 1.28, geometry.size.height * 0.48)
            let guideRect = CGRect(
                x: (geometry.size.width - guideWidth) / 2,
                y: max(geometry.safeAreaInsets.top + 72, geometry.size.height * 0.18),
                width: guideWidth,
                height: guideHeight
            )

            Canvas { context, size in
                var dimmedArea = Path(CGRect(origin: .zero, size: size))
                dimmedArea.addEllipse(in: guideRect)
                context.fill(
                    dimmedArea,
                    with: .color(.black.opacity(0.30)),
                    style: FillStyle(eoFill: true)
                )

                context.stroke(
                    Path(ellipseIn: guideRect),
                    with: .color(.white.opacity(0.95)),
                    style: StrokeStyle(lineWidth: 3, dash: [10, 7])
                )
            }

            Text(tr("จัดดวงตา จมูก และคางให้อยู่ภายในกรอบ", "Keep your eyes, nose, and chin inside the frame"))
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.black.opacity(0.58))
                .clipShape(Capsule())
                .position(x: geometry.size.width / 2, y: guideRect.maxY + 24)
        }
    }
}

private struct ActiveLivenessCamera: UIViewControllerRepresentable {
    let onStatus: (String, Int) -> Void
    let onComplete: (UIImage) -> Void
    let onError: (String) -> Void

    func makeUIViewController(context: Context) -> LivenessCameraViewController {
        let controller = LivenessCameraViewController()
        controller.onStatus = onStatus
        controller.onComplete = onComplete
        controller.onError = onError
        return controller
    }

    func updateUIViewController(_ uiViewController: LivenessCameraViewController, context: Context) {}
}

private final class LivenessCameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private enum LivenessChallenge: CaseIterable, Equatable {
        case turnLeft, turnRight, smile

        var instruction: String {
            switch self {
            case .turnLeft: return tr("หันหน้าไปทางซ้ายและค้างไว้", "Turn your face left and hold")
            case .turnRight: return tr("หันหน้าไปทางขวาและค้างไว้", "Turn your face right and hold")
            case .smile: return tr("มองตรงและยิ้มให้เห็นฟัน", "Look straight ahead and smile with your teeth visible")
            }
        }
    }

    var onStatus: ((String, Int) -> Void)?
    var onComplete: ((UIImage) -> Void)?
    var onError: ((String) -> Void)?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.gowithus.liveness.session")
    private let videoQueue = DispatchQueue(label: "com.gowithus.liveness.video")
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var challengeStep = 0
    private var stableFrames = 0
    private var baselinePitch: CGFloat = 0
    private var baselineMouthWidth: CGFloat = 0
    private var baselineMouthOpening: CGFloat = 0
    private var calibrationSamples = 0
    private lazy var challenges = LivenessChallenge.allCases.shuffled()
    private var isProcessingFrame = false
    private var didFinish = false
    private var lastSampleBuffer: CMSampleBuffer?
    private var missingFaceFrames = 0
    private var isShowingTrackingWarning = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [weak self] in self?.session.stopRunning() }
    }

    private func configureCamera() {
        #if targetEnvironment(simulator)
        reportError(tr("การตรวจใบหน้าต้องทดสอบบน iPhone ที่มีกล้องหน้า", "Face verification requires an iPhone with a front camera"))
        return
        #else
        guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil else {
            reportError(tr("การตรวจใบหน้าต้องทดสอบบน iPhone ที่มีกล้องหน้า", "Face verification requires an iPhone with a front camera"))
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                granted ? self?.setupSession() : self?.reportError(tr("กรุณาอนุญาตการใช้กล้องในการตั้งค่า", "Allow camera access in Settings"))
            }
        default:
            reportError(tr("กรุณาอนุญาตการใช้กล้องในการตั้งค่า", "Allow camera access in Settings"))
        }
        #endif
    }

    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            session.beginConfiguration()
            session.sessionPreset = .high

            guard
                let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                let input = try? AVCaptureDeviceInput(device: camera),
                session.canAddInput(input)
            else {
                session.commitConfiguration()
                reportError(tr("ไม่พบกล้องหน้าสำหรับตรวจสอบใบหน้า", "No front camera is available for face verification"))
                return
            }

            session.addInput(input)
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            output.setSampleBufferDelegate(self, queue: videoQueue)

            guard session.canAddOutput(output) else {
                session.commitConfiguration()
                reportError(tr("ไม่สามารถเริ่มระบบตรวจสอบใบหน้าได้", "Unable to start face verification"))
                return
            }
            session.addOutput(output)
            if let connection = output.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
                if connection.isVideoMirroringSupported {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = true
                }
            }
            session.commitConfiguration()

            DispatchQueue.main.async {
                let layer = AVCaptureVideoPreviewLayer(session: self.session)
                layer.videoGravity = .resizeAspectFill
                layer.frame = self.view.bounds
                self.view.layer.insertSublayer(layer, at: 0)
                self.previewLayer = layer
            }
            session.startRunning()
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !didFinish, !isProcessingFrame else { return }
        isProcessingFrame = true
        lastSampleBuffer = sampleBuffer

        let request = VNDetectFaceLandmarksRequest { [weak self] request, _ in
            guard let self else { return }
            defer { self.isProcessingFrame = false }
            guard let face = (request.results as? [VNFaceObservation])?.first else {
                self.stableFrames = 0
                self.missingFaceFrames += 1
                if self.missingFaceFrames >= 6 && !self.isShowingTrackingWarning {
                    self.isShowingTrackingWarning = true
                    self.publishStatus(tr("ไม่พบใบหน้า กรุณาจัดใบหน้าให้อยู่ในกรอบ", "No face detected. Position your face inside the frame."), step: self.challengeStep)
                }
                return
            }
            self.missingFaceFrames = 0
            if self.isShowingTrackingWarning {
                self.isShowingTrackingWarning = false
                self.publishStatus(self.instructionForCurrentStep(), step: self.challengeStep)
            }
            self.evaluate(face: face, sampleBuffer: sampleBuffer)
        }

        do {
            try VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .leftMirrored).perform([request])
        } catch {
            isProcessingFrame = false
        }
    }

    private func evaluate(face: VNFaceObservation, sampleBuffer: CMSampleBuffer) {
        let yaw = CGFloat(face.yaw?.doubleValue ?? 0)
        let pitch = CGFloat(face.pitch?.doubleValue ?? 0)
        let mouthWidth = face.landmarks?.outerLips.map { region in
            let points = region.normalizedPoints
            guard let minimumX = points.map(\.x).min(), let maximumX = points.map(\.x).max() else { return 0 }
            return maximumX - minimumX
        } ?? 0
        let mouthOpening = face.landmarks?.innerLips.map { region in
            let points = region.normalizedPoints
            guard let minimumY = points.map(\.y).min(), let maximumY = points.map(\.y).max() else { return 0 }
            return maximumY - minimumY
        } ?? 0
        let faceLargeEnough = face.boundingBox.width > 0.22 && face.boundingBox.height > 0.22

        guard faceLargeEnough else {
            stableFrames = 0
            if !isShowingTrackingWarning {
                isShowingTrackingWarning = true
                publishStatus(tr("ขยับใบหน้าเข้ามาใกล้กล้องอีกเล็กน้อย", "Move slightly closer to the camera"), step: challengeStep)
            }
            return
        }

        if isShowingTrackingWarning {
            isShowingTrackingWarning = false
            publishStatus(instructionForCurrentStep(), step: challengeStep)
        }

        if challengeStep == 0 {
            if abs(yaw) < 0.14 {
                stableFrames += 1
                baselinePitch += pitch
                if mouthWidth > 0 { baselineMouthWidth += mouthWidth }
                if mouthOpening > 0 { baselineMouthOpening += mouthOpening }
                calibrationSamples += 1
                if stableFrames >= 12 {
                    let divisor = CGFloat(max(calibrationSamples, 1))
                    baselinePitch /= divisor
                    baselineMouthWidth /= divisor
                    baselineMouthOpening /= divisor
                    advance(to: 1, message: challenges[0].instruction)
                }
            } else {
                stableFrames = 0
                baselinePitch = 0
                baselineMouthWidth = 0
                baselineMouthOpening = 0
                calibrationSamples = 0
            }
            return
        }

        if challengeStep >= 1 && challengeStep <= challenges.count {
            evaluate(
                challenge: challenges[challengeStep - 1],
                yaw: yaw,
                mouthWidth: mouthWidth,
                mouthOpening: mouthOpening
            )
            return
        }

        if challengeStep == challenges.count + 1 {
            if abs(yaw) < 0.12 && abs(pitch - baselinePitch) < 0.12 {
                stableFrames += 1
                if stableFrames >= 10 { complete(with: sampleBuffer) }
            } else {
                stableFrames = 0
            }
        }
    }

    private func evaluate(
        challenge: LivenessChallenge,
        yaw: CGFloat,
        mouthWidth: CGFloat,
        mouthOpening: CGFloat
    ) {
        let condition: Bool
        let requiredFrames: Int

        switch challenge {
        case .turnLeft:
            // The Vision request uses `.leftMirrored` for the front camera.
            // Mirroring reverses Vision's horizontal sign on the user-facing preview.
            condition = yaw > 0.30
            requiredFrames = 8
        case .turnRight:
            condition = yaw < -0.30
            requiredFrames = 8
        case .smile:
            // A natural tooth-showing smile only changes Vision's inner-lip
            // landmarks slightly, so keep the threshold above calibration but
            // low enough to work across different mouth shapes and distances.
            let smileThreshold = max(baselineMouthWidth * 1.08, baselineMouthWidth + 0.015)
            let openingThreshold = max(baselineMouthOpening * 1.15, baselineMouthOpening + 0.012)
            condition = abs(yaw) < 0.18
                && mouthWidth > smileThreshold
                && mouthOpening > openingThreshold
            requiredFrames = 8
        }

        if condition {
            stableFrames += 1
            if stableFrames >= requiredFrames {
                let nextStep = challengeStep + 1
                let nextMessage = nextStep <= challenges.count
                    ? challenges[nextStep - 1].instruction
                    : tr("มองหน้าตรงและอยู่นิ่งเพื่อถ่ายรูป", "Look straight ahead and hold still for the photo")
                advance(to: nextStep, message: nextMessage)
            }
        } else {
            stableFrames = 0
        }
    }

    private func advance(to step: Int, message: String) {
        challengeStep = step
        stableFrames = 0
        missingFaceFrames = 0
        isShowingTrackingWarning = false
        publishStatus(message, step: step)
    }

    private func instructionForCurrentStep() -> String {
        if challengeStep == 0 {
            return tr("จัดใบหน้าให้อยู่ในกรอบและมองตรง", "Position your face inside the frame and look straight ahead")
        }
        if challengeStep >= 1 && challengeStep <= challenges.count {
            return challenges[challengeStep - 1].instruction
        }
        return tr("มองหน้าตรงและอยู่นิ่งเพื่อถ่ายรูป", "Look straight ahead and hold still for the photo")
    }

    private func complete(with sampleBuffer: CMSampleBuffer) {
        guard !didFinish, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        didFinish = true
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.leftMirrored)
        let cropRect = centeredPortraitCrop(in: ciImage.extent, aspectRatio: 3.0 / 4.0)
        let croppedImage = ciImage.cropped(to: cropRect)
        let context = CIContext()
        guard let cgImage = context.createCGImage(croppedImage, from: cropRect) else {
            reportError(tr("ไม่สามารถบันทึกภาพยืนยันได้", "Unable to capture the verification photo"))
            return
        }
        let image = UIImage(cgImage: cgImage)
        sessionQueue.async { [weak self] in self?.session.stopRunning() }
        DispatchQueue.main.async { [weak self] in self?.onComplete?(image) }
    }

    private func centeredPortraitCrop(in extent: CGRect, aspectRatio: CGFloat) -> CGRect {
        let currentAspectRatio = extent.width / extent.height

        if currentAspectRatio > aspectRatio {
            let cropWidth = extent.height * aspectRatio
            return CGRect(
                x: extent.midX - cropWidth / 2,
                y: extent.minY,
                width: cropWidth,
                height: extent.height
            ).integral
        }

        let cropHeight = extent.width / aspectRatio
        return CGRect(
            x: extent.minX,
            y: extent.midY - cropHeight / 2,
            width: extent.width,
            height: cropHeight
        ).integral
    }

    private func publishStatus(_ message: String, step: Int) {
        DispatchQueue.main.async { [weak self] in self?.onStatus?(message, step) }
    }

    private func reportError(_ message: String) {
        DispatchQueue.main.async { [weak self] in self?.onError?(message) }
    }
}

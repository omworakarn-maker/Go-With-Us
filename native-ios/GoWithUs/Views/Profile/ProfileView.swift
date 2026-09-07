import SwiftUI
import AVFoundation
import Vision
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
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
            .sheet(isPresented: $showIdentityVerification) {
                IdentityVerificationView()
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
}

// MARK: - Identity verification
/// The flow verifies access to the registered email, then performs a basic
/// on-device active-liveness challenge with Apple Vision before accepting a selfie.
struct IdentityVerificationView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var otp = ""
    @State private var selfie: UIImage?
    @State private var showCamera = false
    @State private var livenessPassed = false
    @State private var isSendingCode = false
    @State private var isSubmitting = false
    @State private var message = ""
    @State private var showMessage = false

    private var email: String { authViewModel.currentUser?.email ?? authViewModel.email }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.appPrimary)
                        Text("ยืนยันตัวตนเพื่อความปลอดภัย")
                            .font(.title2.bold())
                        Text("ยืนยันอีเมลก่อน แล้วทำตามคำแนะนำการขยับใบหน้าเพื่อส่งคำขอให้ผู้ดูแลตรวจสอบ")
                            .font(.subheadline)
                            .foregroundColor(.adaptiveSecondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 4)

                    verificationStep(
                        number: "1", icon: "envelope.badge.fill", title: "ยืนยันอีเมลด้วยรหัส OTP",
                        description: "ระบบจะส่งรหัส 6 หลักไปที่ \(email)"
                    ) {
                        TextField("กรอกรหัส 6 หลัก", text: $otp)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .font(.title3.monospacedDigit().weight(.bold))
                            .multilineTextAlignment(.center)
                            .tint(.appPrimary)
                            .padding(14)
                            .background(Color.adaptiveGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onChange(of: otp) { _, newValue in
                                otp = String(newValue.filter(\.isNumber).prefix(6))
                            }

                        Button {
                            sendOTP()
                        } label: {
                            HStack {
                                if isSendingCode { ProgressView().tint(.white) }
                                Text(isSendingCode ? "กำลังส่งรหัส…" : "ส่งรหัสไปยังอีเมล")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.appPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isSendingCode)
                    }

                    verificationStep(
                        number: "2", icon: "person.crop.circle.badge.checkmark", title: "ตรวจสอบการมีตัวตนด้วยใบหน้า",
                        description: "ใช้กล้องหน้าในที่สว่าง แล้วมองตรงและหันหน้าตามคำแนะนำ ระบบจะตรวจการเคลื่อนไหวด้วย Apple Vision"
                    ) {
                        if let selfie {
                            ZStack(alignment: .bottomLeading) {
                                Image(uiImage: selfie)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 210)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))

                                Label("ตรวจการเคลื่อนไหวผ่านแล้ว", systemImage: "checkmark.seal.fill")
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
                                Text("ยังไม่ได้ตรวจการเคลื่อนไหวใบหน้า")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.adaptiveSecondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .background(Color.appSecondary.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        Button(selfie == nil ? "เริ่มตรวจใบหน้า" : "ตรวจใหม่") {
                            showCamera = true
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.appPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.appPrimary.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        submit()
                    } label: {
                        HStack {
                            if isSubmitting { ProgressView().tint(.white) }
                            Text(isSubmitting ? "กำลังส่งคำขอ…" : "ส่งคำขอยืนยันตัวตน")
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
                .padding(24)
            }
            .background(Color.adaptiveBackground)
            .navigationTitle("ยืนยันตัวตน")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("ปิด") { dismiss() } } }
        }
        .fullScreenCover(isPresented: $showCamera) {
            ActiveLivenessView(image: $selfie, passed: $livenessPassed)
        }
        .alert("การยืนยันตัวตน", isPresented: $showMessage) {
            Button("ตกลง") { if message.contains("ส่งคำขอ") { dismiss() } }
        } message: { Text(message) }
    }

    private var canSubmit: Bool { otp.count == 6 && selfie != nil && livenessPassed }

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

    private func sendOTP() {
        Task {
            isSendingCode = true
            defer { isSendingCode = false }
            do {
                try await AuthService.shared.sendIdentityVerificationOTP()
                message = "ส่งรหัสยืนยันไปยังอีเมลแล้ว รหัสมีอายุ 10 นาที"
            } catch {
                message = error.localizedDescription
            }
            showMessage = true
        }
    }

    private func submit() {
        guard let selfie else { return }
        Task {
            isSubmitting = true
            defer { isSubmitting = false }
            do {
                try await AuthService.shared.submitIdentityVerification(otp: otp, selfie: selfie)
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
    @State private var instruction = "จัดใบหน้าให้อยู่ในกรอบและมองตรง"
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
                    .accessibilityLabel("ปิด")
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
                    } else {
                        Text("ขั้นตอน \(min(step + 1, 4)) จาก 4")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.75))
                        ProgressView(value: Double(step), total: 4)
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
    var onStatus: ((String, Int) -> Void)?
    var onComplete: ((UIImage) -> Void)?
    var onError: ((String) -> Void)?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.gowithus.liveness.session")
    private let videoQueue = DispatchQueue(label: "com.gowithus.liveness.video")
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var challengeStep = 0
    private var stableFrames = 0
    private var firstTurnDirection: CGFloat?
    private var isProcessingFrame = false
    private var didFinish = false
    private var lastSampleBuffer: CMSampleBuffer?

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
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            reportError("การตรวจใบหน้าต้องทดสอบบน iPhone ที่มีกล้องหน้า")
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                granted ? self?.setupSession() : self?.reportError("กรุณาอนุญาตการใช้กล้องในการตั้งค่า")
            }
        default:
            reportError("กรุณาอนุญาตการใช้กล้องในการตั้งค่า")
        }
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
                reportError("ไม่พบกล้องหน้าสำหรับตรวจสอบใบหน้า")
                return
            }

            session.addInput(input)
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            output.setSampleBufferDelegate(self, queue: videoQueue)

            guard session.canAddOutput(output) else {
                session.commitConfiguration()
                reportError("ไม่สามารถเริ่มระบบตรวจสอบใบหน้าได้")
                return
            }
            session.addOutput(output)
            if let connection = output.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
                if connection.isVideoMirroringSupported {
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

        let request = VNDetectFaceRectanglesRequest { [weak self] request, _ in
            guard let self else { return }
            defer { self.isProcessingFrame = false }
            guard let face = (request.results as? [VNFaceObservation])?.first else {
                self.stableFrames = 0
                self.publishStatus("ไม่พบใบหน้า กรุณามองกล้องและอยู่ในที่สว่าง", step: self.challengeStep)
                return
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
        let faceLargeEnough = face.boundingBox.width > 0.22 && face.boundingBox.height > 0.22

        guard faceLargeEnough else {
            stableFrames = 0
            publishStatus("ขยับใบหน้าเข้ามาใกล้กล้องอีกเล็กน้อย", step: challengeStep)
            return
        }

        switch challengeStep {
        case 0:
            check(abs(yaw) < 0.14, requiredFrames: 8, nextMessage: "หันหน้าไปด้านใดด้านหนึ่ง")
        case 1:
            if abs(yaw) > 0.28 {
                firstTurnDirection = yaw > 0 ? 1 : -1
                advance(to: 2, message: "หันหน้ากลับไปอีกด้าน")
            } else {
                stableFrames = 0
            }
        case 2:
            if let firstTurnDirection, yaw * firstTurnDirection < -0.20 {
                advance(to: 3, message: "มองตรงและอยู่นิ่ง")
            } else {
                stableFrames = 0
            }
        case 3:
            if abs(yaw) < 0.12 {
                stableFrames += 1
                if stableFrames >= 10 { complete(with: sampleBuffer) }
            } else {
                stableFrames = 0
            }
        default:
            break
        }
    }

    private func check(_ condition: Bool, requiredFrames: Int, nextMessage: String) {
        if condition {
            stableFrames += 1
            if stableFrames >= requiredFrames {
                advance(to: challengeStep + 1, message: nextMessage)
            }
        } else {
            stableFrames = 0
        }
    }

    private func advance(to step: Int, message: String) {
        challengeStep = step
        stableFrames = 0
        publishStatus(message, step: step)
    }

    private func complete(with sampleBuffer: CMSampleBuffer) {
        guard !didFinish, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        didFinish = true
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.leftMirrored)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            reportError("ไม่สามารถบันทึกภาพยืนยันได้")
            return
        }
        let image = UIImage(cgImage: cgImage)
        sessionQueue.async { [weak self] in self?.session.stopRunning() }
        DispatchQueue.main.async { [weak self] in self?.onComplete?(image) }
    }

    private func publishStatus(_ message: String, step: Int) {
        DispatchQueue.main.async { [weak self] in self?.onStatus?(message, step) }
    }

    private func reportError(_ message: String) {
        DispatchQueue.main.async { [weak self] in self?.onError?(message) }
    }
}

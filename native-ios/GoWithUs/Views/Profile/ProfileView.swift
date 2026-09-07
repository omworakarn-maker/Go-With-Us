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
/// The flow verifies access to the registered email before accepting a selfie.
/// Face liveness is intentionally not claimed here: it requires a dedicated
/// liveness provider before the server may treat this as bank-grade verification.
struct IdentityVerificationView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var otp = ""
    @State private var selfie: UIImage?
    @State private var showCamera = false
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
                        Text("ยืนยันอีเมลก่อน แล้วจึงถ่ายเซลฟี่เพื่อส่งคำขอให้ผู้ดูแลตรวจสอบ")
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
                        number: "2", icon: "person.crop.circle.badge.checkmark", title: "ถ่ายเซลฟี่ยืนยันใบหน้า",
                        description: "ใช้กล้องหน้า ถ่ายในที่สว่าง มองตรง เห็นใบหน้าชัดเจน และไม่สวมหน้ากากหรือแว่นกันแดด"
                    ) {
                        if let selfie {
                            Image(uiImage: selfie)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 210)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            VStack(spacing: 10) {
                                Image(systemName: "face.smiling")
                                    .font(.system(size: 42))
                                    .foregroundColor(.appSecondary)
                                Text("ยังไม่ได้ถ่ายเซลฟี่")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.adaptiveSecondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .background(Color.appSecondary.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        Button(selfie == nil ? "เปิดกล้องหน้า" : "ถ่ายใหม่") {
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
        .sheet(isPresented: $showCamera) {
            SelfieCameraPicker(image: $selfie)
                .ignoresSafeArea()
        }
        .alert("การยืนยันตัวตน", isPresented: $showMessage) {
            Button("ตกลง") { if message.contains("ส่งคำขอ") { dismiss() } }
        } message: { Text(message) }
    }

    private var canSubmit: Bool { otp.count == 6 && selfie != nil }

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

private struct SelfieCameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.cameraDevice = .front
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SelfieCameraPicker
        init(parent: SelfieCameraPicker) { self.parent = parent }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }
    }
}

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var username: String = ""
    @State private var usernameStatus: UsernameStatus = .idle
    @State private var checkTask: Task<Void, Never>?
    
    enum UsernameStatus {
        case idle
        case checking
        case available
        case taken(String)
        case invalid(String)
    }

    private func checkUsername(_ value: String) {
        checkTask?.cancel()
        
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty {
            usernameStatus = .idle
            return
        }
        
        if cleaned.count < 3 {
            usernameStatus = .invalid("ขั้นต่ำ 3 ตัวอักษร")
            return
        }

        usernameStatus = .checking
        
        checkTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
            if Task.isCancelled { return }
            
            do {
                let result = try await AuthService.shared.checkUsernameAvailability(
                    username: cleaned,
                    excludeUserId: authViewModel.currentUser?.id
                )
                
                await MainActor.run {
                    if result.available {
                        usernameStatus = .available
                    } else {
                        // Allow save even if checking username if the username isn't being changed
                        let originalUsername = authViewModel.currentUser?.username ?? ""
                        
                        // If the username is taken, but it's the user's current username,
                        // and the user hasn't changed it, then it's still considered valid for saving.
                        if cleaned == originalUsername {
                            usernameStatus = .available // Treat as available if it's their own existing username
                        } else {
                            usernameStatus = .taken(result.message)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    usernameStatus = .idle
                }
            }
        }
    }
    
    @State private var selectedInterests: Set<String> = []
    @State private var gender: String = ""
    @State private var bio: String = ""
    @State private var birthDate = Date()
    @State private var showBirthDatePicker = false
    @State private var showQuiz = false
    
    // Privacy settings
    @State private var isProfilePublic = true
    @State private var showGender = true
    @State private var showAge = true
    @State private var showBio = true
    @State private var showInterests = true
    @State private var showEmail = false
    
    // Photo picker
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Image Section
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                if let image = profileImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 90, height: 90)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.black)
                                        .frame(width: 90, height: 90)
                                        .overlay(
                                            Text(String(name.prefix(1)))
                                                .font(.system(size: 36, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                }
                                
                                Circle()
                                    .fill(Color.appAccent)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 2, y: 2)
                            }
                        }
                        .onChange(of: selectedItem) { oldItem, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    profileImage = uiImage
                                }
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section(header: Text("ข้อมูลส่วนตัว")) {
                    TextField("ชื่อ", text: $name)
                        .font(.system(size: 16, weight: .medium))
                    
                    // @ Handle / Username
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("@")
                                .foregroundColor(.adaptiveSecondaryText)
                                .font(.system(size: 16, weight: .medium))
                            if let originalUsername = authViewModel.currentUser?.username, !originalUsername.isEmpty {
                                Text(originalUsername)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                               Spacer()
                                Text("ตั้งแล้วเปลี่ยนไม่ได้")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else {
                                TextField("ตั้งได้ครั้งเดียวเท่านั้น", text: $username)
                                    .font(.system(size: 16, weight: .medium))
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .onChange(of: username) { oldValue, newValue in
                                        checkUsername(newValue)
                                    }
                            }
                            
                            // Status Icon
                            switch usernameStatus {
                            case .checking:
                                ProgressView().scaleEffect(0.7)
                            case .available:
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            case .taken, .invalid:
                                Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                            case .idle:
                                EmptyView()
                            }
                        }
                        
                        // Status Text
                        Group {
                            switch usernameStatus {
                            case .taken(let msg):
                                Text(msg).foregroundColor(.red)
                            case .invalid(let msg):
                                Text(msg).foregroundColor(.red)
                            case .available:
                                Text("Username นี้ใช้ได้").foregroundColor(.green)
                            default:
                                EmptyView()
                            }
                        }
                        .font(.system(size: 10, weight: .bold))
                    }
                    
                    // Gender Selection
                    Picker("เพศ", selection: $gender) {
                        Text("-- เลือกเพศ --").tag("")
                        Text("ชาย").tag("male")
                        Text("หญิง").tag("female")
                        Text("อื่นๆ").tag("other")
                    }
                    .font(.system(size: 16, weight: .medium))
                    
                    // Age is removed, computed from birth date
                    
                    // Birth Date Picker
                    HStack {
                        Text("วันเกิด")
                        Spacer()
                        DatePicker(
                            "",
                            selection: $birthDate,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }
                }
                
                Section(header: Text("ประวัติส่วนตัว")) {
                    TextEditor(text: $bio)
                            .frame(height: 100)
                            .font(.system(size: 16, weight: .regular))
                        Text("\(bio.count) / 500")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.adaptiveSecondaryText)
                }
                
                Section(header: Text("Lifestyle & Travel Style")) {
                    Button(action: { showQuiz = true }) {
                        HStack {
                            Image(systemName: "pencil.and.outline")
                            Text("ทำแบบสำรวจไลฟ์สไตล์ใหม่")
                                .fontWeight(.bold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.adaptiveSecondaryText)
                        }
                    }
                    .foregroundColor(.adaptiveText)
                    
                    if let style = authViewModel.currentUser?.travelStyle {
                        let tags = [style.budget, style.pace, style.social, style.accommodation].compactMap { $0 }
                        if !tags.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color.adaptiveBackground)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.adaptiveText)
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                Section(header: Text("สิ่งที่สนใจ (เลือกได้หลายข้อ)")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                        ForEach(INTEREST_CATEGORIES) { cat in
                            InterestTag(

                                label: cat.label,
                                icon: cat.icon,
                                isSelected: selectedInterests.contains(cat.label)
                            ) {
                                if selectedInterests.contains(cat.label) {
                                    selectedInterests.remove(cat.label)
                                } else {
                                    selectedInterests.insert(cat.label)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("ตั้งค่าความเป็นส่วนตัว")) {
                    Toggle("เปิดโปรไฟล์สาธารณะ", isOn: $isProfilePublic)
                        .font(.system(size: 14, weight: .medium))
                    
                    if isProfilePublic {
                        Toggle("แสดงเพศ", isOn: $showGender)
                            .font(.system(size: 14, weight: .medium))
                        Toggle("แสดงอายุ", isOn: $showAge)
                            .font(.system(size: 14, weight: .medium))
                        Toggle("แสดงประวัติส่วนตัว", isOn: $showBio)
                            .font(.system(size: 14, weight: .medium))
                        Toggle("แสดงความสนใจ", isOn: $showInterests)
                            .font(.system(size: 14, weight: .medium))
                        Toggle("แสดงอีเมล", isOn: $showEmail)
                            .font(.system(size: 14, weight: .medium))
                    } else {
                        Text("โปรไฟล์ถูกซ่อนจากผู้ใช้คนอื่น")
                            .font(.system(size: 12))
                            .foregroundColor(.adaptiveSecondaryText)
                    }
                }
                

            }
            .navigationTitle("แก้ไขโปรไฟล์")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ยกเลิก") { dismiss() }
                        .foregroundColor(.appAccent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        Task {
                            // Convert profile image to base64 for backend
                            var profileImageBase64: String? = nil
                            if selectedItem != nil, let image = profileImage,
                               let scaledImage = image.resized(toWidth: 512),
                               let jpegData = scaledImage.jpegData(compressionQuality: 0.6) {
                                // Save locally as cache
                                UserDefaults.standard.set(jpegData, forKey: "local_profile_image")
                                // Convert to base64 data URI for backend
                                profileImageBase64 = "data:image/jpeg;base64," + jpegData.base64EncodedString()
                            }
                            
                            let calendar = Calendar.current
                            let ageInt = calendar.dateComponents([.year], from: birthDate, to: Date()).year
                            
                            await authViewModel.updateProfile(
                                name: name,
                                username: username.isEmpty ? nil : username,
                                interests: Array(selectedInterests),
                                gender: gender,
                                age: ageInt,
                                bio: bio,
                                birthDate: birthDate,
                                travelStyle: authViewModel.currentUser?.travelStyle,
                                profileImage: profileImageBase64
                            )
                            
                            // Save privacy settings
                            try? await AuthService.shared.updatePrivacySettings(
                                isProfilePublic: isProfilePublic,
                                showGender: showGender,
                                showAge: showAge,
                                showBio: showBio,
                                showInterests: showInterests,
                                showEmail: showEmail
                            )
                            
                            // Refresh current user logic to sync entirely with DB
                            await authViewModel.loadCurrentUser()
                            
                            dismiss()
                        }
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.appAccent)
                        } else {
                            Text("บันทึก")
                        }
                    }
                    .foregroundColor(.appAccent)
                    .disabled(authViewModel.isLoading || name.trimmingCharacters(in: .whitespaces).isEmpty || isUsernameInvalid)
                }
            }
            .tint(.black)
            .onAppear {
                if let user = authViewModel.currentUser {
                    name = user.name
                    username = user.username ?? ""
                    selectedInterests = Set(user.interests ?? [])
                    gender = user.gender ?? ""
                    bio = user.bio ?? ""
                    if let birthDate = user.birthDate {
                        self.birthDate = birthDate
                    }
                    
                    // Load privacy settings
                    self.isProfilePublic = user.isProfilePublic ?? true
                    self.showGender = user.showGender ?? true
                    self.showAge = user.showAge ?? true
                    self.showBio = user.showBio ?? true
                    self.showInterests = user.showInterests ?? true
                    self.showEmail = user.showEmail ?? false
                }
                // Load saved image (local cache first, then backend)
                if let data = UserDefaults.standard.data(forKey: "local_profile_image"),
                   let image = UIImage(data: data) {
                    profileImage = image
                } else if let profileImageStr = authViewModel.currentUser?.profileImage,
                          !profileImageStr.isEmpty,
                          let image = ProfileView.decodeBase64Image(profileImageStr) {
                    profileImage = image
                }
            }
            .sheet(isPresented: $showQuiz) {
                TravelStyleQuizView()
                    .environmentObject(authViewModel)
            }
        }
    }
    private var isUsernameInvalid: Bool {
        switch usernameStatus {
        case .taken, .invalid: return true
        default: return false
        }
    }
}

struct InterestTag: View {
    let label: String
    let icon: String // Changed variable name
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon) // Using SF Symbol
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 12, weight: .bold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.adaptiveText : Color.adaptiveCardTint)
            .foregroundColor(isSelected ? Color.adaptiveBackground : .adaptiveText)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.adaptiveText : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


#Preview {
    EditProfileView()
        .environmentObject(AuthViewModel())
}

// MARK: - UIImage Extension
extension UIImage {
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

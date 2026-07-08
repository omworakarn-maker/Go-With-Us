import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    let targetUser: User?
    
    init(targetUser: User? = nil) {
        self.targetUser = targetUser
    }
    
    @State private var name: String = ""
    @State private var username: String = ""
    @State private var usernameStatus: UsernameStatus = .idle
    @State private var checkTask: Task<Void, Never>?
    
    enum UsernameStatus: Equatable {
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
        
        // If it's the current username, it's available (no change)
        if cleaned == authViewModel.currentUser?.username {
            usernameStatus = .available
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
                        usernameStatus = .taken(result.message)
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
    
    // Photo picker (6 slots)
    @State private var selectedItems: [PhotosPickerItem?] = Array(repeating: nil, count: 6)
    @State private var profileImages: [UIImage?] = Array(repeating: nil, count: 6)
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Image Section
                Section(header: Text("รูปโปรไฟล์ (สูงสุด 6 รูป)")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 16) {
                        ForEach(0..<6, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                PhotosPicker(selection: Binding(
                                    get: { selectedItems[index] },
                                    set: { selectedItems[index] = $0 }
                                ), matching: .images) {
                                    if let image = profileImages[index] {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .frame(height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .frame(height: 120)
                                            .overlay(
                                                Image(systemName: "plus")
                                                    .font(.system(size: 24, weight: .bold))
                                                    .foregroundColor(.gray.opacity(0.6))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                                    .foregroundColor(.gray.opacity(0.3))
                                            )
                                    }
                                }
                                .onChange(of: selectedItems[index]) { oldItem, newItem in
                                    Task {
                                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                                           let uiImage = UIImage(data: data) {
                                            await MainActor.run {
                                                profileImages[index] = uiImage
                                            }
                                        }
                                    }
                                }
                                
                                if profileImages[index] != nil {
                                    Button(action: {
                                        profileImages[index] = nil
                                        selectedItems[index] = nil
                                    }) {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .offset(x: 8, y: -8)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
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
                            
                            if let user = authViewModel.currentUser, 
                               let updatedAt = user.usernameUpdatedAt,
                               let thirtyDaysLater = Calendar.current.date(byAdding: .day, value: 30, to: updatedAt),
                               thirtyDaysLater > Date() {
                                
                                // Can't change yet
                                Text(username)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("เปลี่ยนได้อีกครั้ง:")
                                        .font(.system(size: 10))
                                    Text(thirtyDaysLater, style: .date)
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(.red)
                            } else {
                                TextField(authViewModel.currentUser?.username == nil ? "ตั้งได้ครั้งเดียว (เปลี่ยนได้ทุก 30 วัน)" : "เปลี่ยน username", text: $username)
                                    .font(.system(size: 16, weight: .medium))
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .onChange(of: username) { oldValue, newValue in
                                        checkUsername(newValue)
                                    }
                            }
                            
                            switch usernameStatus {
                            case .checking:
                                ProgressView().scaleEffect(0.7)
                            case .available:
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            case .taken, .invalid:
                                Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                            default:
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
                            case .idle:
                                if authViewModel.currentUser?.username != nil {
                                    Text("สามารถเปลี่ยนได้ทุก 30 วัน").foregroundColor(.gray)
                                } else {
                                    Text("Username ต้องไม่ซ้ำกับผู้อื่น").foregroundColor(.gray)
                                }
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
                        let tags: [String] = {
                            var t: [String] = []
                            if let b = style.budget { t.append("Budget \(b)/10") }
                            if let a = style.activityStyle { t.append("Activity \(a)/10") }
                            if let time = style.timeOfDay {
                                t.append(contentsOf: time.map { $0.capitalized })
                            }
                            return t
                        }()
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
                            // Convert profile images to base64 for backend
                            var profileImageBase64: String? = nil
                            var galleryBase64: [String] = []
                            
                            let userId = targetUser?.id ?? authViewModel.currentUser?.id ?? "unknown"
                            
                            if let mainImage = profileImages[0],
                               let scaledImage = mainImage.resized(toWidth: 512),
                               let jpegData = scaledImage.jpegData(compressionQuality: 0.6) {
                                profileImageBase64 = "data:image/jpeg;base64," + jpegData.base64EncodedString()
                                UserDefaults.standard.set(jpegData, forKey: "local_profile_image_\(userId)")
                            }
                            
                            for i in 1..<6 {
                                if let img = profileImages[i],
                                   let scaledImage = img.resized(toWidth: 512),
                                   let jpegData = scaledImage.jpegData(compressionQuality: 0.6) {
                                    galleryBase64.append("data:image/jpeg;base64," + jpegData.base64EncodedString())
                                }
                            }
                            
                            let calendar = Calendar.current
                            let ageInt = calendar.dateComponents([.year], from: birthDate, to: Date()).year
                            
                            if let target = targetUser {
                                // Admin editing another user
                                try? await authViewModel.adminUpdateProfile(
                                    userId: target.id,
                                    name: name,
                                    username: username.isEmpty ? nil : username,
                                    interests: Array(selectedInterests),
                                    gender: gender,
                                    age: ageInt,
                                    bio: bio,
                                    birthDate: birthDate,
                                    travelStyle: target.travelStyle, // Keep their style or use what's in VM
                                    profileImage: profileImageBase64,
                                    gallery: galleryBase64.isEmpty ? nil : galleryBase64
                                )
                            } else {
                                // Default self-update
                                await authViewModel.updateProfile(
                                    name: name,
                                    username: username.isEmpty ? nil : username,
                                    interests: Array(selectedInterests),
                                    gender: gender,
                                    age: ageInt,
                                    bio: bio,
                                    birthDate: birthDate,
                                    travelStyle: authViewModel.currentUser?.travelStyle,
                                    profileImage: profileImageBase64,
                                    gallery: galleryBase64.isEmpty ? nil : galleryBase64
                                )
                            }
                            
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
                let userToEdit = targetUser ?? authViewModel.currentUser
                if let user = userToEdit {
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
                
                // Load saved images
                if let userId = userToEdit?.id,
                   let data = UserDefaults.standard.data(forKey: "local_profile_image_\(userId)"),
                   let image = UIImage(data: data) {
                    profileImages[0] = image
                } else if let profileImageStr = userToEdit?.profileImage,
                          !profileImageStr.isEmpty,
                          let image = ProfileView.decodeBase64Image(profileImageStr) {
                    profileImages[0] = image
                }
                
                if let gallery = userToEdit?.gallery {
                    for (i, str) in gallery.prefix(5).enumerated() {
                        if !str.isEmpty, let image = ProfileView.decodeBase64Image(str) {
                            profileImages[i+1] = image
                        }
                    }
                }
            }
            .sheet(isPresented: $showQuiz) {
                QuestionnaireView()
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
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, 1.0) // Use 1.0 scale to get exact pixel width
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @ObservedObject private var settings = SettingsManager.shared
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
    @FocusState private var isBioFocused: Bool
    @State private var birthDate = Date()
    @State private var isBirthDateSet = false
    @State private var showBirthDatePicker = false
    @State private var showQuiz = false
    
    // Travel Style variables
    @State private var budget: Double = 1500
    private let budgetSteps: [Double] = [
        100, 300, 500, 1000, 1500, 2000, 2500, 3000, 4000, 5000,
        6000, 7000, 8000, 10000, 15000, 20000, 30000, 50000
    ]
    private var budgetSliderBinding: Binding<Double> {
        Binding<Double>(
            get: {
                let closest = budgetSteps.enumerated().min(by: { abs($0.element - budget) < abs($1.element - budget) })?.offset ?? 0
                return Double(closest)
            },
            set: { newValue in
                let index = min(max(Int(newValue), 0), budgetSteps.count - 1)
                let newBudget = budgetSteps[index]
                if budget != newBudget {
                    budget = newBudget
                }
            }
        )
    }
    @State private var activityStyle: Double = 3
    @State private var timeOfDay: [String] = []
    
    var timeOptions: [(String, String)] {
        SettingsManager.shared.currentLanguage == .thai
            ? [("morning", "เช้า"), ("noon", "กลางวัน"), ("evening", "เย็น"), ("night", "ดึก")]
            : [("morning", "Morning"), ("noon", "Afternoon"), ("evening", "Evening"), ("night", "Night")]
    }
    
    // Privacy settings
    @State private var isProfilePublic = true
    @State private var showGender = true
    @State private var showAge = true
    @State private var showBio = true
    @State private var showInterests = true
    @State private var showEmail = false
    
    // Photo picker (6 slots)
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoSlot: Int?
    @State private var showPhotoPicker = false
    @State private var profileImages: [UIImage?] = Array(repeating: nil, count: 6)
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Image Section
                Section(header: Text(SettingsManager.shared.text(thai: "รูปโปรไฟล์ (สูงสุด 6 รูป)", english: "Profile photos (up to 6)"))) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 16) {
                        ForEach(0..<6, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Button {
                                    selectedPhotoSlot = index
                                    selectedPhotoItem = nil
                                    showPhotoPicker = true
                                } label: {
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
                                .buttonStyle(.plain)
                                
                                if profileImages[index] != nil {
                                    Button(action: {
                                        profileImages[index] = nil
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
                                    .padding(6)
                                }
                            }
                        }
                    }
                    .photosPicker(
                        isPresented: $showPhotoPicker,
                        selection: $selectedPhotoItem,
                        matching: .images
                    )
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        guard let newItem, let targetSlot = selectedPhotoSlot else { return }
                        Task {
                            guard let data = try? await newItem.loadTransferable(type: Data.self),
                                  let uiImage = UIImage(data: data) else { return }
                            await MainActor.run {
                                profileImages[targetSlot] = uiImage
                                selectedPhotoItem = nil
                                selectedPhotoSlot = nil
                                showPhotoPicker = false
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                
                Section(header: Text(SettingsManager.shared.text(thai: "ข้อมูลส่วนตัว", english: "Personal information"))) {
                    TextField(SettingsManager.shared.text(thai: "ชื่อ", english: "Name"), text: $name)
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
                                    Text(SettingsManager.shared.text(thai: "เปลี่ยนได้อีกครั้ง:", english: "Can be changed again:"))
                                        .font(.system(size: 10))
                                    Text(thirtyDaysLater, style: .date)
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(.red)
                            } else {
                                TextField(authViewModel.currentUser?.username == nil ? tr("ตั้งได้ครั้งเดียว (เปลี่ยนได้ทุก 30 วัน)", "Set a username (changeable every 30 days)") : tr("เปลี่ยน username", "Change username"), text: $username)
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
                                Text(SettingsManager.shared.localizedString(for: "username_available")).foregroundColor(.green)
                            case .idle:
                                if authViewModel.currentUser?.username != nil {
                                    Text(SettingsManager.shared.text(thai: "สามารถเปลี่ยนได้ทุก 30 วัน", english: "Can be changed every 30 days")).foregroundColor(.gray)
                                } else {
                                    Text(SettingsManager.shared.localizedString(for: "username_taken")).foregroundColor(.gray)
                                }
                            default:
                                EmptyView()
                            }
                        }
                        .font(.system(size: 10, weight: .bold))
                    }
                    
                    // Gender Selection
                    Picker(tr("เพศ", "Gender"), selection: $gender) {
                        Text(SettingsManager.shared.text(thai: "-- เลือกเพศ --", english: "-- Select gender --")).tag("")
                        Text(SettingsManager.shared.text(thai: "ชาย", english: "Male")).tag("male")
                        Text(SettingsManager.shared.text(thai: "หญิง", english: "Female")).tag("female")
                        Text(SettingsManager.shared.text(thai: "อื่นๆ", english: "Other")).tag("other")
                    }
                    .font(.system(size: 16, weight: .medium))
                    
                    // Birth Date Picker
                    HStack {
                        Text(SettingsManager.shared.text(thai: "วันเกิด", english: "Date of birth"))
                        Spacer()
                        if isBirthDateSet {
                            DatePicker(
                                "",
                                selection: $birthDate,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                        } else {
                            Button(action: {
                                isBirthDateSet = true
                            }) {
                                Text(SettingsManager.shared.text(thai: "ตั้งวันเกิด", english: "Set date of birth"))
                                    .foregroundColor(.appAccent)
                            }
                        }
                    }
                }
                
                Section {
                    TextEditor(text: $bio)
                        .focused($isBioFocused)
                        .frame(height: 100)
                        .font(.system(size: 16, weight: .regular))
                        .listRowSeparator(.hidden)
                        
                    HStack {
                        Text(SettingsManager.shared.text(thai: "เขียนรายละเอียดตรงนี้", english: "Write something about yourself"))
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.7))
                        
                        Spacer()
                        
                        Text("\(bio.count) / 500")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.adaptiveSecondaryText)
                    }
                }
                
                Section(header: Text(SettingsManager.shared.localizedString(for: "lifestyle_header"))) {
                    Button(action: { showQuiz = true }) {
                        HStack {
                            Image(systemName: "pencil.and.outline")
                            Text(SettingsManager.shared.text(thai: "ทำแบบสำรวจไลฟ์สไตล์ใหม่", english: "Retake lifestyle questionnaire"))
                                .fontWeight(.bold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.adaptiveSecondaryText)
                        }
                    }
                    .foregroundColor(.adaptiveText)
                    
                }

                Section(header: Text(SettingsManager.shared.text(thai: "สไตล์การเที่ยว (เลือกได้สูงสุด 5 ข้อ)", english: "Travel styles (select up to 5)"))) {
                    ForEach(INTEREST_SECTIONS) { section in
                        Text(section.displayTitle)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.bottom, 2)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(section.categories) { cat in
                                InterestTag(
                                    label: cat.displayLabel,
                                    icon: cat.icon,
                                    isSelected: selectedInterests.contains(cat.label)
                                ) {
                                    if selectedInterests.contains(cat.label) {
                                        selectedInterests.remove(cat.label)
                                    } else {
                                        if selectedInterests.count < 5 {
                                            selectedInterests.insert(cat.label)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 8)
                    }
                }
                
                Section(header: Text(SettingsManager.shared.text(thai: "ตั้งค่าความเป็นส่วนตัว", english: "Privacy settings"))) {
                    Toggle(tr("เปิดโปรไฟล์สาธารณะ", "Public profile"), isOn: $isProfilePublic)
                        .font(.system(size: 14, weight: .medium))
                    
                    if isProfilePublic {
                        Toggle(tr("แสดงเพศ", "Show gender"), isOn: $showGender)
                            .font(.system(size: 14, weight: .medium))
                        Toggle(tr("แสดงอายุ", "Show age"), isOn: $showAge)
                            .font(.system(size: 14, weight: .medium))
                        Toggle(tr("แสดงประวัติส่วนตัว", "Show bio"), isOn: $showBio)
                            .font(.system(size: 14, weight: .medium))
                        Toggle(tr("แสดงสไตล์การเที่ยว", "Show travel styles"), isOn: $showInterests)
                            .font(.system(size: 14, weight: .medium))
                        Toggle(tr("แสดงอีเมล", "Show email"), isOn: $showEmail)
                            .font(.system(size: 14, weight: .medium))
                    } else {
                        Text(SettingsManager.shared.text(thai: "โปรไฟล์ถูกซ่อนจากผู้ใช้คนอื่น", english: "Your profile is hidden from other users"))
                            .font(.system(size: 12))
                            .foregroundColor(.adaptiveSecondaryText)
                    }
                }
                

            }
            .navigationTitle(SettingsManager.shared.text(thai: "แก้ไขโปรไฟล์", english: "Edit Profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(SettingsManager.shared.text(thai: "เสร็จสิ้น", english: "Done")) {
                        isBioFocused = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(SettingsManager.shared.text(thai: "ยกเลิก", english: "Cancel")) { dismiss() }
                        .foregroundColor(.appAccent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        Task {
                            // Convert profile images to base64 for backend
                            var profileImageBase64: String? = nil
                            var galleryBase64: [String] = []
                            let imagesToSave = profileImages.compactMap { $0 }
                            
                            let userId = targetUser?.id ?? authViewModel.currentUser?.id ?? "unknown"
                            
                            if let mainImage = imagesToSave.first,
                               let scaledImage = mainImage.resized(toWidth: 512),
                               let jpegData = scaledImage.jpegData(compressionQuality: 0.6) {
                                profileImageBase64 = "data:image/jpeg;base64," + jpegData.base64EncodedString()
                                UserDefaults.standard.set(jpegData, forKey: "local_profile_image_\(userId)")
                            }
                            
                            for img in imagesToSave.dropFirst() {
                                if let scaledImage = img.resized(toWidth: 512),
                                   let jpegData = scaledImage.jpegData(compressionQuality: 0.6) {
                                    galleryBase64.append("data:image/jpeg;base64," + jpegData.base64EncodedString())
                                }
                            }
                            
                            let calendar = Calendar.current
                            let ageInt = isBirthDateSet ? calendar.dateComponents([.year], from: birthDate, to: Date()).year : nil
                            let finalBirthDate = isBirthDateSet ? birthDate : nil
                            
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
                                    birthDate: finalBirthDate,
                                    travelStyle: TravelStyle(budget: Int(budget), activityStyle: Int(activityStyle), timeOfDay: timeOfDay),
                                    profileImage: profileImageBase64,
                                    gallery: galleryBase64
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
                                    birthDate: finalBirthDate,
                                    travelStyle: TravelStyle(budget: Int(budget), activityStyle: Int(activityStyle), timeOfDay: timeOfDay),
                                    profileImage: profileImageBase64,
                                    gallery: galleryBase64
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
                            MatchTripViewModel.invalidateCache()
                            
                            dismiss()
                        }
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.appAccent)
                        } else {
                            Text(SettingsManager.shared.text(thai: "บันทึก", english: "Save"))
                        }
                    }
                    .foregroundColor(.appAccent)
                    .disabled(authViewModel.isLoading || name.trimmingCharacters(in: .whitespaces).isEmpty || isUsernameInvalid)
                }
            }

            .tint(.appPrimary)
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
                        self.isBirthDateSet = true
                    }
                    
                    if let style = user.travelStyle {
                        if let b = style.budget { budget = Double(b) }
                        if let a = style.activityStyle { activityStyle = Double(a) }
                        if let t = style.timeOfDay { timeOfDay = t }
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
            .onChange(of: showQuiz) { oldValue, newValue in
                if !newValue {
                    // Sheet dismissed, reload interests/travel style in case they changed
                    if let user = targetUser ?? authViewModel.currentUser {
                        selectedInterests = Set(user.interests ?? [])
                        if let style = user.travelStyle {
                            if let b = style.budget { budget = Double(b) }
                            if let a = style.activityStyle { activityStyle = Double(a) }
                            if let t = style.timeOfDay { timeOfDay = t }
                        }
                    }
                }
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
                Text(icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 12, weight: .bold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.appPrimary : Color.adaptiveCardTint)
            .foregroundColor(isSelected ? Color.white : .adaptiveText)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.appPrimary : Color.clear, lineWidth: 1)
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

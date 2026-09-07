import SwiftUI
import PhotosUI

struct QuestionnaireView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0
    @State private var isSubmitting = false
    @State private var errorMessage = ""
    @State private var username = ""
    @State private var usernameStatus: UsernameStatus = .idle
    @State private var usernameCheckTask: Task<Void, Never>?
    @State private var selectedProfileItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var isBirthDateSet = false
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // State
    @State private var budget: Double = 1500
    @State private var activityStyle: Double = 5
    
    // Non-linear budget steps
    private let budgetSteps: [Double] = [
        100, 300, 500, 800, 1000, 1500, 2000, 3000, 4000, 5000
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
                    triggerHapticFeedback()
                }
            }
        )
    }
    
    private func triggerHapticFeedback() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    @State private var startTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var endTime: Date = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    
    @State private var timeOfDay: [String] = []
    @State private var interests: Set<String> = []
    @State private var movingForward: Bool = true
    
    @State private var userName: String = "User"
    var isOnboarding: Bool = false
    var onComplete: (() -> Void)?

    private var totalSteps: Int { isOnboarding ? 5 : 4 }
    private var displayedStep: Int { currentStep + (isOnboarding ? 0 : 1) }

    private var canContinue: Bool {
        guard !isSubmitting else { return false }
        switch displayedStep {
        case 0:
            let cleanedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
            let usernameIsValid = cleanedUsername.isEmpty || usernameStatus == .available
            let hasRequiredImage = !isOnboarding || profileImage != nil
            return usernameIsValid && isBirthDateSet && hasRequiredImage
        case 3:
            return !timeOfDay.isEmpty
        case 4:
            return !interests.isEmpty
        default:
            return true
        }
    }

    private enum UsernameStatus: Equatable {
        case idle, checking, available
        case taken(String)
        case invalid(String)
    }

    private var calculatedAge: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }

    private func checkUsername(_ value: String) {
        usernameCheckTask?.cancel()
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { usernameStatus = .idle; return }
        guard cleaned.count >= 3 else {
            usernameStatus = .invalid("Username ต้องมีอย่างน้อย 3 ตัวอักษร")
            return
        }
        if cleaned == authViewModel.currentUser?.username {
            usernameStatus = .available
            return
        }

        usernameStatus = .checking
        usernameCheckTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            do {
                let result = try await AuthService.shared.checkUsernameAvailability(
                    username: cleaned,
                    excludeUserId: authViewModel.currentUser?.id
                )
                await MainActor.run {
                    usernameStatus = result.available ? .available : .taken(result.message)
                }
            } catch {
                await MainActor.run { usernameStatus = .idle }
            }
        }
    }
    
    // Time slots
    let timeSlots = [
        ("morning", "ช่วงเช้า (06:00 - 11:00 น.)", "เหมาะสำหรับคนที่ชอบออกจากที่พักเร็ว เช่น ดูพระอาทิตย์ขึ้น เดินตลาดเช้า หรือรับประทานอาหารเช้า"),
        ("noon", "ช่วงกลางวัน (11:00 - 16:00 น.)", "เหมาะสำหรับคนที่ชอบเที่ยวช่วงสายถึงบ่าย เช่น เข้าชมสถานที่ท่องเที่ยว แวะคาเฟ่ หรือรับประทานอาหารกลางวัน"),
        ("evening", "ช่วงเย็น (16:00 - 20:00 น.)", "เหมาะสำหรับคนที่ชอบเที่ยวช่วงเย็นก่อนค่ำ เช่น เดินเล่น ชมพระอาทิตย์ตก หรือรับประทานอาหารเย็น"),
        ("night", "ช่วงกลางคืน (20:00 น. เป็นต้นไป)", "เหมาะสำหรับคนที่ชอบออกเที่ยวหลังค่ำ เช่น เดินตลาดกลางคืน ชมแสงไฟในเมือง หรือฟังดนตรีสด")
    ]
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Progress
                // Progress
                ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                    .padding(.horizontal)
                    .tint(.appPrimary)
                
                Text("\(SettingsManager.shared.localizedString(for: "step_prefix")) \(currentStep + 1) \(SettingsManager.shared.localizedString(for: "step_suffix")) \(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Group {
                            if displayedStep == 0 {
                                Text("👤 ข้อมูลส่วนตัวของคุณ")
                                    .font(.title2).bold()
                                Text("ข้อมูลนี้ช่วยให้ผู้ร่วมทริปรู้จักคุณ และใช้สร้างโปรไฟล์ของคุณ")
                                    .font(.subheadline).foregroundColor(.secondary)

                                VStack(spacing: 12) {
                                    if let profileImage {
                                        Image(uiImage: profileImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 124, height: 124)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.appPrimary, lineWidth: 3))
                                    } else {
                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .font(.system(size: 86, weight: .light))
                                            .foregroundColor(.appPrimary)
                                    }

                                    PhotosPicker(selection: $selectedProfileItem, matching: .images) {
                                        Label(profileImage == nil ? "เลือกรูปโปรไฟล์" : "เปลี่ยนรูปโปรไฟล์", systemImage: "photo")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 11)
                                            .background(Color.appPrimary)
                                            .clipShape(Capsule())
                                    }

                                    if isOnboarding && profileImage == nil {
                                        Text("จำเป็นต้องเลือกรูปโปรไฟล์ก่อนดำเนินการต่อ")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Username").font(.headline)
                                    HStack {
                                        Text("@").foregroundColor(.secondary)
                                        TextField("username", text: $username)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled(true)
                                            .onChange(of: username) { _, newValue in checkUsername(newValue) }
                                        switch usernameStatus {
                                        case .checking: ProgressView().scaleEffect(0.75)
                                        case .available: Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                        case .taken, .invalid: Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                                        default: EmptyView()
                                        }
                                    }
                                    .padding().background(Color.gray.opacity(0.1)).cornerRadius(12)

                                    switch usernameStatus {
                                    case .available: Text("Username นี้ใช้งานได้").foregroundColor(.green)
                                    case .taken(let message), .invalid(let message): Text(message).foregroundColor(.red)
                                    default: Text("เว้นว่างได้ ระบบจะสร้าง Username ที่ไม่ซ้ำให้อัตโนมัติ").foregroundColor(.secondary)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("วันเกิด").font(.headline)
                                    DatePicker(
                                        "เลือกวันเกิด",
                                        selection: $birthDate,
                                        in: ...Date(),
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(.compact)
                                    .onChange(of: birthDate) { _, _ in isBirthDateSet = true }
                                    Text("อายุ \(calculatedAge) ปี")
                                        .font(.subheadline).foregroundColor(.secondary)
                                }
                                .padding().background(Color.gray.opacity(0.1)).cornerRadius(12)

                            } else if displayedStep == 1 {
                                // Budget Step
                                Text("💰 งบประมาณเฉลี่ยต่อทริป (Budget per Trip)")
                                    .font(.title2).bold()
                            Text("ระบุงบประมาณที่คุณสะดวกใช้จ่ายสำหรับหนึ่งทริป (บาท)")
                                .font(.subheadline).foregroundColor(.secondary)
                            
                            VStack(spacing: 30) {
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    TextField("1500", value: $budget, format: .number)
                                        .font(.system(size: 60, weight: .black))
                                        .foregroundColor(.primary)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: 200)
                                        .tint(.appPrimary)
                                    
                                    Text("฿")
                                        .font(.title)
                                        .foregroundColor(.secondary)
                                }
                                
                                Slider(value: budgetSliderBinding, in: 0...Double(budgetSteps.count - 1), step: 1)
                                    .tint(.appPrimary)
                                
                                HStack {
                                    Text("ประหยัด (100฿)")
                                        .font(.caption).foregroundColor(.secondary)
                                    Spacer()
                                    Text("หรูหรา (5,000฿+)")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 20)
                            
                        } else if displayedStep == 2 {
                            // Activity Style Step
                            Text("🎯 จำนวนสถานที่ท่องเที่ยวต่อวัน (Places per Day)")
                                .font(.title2).bold()
                            Text("เลือกจำนวนสถานที่ที่คุณสะดวกเที่ยวในหนึ่งวัน")
                                .font(.subheadline).foregroundColor(.secondary)
                            
                            VStack(spacing: 12) {
                                QuestionnaireActivityStyleCard(title: "1–2 สถานที่ต่อวัน", subtitle: "ต้องการใช้เวลาในแต่ละสถานที่อย่างเต็มที่ และมีเวลาพักผ่อนระหว่างวัน", value: 2, selectedValue: $activityStyle)
                                QuestionnaireActivityStyleCard(title: "3–4 สถานที่ต่อวัน", subtitle: "ต้องการเที่ยวหลายสถานที่ โดยแบ่งเวลาเที่ยวและพักผ่อนให้สมดุล", value: 5, selectedValue: $activityStyle)
                                QuestionnaireActivityStyleCard(title: "5 สถานที่ขึ้นไปต่อวัน", subtitle: "ต้องการเที่ยวให้หลากหลายในหนึ่งวัน และใช้เวลาในแต่ละสถานที่ไม่นาน", value: 8, selectedValue: $activityStyle)
                            }
                            .padding(.top, 20)
                            
                        } else if displayedStep == 3 {
                            // Time of Day Step
                            Text("🕘 ช่วงเวลาที่ชอบท่องเที่ยว (Time of Day)")
                                .font(.title2).bold()
                            Text("เลือกช่วงเวลาที่คุณชอบออกไปทำกิจกรรมหรือท่องเที่ยว (เลือกได้มากกว่า 1 ช่วง)")
                                .font(.subheadline).foregroundColor(.secondary)
                            
                            VStack(spacing: 12) {
                                ForEach(timeSlots, id: \.0) { slot in
                                    let (key, title, subtitle) = slot
                                    let isSelected = timeOfDay.contains(key)
                                    
                                    Button {
                                        triggerHapticFeedback()
                                        if isSelected {
                                            timeOfDay.removeAll { $0 == key }
                                        } else {
                                            timeOfDay.append(key)
                                        }
                                    } label: {
                                        HStack(alignment: .center) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(title)
                                                    .font(.headline)
                                                    .foregroundColor(isSelected ? .white : .primary)
                                                Text(subtitle)
                                                    .font(.caption)
                                                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                                                    .multilineTextAlignment(.leading)
                                            }
                                            Spacer()
                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.white)
                                                    .font(.title3)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(.gray)
                                                    .font(.title3)
                                            }
                                        }
                                        .padding()
                                        .background(isSelected ? Color.appPrimary : Color.gray.opacity(0.1))
                                        .cornerRadius(12)
                                        .contentShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 20)
                        } else if displayedStep == 4 {
                            // Interests Step
                            HStack {
                                Text("✨ ความสนใจด้านการท่องเที่ยว (Travel Interests)")
                                    .font(.title2).bold()
                                Spacer()
                            }
                            Text("เลือกหมวดหมู่ที่คุณสนใจได้สูงสุด 5 ข้อ เพื่อให้เราแนะนำทริปที่เหมาะกับคุณ")
                                .font(.subheadline).foregroundColor(.secondary)
                            
                            HStack {
                                Label("เลื่อนซ้าย–ขวาเพื่อดูตัวเลือก", systemImage: "arrow.left.arrow.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("เลือกแล้ว \(interests.count)/5")
                                    .font(.caption.bold())
                            }
                            .padding(.top, 8)

                            ForEach(INTEREST_SECTIONS) { section in
                                VStack(alignment: .leading, spacing: 12) {
                                Text(section.title)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                ScrollView(.horizontal, showsIndicators: true) {
                                    LazyHStack(spacing: 12) {
                                    ForEach(section.categories) { cat in
                                        QuestionnaireInterestCard(
                                            label: cat.label,
                                            icon: cat.icon,
                                            isSelected: interests.contains(cat.label)
                                        ) {
                                            triggerHapticFeedback()
                                            if interests.contains(cat.label) {
                                                interests.remove(cat.label)
                                            } else {
                                                if interests.count < 5 {
                                                    interests.insert(cat.label)
                                                }
                                            }
                                        }
                                        .frame(width: 112)
                                    }
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 4)
                                }
                                }
                                .padding(.top, 16)
                            }
                        }
                        } // Closes Group
                        .transition(.asymmetric(
                            insertion: .move(edge: movingForward ? .trailing : .leading),
                            removal: .move(edge: movingForward ? .leading : .trailing)
                        ))
                        .id(currentStep)
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Footer Navigation
                HStack {
                    if currentStep > 0 {
                        Button("ย้อนกลับ") {
                            triggerHapticFeedback()
                            if currentStep > 0 {
                                movingForward = false
                                withAnimation(.easeInOut) { currentStep -= 1 }
                            }
                        }
                        .padding()
                        .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Button {
                        triggerHapticFeedback()
                        
                        if displayedStep == 0 {
                            let cleanedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !cleanedUsername.isEmpty && usernameStatus != .available {
                                errorMessage = "กรุณาระบุ Username ที่สามารถใช้งานได้"
                                return
                            }
                            if isOnboarding && profileImage == nil {
                                errorMessage = "กรุณาเลือกรูปโปรไฟล์"
                                return
                            }
                            if !isBirthDateSet {
                                errorMessage = "กรุณาเลือกวันเกิดเพื่อระบุอายุ"
                                return
                            }
                        }
                        if displayedStep == 3 && timeOfDay.isEmpty {
                            errorMessage = "โปรดเลือกอย่างน้อย 1 ช่วงเวลา"
                            return
                        }
                        if displayedStep == 4 && interests.isEmpty {
                            errorMessage = "โปรดเลือกอย่างน้อย 1 สไตล์"
                            return
                        }
                        
                        errorMessage = ""
                        
                        if currentStep < totalSteps - 1 {
                            movingForward = true
                            withAnimation(.easeInOut) { currentStep += 1 }
                        } else {
                            submitQuestionnaire()
                        }
                    } label: {
                        if isSubmitting {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(currentStep == totalSteps - 1 ? "เสร็จสิ้น" : "ถัดไป")
                                .bold()
                        }
                    }
                    .frame(width: 120, height: 50)
                    .background(canContinue ? Color.appPrimary : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    .disabled(!canContinue)
                }
                .padding()
            }
            .navigationTitle("แบบสอบถาม")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isOnboarding {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("ปิด") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .task {
            // Load existing preferences if available
            do {
                let user = try await AuthService.shared.getCurrentUser()
                userName = user.name
                username = user.username ?? ""
                if !username.isEmpty { usernameStatus = .available }
                if let existingBirthDate = user.birthDate {
                    birthDate = existingBirthDate
                    isBirthDateSet = true
                }
                if let existingInterests = user.interests {
                    interests = Set(existingInterests)
                }
                if let profileImageString = user.profileImage,
                   !profileImageString.isEmpty,
                   let existingImage = ProfileView.decodeBase64Image(profileImageString) {
                    profileImage = existingImage
                }
                if let style = user.travelStyle {
                    if let b = style.budget { budget = Double(b) }
                    if let a = style.activityStyle { activityStyle = Double(a) }
                    if let t = style.timeOfDay { timeOfDay = t }
                }
            } catch {
                print("Could not fetch user for questionnaire: \(error)")
            }
        }
        .onChange(of: selectedProfileItem) { _, newItem in
            guard let newItem else { return }
            Task {
                guard let data = try? await newItem.loadTransferable(type: Data.self),
                      let selectedImage = UIImage(data: data) else {
                    await MainActor.run { errorMessage = "ไม่สามารถเปิดรูปที่เลือกได้" }
                    return
                }
                await MainActor.run {
                    profileImage = selectedImage
                    errorMessage = ""
                }
            }
        }
    }
    
    private func submitQuestionnaire() {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = ""
        
        Task {
            do {
                let travelStyle = TravelStyle(
                    budget: Int(budget),
                    activityStyle: Int(activityStyle),
                    timeOfDay: timeOfDay
                )

                var profileImageBase64: String?
                if let profileImage,
                   let resizedImage = profileImage.resized(toWidth: 512),
                   let jpegData = resizedImage.jpegData(compressionQuality: 0.65) {
                    profileImageBase64 = "data:image/jpeg;base64," + jpegData.base64EncodedString()
                }
                
                let updatedUser = try await AuthService.shared.updateProfile(
                    name: userName,
                    interests: Array(interests).sorted(),
                    age: isOnboarding ? calculatedAge : nil,
                    birthDate: isOnboarding ? birthDate : nil,
                    travelStyle: travelStyle,
                    profileImage: profileImageBase64,
                    username: isOnboarding
                        ? (username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? nil
                            : username.trimmingCharacters(in: .whitespacesAndNewlines))
                        : nil
                )
                
                await authViewModel.loadCurrentUser()
                
                DispatchQueue.main.async {
                    MatchTripViewModel.invalidateCache()
                    self.isSubmitting = false
                    self.onComplete?()
                    if self.isOnboarding {
                        self.authViewModel.needsOnboarding = false
                    }
                    self.dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isSubmitting = false
                    self.errorMessage = "Failed to save profile: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct QuestionnaireInfoRow: View {
    let range: String
    let label: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(range)
                .font(.caption)
                .bold()
                .frame(width: 40, alignment: .leading)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    QuestionnaireView()
        .environmentObject(AuthViewModel())
}

struct QuestionnaireInterestCard: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(icon)
                    .font(.system(size: 36))
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(isSelected ? Color.appPrimary : Color.gray.opacity(0.05))
            .foregroundColor(isSelected ? .white : .adaptiveText)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.appPrimary : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(16)
            .contentShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: isSelected ? Color.appPrimary.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

struct QuestionnaireActivityStyleCard: View {
    let title: String
    let subtitle: String
    let value: Double
    @Binding var selectedValue: Double
    
    var body: some View {
        let isSelected = selectedValue == value
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedValue = value
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.title3)
                }
            }
            .padding()
            .background(isSelected ? Color.appPrimary : Color.gray.opacity(0.1))
            .cornerRadius(12)
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

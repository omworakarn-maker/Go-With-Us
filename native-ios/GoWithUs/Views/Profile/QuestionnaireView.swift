import SwiftUI

struct QuestionnaireView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0
    @State private var isSubmitting = false
    @State private var errorMessage = ""
    
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
    @State private var interests: [String] = []
    @State private var movingForward: Bool = true
    
    @State private var userName: String = "User"
    var isOnboarding: Bool = false
    var onComplete: (() -> Void)?
    
    // Time slots
    let timeSlots = [
        ("morning", "ช่วงเช้า (06:00 - 11:00 น.)", "เช่น ชมพระอาทิตย์ขึ้น, เยี่ยมชมตลาดเช้า"),
        ("noon", "ช่วงกลางวัน (11:00 - 16:00 น.)", "เช่น รับประทานอาหาร, พักผ่อนในคาเฟ่, เข้าชมพิพิธภัณฑ์"),
        ("evening", "ช่วงเย็น (16:00 - 20:00 น.)", "เช่น เดินพักผ่อน, ชมพระอาทิตย์ตก, รับประทานอาหารค่ำ"),
        ("night", "ช่วงกลางคืน (20:00 น. เป็นต้นไป)", "เช่น สัมผัสบรรยากาศยามค่ำคืน, เข้าร่วมงานสังสรรค์")
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
                ProgressView(value: Double(currentStep + 1), total: 4)
                    .padding(.horizontal)
                    .tint(.black)
                
                Text("\(SettingsManager.shared.localizedString(for: "step_prefix")) \(currentStep + 1) \(SettingsManager.shared.localizedString(for: "step_suffix")) 4")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Group {
                            if currentStep == 0 {
                                // Budget Step
                                Text("💰 งบประมาณเฉลี่ยต่อวัน (Budget / บาท)")
                                    .font(.title2).bold()
                            Text("ระบุงบประมาณที่คุณพึงพอใจในการใช้จ่ายระหว่างทริป (ต่อวัน)")
                                .font(.subheadline).foregroundColor(.secondary)
                            
                            VStack(spacing: 30) {
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    TextField("1500", value: $budget, format: .number)
                                        .font(.system(size: 60, weight: .black))
                                        .foregroundColor(.primary)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: 200)
                                        .tint(.black)
                                    
                                    Text("฿")
                                        .font(.title)
                                        .foregroundColor(.secondary)
                                }
                                
                                Slider(value: budgetSliderBinding, in: 0...Double(budgetSteps.count - 1), step: 1)
                                    .tint(.black)
                                
                                HStack {
                                    Text("ประหยัด (100฿)")
                                        .font(.caption).foregroundColor(.secondary)
                                    Spacer()
                                    Text("หรูหรา (5,000฿+)")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 20)
                            
                        } else if currentStep == 1 {
                            // Activity Style Step
                            Text("🎯 สไตล์กิจกรรมที่ชื่นชอบ (Activity Style)")
                                .font(.title2).bold()
                            Text("รูปแบบของกิจกรรมที่คุณต้องการทำระหว่างการท่องเที่ยว")
                                .font(.subheadline).foregroundColor(.secondary)
                            
                            VStack(spacing: 12) {
                                QuestionnaireActivityStyleCard(title: "เน้นการพักผ่อน (Very Relaxed)", subtitle: "เน้นการใช้เวลาภายในที่พักหรือสถานที่ผ่อนคลาย", value: 1, selectedValue: $activityStyle)
                                QuestionnaireActivityStyleCard(title: "พักผ่อนปานกลาง (Somewhat Relaxed)", subtitle: "เน้นการเดินทางแบบไม่เร่งรีบ (1-2 สถานที่ต่อวัน)", value: 3, selectedValue: $activityStyle)
                                QuestionnaireActivityStyleCard(title: "สมดุล (Balanced)", subtitle: "ผสมผสานระหว่างการพักผ่อนและการทำกิจกรรมอย่างเท่าเทียม", value: 5, selectedValue: $activityStyle)
                                QuestionnaireActivityStyleCard(title: "เน้นกิจกรรม (Somewhat Active)", subtitle: "มีตารางการเดินทางชัดเจนและครอบคลุมหลายสถานที่", value: 7, selectedValue: $activityStyle)
                                QuestionnaireActivityStyleCard(title: "กิจกรรมเต็มรูปแบบ (Very Active)", subtitle: "เน้นการผจญภัยและการเดินทางไปยังสถานที่สำคัญอย่างครบถ้วน", value: 10, selectedValue: $activityStyle)
                            }
                            .padding(.top, 20)
                            
                        } else if currentStep == 2 {
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
                                        .background(isSelected ? Color.black : Color.gray.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.top, 20)
                        } else if currentStep == 3 {
                            // Interests Step
                            HStack {
                                Text("✨ สไตล์การเที่ยวของคุณ")
                                    .font(.title2).bold()
                                Spacer()
                            }
                            Text("เลือกสไตล์การท่องเที่ยวที่คุณชอบ (เลือกได้สูงสุด 5 ข้อ) เพื่อให้เราแนะนำทริปที่โดนใจคุณมากที่สุด")
                                .font(.subheadline).foregroundColor(.secondary)
                            
                            ForEach(INTEREST_SECTIONS) { section in
                                Text(section.title)
                                    .font(.headline)
                                    .padding(.top, 16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ], spacing: 16) {
                                    ForEach(section.categories) { cat in
                                        QuestionnaireInterestCard(
                                            label: cat.label,
                                            icon: cat.icon,
                                            isSelected: interests.contains(cat.label)
                                        ) {
                                            triggerHapticFeedback()
                                            if interests.contains(cat.label) {
                                                interests.removeAll { $0 == cat.label }
                                            } else {
                                                if interests.count < 5 {
                                                    interests.append(cat.label)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.top, 20)
                        } // Closes else if currentStep == 3
                        } // Closes Group
                        .transition(.asymmetric(
                            insertion: .move(edge: movingForward ? .trailing : .leading),
                            removal: .move(edge: movingForward ? .leading : .trailing)
                        ))
                        .id(currentStep)
                    }
                    .padding()
                }
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                
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
                        
                        if currentStep == 2 && timeOfDay.isEmpty {
                            errorMessage = "โปรดเลือกอย่างน้อย 1 ช่วงเวลา"
                            return
                        }
                        if currentStep == 3 && interests.isEmpty {
                            errorMessage = "โปรดเลือกอย่างน้อย 1 สไตล์"
                            return
                        }
                        
                        errorMessage = ""
                        
                        if currentStep < 3 {
                            movingForward = true
                            withAnimation(.easeInOut) { currentStep += 1 }
                        } else {
                            submitQuestionnaire()
                        }
                    } label: {
                        if isSubmitting {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(currentStep == 3 ? "เสร็จสิ้น" : "ถัดไป")
                                .bold()
                        }
                    }
                    .frame(width: 120, height: 50)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    .disabled(isSubmitting)
                }
                .padding()
            }
            .navigationTitle("แบบสอบถาม")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("ข้าม") {
                        if isOnboarding {
                            authViewModel.needsOnboarding = false
                        }
                        dismiss()
                    }
                }
            }
        }
        .task {
            // Load existing preferences if available
            do {
                let user = try await AuthService.shared.getCurrentUser()
                userName = user.name
                if let existingInterests = user.interests {
                    interests = existingInterests
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
                
                let updatedUser = try await AuthService.shared.updateProfile(
                    name: userName,
                    interests: interests,
                    travelStyle: travelStyle
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
            .background(isSelected ? Color.black : Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}


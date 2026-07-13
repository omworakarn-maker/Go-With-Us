import SwiftUI

struct QuestionnaireView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0
    @State private var isSubmitting = false
    @State private var errorMessage = ""
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // State
    @State private var budget: Double = 5
    @State private var activityStyle: Double = 5
    @State private var timeOfDay: [String] = []
    @State private var interests: [String] = []
    
    @State private var userName: String = "User"
    var isOnboarding: Bool = false
    var onComplete: (() -> Void)?
    
    // Time slots
    let timeSlots = [
        ("morning", "เช้า", "ตื่นแต่เช้า สูดอากาศสด กิจกรรมยามเช้าตรู่"),
        ("noon", "กลางวัน", "ท่องเที่ยวระหว่างวัน เดินเล่น ช็อปปิ้ง"),
        ("evening", "เย็น", "ชมวิว ดูพระอาทิตย์ตก ดินเนอร์ริมทะเล"),
        ("night", "มืด/ราตรี", "แฮงเอาต์ บาร์ ไนท์มาร์เก็ต ปาร์ตี้")
    ]
    
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
                        if currentStep == 0 {
                            // Budget Step
                            Text("งบประมาณในการท่องเที่ยว (Budget Level)")
                                .font(.title2).bold()
                            Text("ระดับงบประมาณเฉลี่ยที่คุณพึงพอใจในการใช้จ่ายระหว่างทริป")
                                .font(.subheadline).foregroundColor(.secondary)
                            
                            VStack(spacing: 30) {
                                Text("\(Int(budget))")
                                    .font(.system(size: 60, weight: .black))
                                    .foregroundColor(.primary)
                                
                                Slider(value: $budget, in: 1...10, step: 1)
                                    .tint(.black)
                                
                                HStack {
                                    Text("ประหยัด (1)")
                                        .font(.caption).foregroundColor(.secondary)
                                    Spacer()
                                    Text("หรูหรา (10)")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    QuestionnaireInfoRow(range: "1-3", label: "ประหยัด (Budget) - เน้นคุ้มค่า โฮสเทล (100-500฿)")
                                    QuestionnaireInfoRow(range: "4-7", label: "ปานกลาง (Standard) - โรงแรมทั่วไป สบายๆ (500-2000฿)")
                                    QuestionnaireInfoRow(range: "8-10", label: "หรูหรา (Luxury) - รีสอร์ทห้าดาว ดินเนอร์หรู (2000฿+)")
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.top, 20)
                            
                        } else if currentStep == 1 {
                            // Activity Style Step
                            Text("สไตล์กิจกรรมที่ชื่นชอบ (Activity Style)")
                                .font(.title2).bold()
                            Text("รูปแบบของกิจกรรมที่คุณต้องการทำระหว่างการท่องเที่ยว")
                                .font(.subheadline).foregroundColor(.secondary)
                            
                            VStack(spacing: 30) {
                                Text("\(Int(activityStyle))")
                                    .font(.system(size: 60, weight: .black))
                                    .foregroundColor(.primary)
                                
                                Slider(value: $activityStyle, in: 1...10, step: 1)
                                    .tint(.black)
                                
                                HStack {
                                    Text("พักผ่อนชิลล์ๆ (1)")
                                        .font(.caption).foregroundColor(.secondary)
                                    Spacer()
                                    Text("ลุยเต็มพิกัด (10)")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    QuestionnaireInfoRow(range: "1-3", label: "พักผ่อนชิลล์ๆ (Relaxing) - เดินเล่น ถ่ายรูป นั่งคาเฟ่ สบายๆ")
                                    QuestionnaireInfoRow(range: "4-7", label: "ยืดหยุ่นปานกลาง (Standard) - เดินป่าสั้นๆ เที่ยวชมเมือง ทำกิจกรรมทั่วไป")
                                    QuestionnaireInfoRow(range: "8-10", label: "ลุยเต็มพิกัด (Adventure) - ปีนเขา กางเต็นท์ แอดเวนเจอร์ กีฬาเอ็กซ์ตรีม")
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.top, 20)
                            
                        } else if currentStep == 2 {
                            // Time of Day Step
                            Text("ช่วงเวลาที่ชอบท่องเที่ยว (Time of Day)")
                                .font(.title2).bold()
                            Text("เลือกช่วงเวลาที่คุณชอบออกไปทำกิจกรรมหรือท่องเที่ยว (เลือกได้มากกว่า 1 ช่วง)")
                                .font(.subheadline).foregroundColor(.secondary)
                            
                            VStack(spacing: 12) {
                                ForEach(timeSlots, id: \.0) { slot in
                                    let (key, label, desc) = slot
                                    let isSelected = timeOfDay.contains(key)
                                    
                                    Button {
                                        if isSelected {
                                            timeOfDay.removeAll { $0 == key }
                                        } else {
                                            timeOfDay.append(key)
                                        }
                                    } label: {
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(label)
                                                    .font(.headline)
                                                    .foregroundColor(isSelected ? .white : .primary)
                                                Text(desc)
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
                            Text("สิ่งที่สนใจ (Interests)")
                                .font(.title2).bold()
                            Text("เลือกหมวดหมู่การท่องเที่ยวที่คุณสนใจ (เลือกได้หลายข้อ)")
                                .font(.subheadline).foregroundColor(.secondary)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                                ForEach(INTEREST_CATEGORIES) { cat in
                                    InterestTag(
                                        label: cat.label,
                                        icon: cat.icon,
                                        isSelected: interests.contains(cat.label)
                                    ) {
                                        if interests.contains(cat.label) {
                                            interests.removeAll { $0 == cat.label }
                                        } else {
                                            interests.append(cat.label)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 20)
                        }
                    }
                    .padding()
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Footer Navigation
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation { currentStep -= 1 }
                        }
                        .padding()
                        .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Button {
                        if currentStep == 2 && timeOfDay.isEmpty {
                            errorMessage = "โปรดเลือกอย่างน้อย 1 ช่วงเวลา"
                            return
                        }
                        if currentStep == 3 && interests.isEmpty {
                            errorMessage = "โปรดเลือกอย่างน้อย 1 หมวดหมู่"
                            return
                        }
                        
                        errorMessage = ""
                        
                        if currentStep < 3 {
                            withAnimation { currentStep += 1 }
                        } else {
                            submitQuestionnaire()
                        }
                    } label: {
                        if isSubmitting {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(currentStep == 3 ? "Finish" : "Next")
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
            .navigationTitle("Your Travel Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
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
                
                let _ = try await AuthService.shared.updateProfile(
                    name: userName,
                    interests: interests,
                    travelStyle: travelStyle
                )
                
                DispatchQueue.main.async {
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

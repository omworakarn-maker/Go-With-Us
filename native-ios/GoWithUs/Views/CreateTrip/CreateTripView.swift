import SwiftUI

struct CreateTripView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var destination = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400)
    @State private var budget = ""
    @State private var maxParticipants = "10"
    @State private var selectedCategory: TripCategory = .adventure
    @State private var imageUrl = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("สร้างทริปใหม่")
                                .font(.system(size: 32, weight: .black))
                                .foregroundColor(.black)
                                .tracking(-1)
                            
                            Text("เริ่มต้นการผจญภัยของคุณ")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 8)
                        
                        // Form
                        VStack(spacing: 20) {
                            // Title
                            FormField(label: "ชื่อทริป", placeholder: "เช่น เที่ยวเชียงใหม่ 3 วัน 2 คืน", text: $title)
                            
                            // Image URL
                            FormField(label: "URL รูปภาพ หรือ ชื่อรูปใน Assets", placeholder: "เช่น https://... หรือ trip_chiangmai", text: $imageUrl)
                            
                            // Destination
                            FormField(label: "สถานที่", placeholder: "เช่น เชียงใหม่", text: $destination)
                            
                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("รายละเอียด")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                    .tracking(1)
                                
                                TextEditor(text: $description)
                                    .foregroundColor(.black)
                                    .frame(height: 100)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .cornerRadius(12)
                            }
                            
                            // Category
                            VStack(alignment: .leading, spacing: 8) {
                                Text("หมวดหมู่")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                    .tracking(1)
                                
                                Menu {
                                    ForEach(TripCategory.allCases, id: \.self) { category in
                                        Button(category.rawValue) {
                                            selectedCategory = category
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedCategory.rawValue)
                                            .foregroundColor(.black)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .cornerRadius(12)
                                }
                            }
                            
                            // Dates
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("วันเริ่ม")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.gray)
                                        .textCase(.uppercase)
                                        .tracking(1)
                                    
                                    DatePicker("", selection: $startDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.gray.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                        .cornerRadius(12)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("วันสิ้นสุด")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.gray)
                                        .textCase(.uppercase)
                                        .tracking(1)
                                    
                                    DatePicker("", selection: $endDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.gray.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                        .cornerRadius(12)
                                }
                            }
                            
                            // Budget & Max Participants
                            HStack(spacing: 12) {
                                FormField(label: "งบประมาณ (บาท)", placeholder: "5000", text: $budget)
                                    .keyboardType(.numberPad)
                                
                                FormField(label: "จำนวนคน", placeholder: "10", text: $maxParticipants)
                                    .keyboardType(.numberPad)
                            }
                            
                            // Error Message
                            if let error = errorMessage {
                                Text(error)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.black)
                            }
                            
                            // Create Button
                            Button(action: createTrip) {
                                HStack(spacing: 8) {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "plus.circle.fill")
                                        Text("สร้างทริป")
                                            .font(.system(size: 15, weight: .bold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.black)
                                .cornerRadius(12)
                            }
                            .disabled(isLoading)
                            .padding(.top, 8)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ยกเลิก") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
    
    private func createTrip() {
        // Validation
        guard !title.isEmpty else {
            errorMessage = "กรุณากรอกชื่อทริป"
            return
        }
        
        guard !destination.isEmpty else {
            errorMessage = "กรุณากรอกสถานที่"
            return
        }
        
        guard let budgetValue = Int(budget), budgetValue > 0 else {
            errorMessage = "กรุณากรอกงบประมาณที่ถูกต้อง"
            return
        }
        
        guard let maxPart = Int(maxParticipants), maxPart > 0 else {
            errorMessage = "กรุณากรอกจำนวนคนที่ถูกต้อง"
            return
        }
        
        guard endDate >= startDate else {
            errorMessage = "วันสิ้นสุดต้องมากกว่าหรือเท่ากับวันเริ่ม"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let trip = try await TripService.shared.createTrip(
                    title: title,
                    destination: destination,
                    description: description.isEmpty ? "ไม่มีรายละเอียด" : description,
                    startDate: startDate,
                    endDate: endDate,
                    budget: budgetValue,
                    maxParticipants: maxPart,
                    category: selectedCategory,
                    imageUrl: imageUrl.isEmpty ? nil : imageUrl
                )
                
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Form Field
struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .tracking(1)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.black)
                .keyboardType(keyboardType)
                .padding()
                .background(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(12)
        }
    }
}

#Preview {
    CreateTripView()
}

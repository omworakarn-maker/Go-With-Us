import SwiftUI

// MARK: - Reusable Filter Button
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(isSelected ? .white : .adaptiveText)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.black : Color.adaptiveBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
            .cornerRadius(20)
        }
    }
}

// MARK: - Pickers (Sheets)

struct ProvincePicker: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedProvince: String?
    let provinces = [
        "ทุกจังหวัด", "กรุงเทพฯ", "กระบี่", "กาญจนบุรี", "กาฬสินธุ์", "กำแพงเพชร", "ขอนแก่น", "จันทบุรี", "ฉะเชิงเทรา", 
        "ชลบุรี", "ชัยนาท", "ชัยภูมิ", "ชุมพร", "เชียงราย", "เชียงใหม่", "ตรัง", "ตราด", "ตาก", "นครนายก", "นครปฐม", 
        "นครพนม", "นครราชสีมา", "นครศรีธรรมราช", "นครสวรรค์", "นนทบุรี", "นราธิวาส", "น่าน", "บึงกาฬ", "บุรีรัมย์", 
        "ปทุมธานี", "ประจวบคีรีขันธ์", "ปราจีนบุรี", "ปัตตานี", "พระนครศรีอยุธยา", "พะเยา", "พังงา", "พัทลุง", "พิจิตร", 
        "พิษณุโลก", "เพชรบุรี", "เพชรบูรณ์", "แพร่", "ภูเก็ต", "มหาสารคาม", "มุกดาหาร", "แม่ฮ่องสอน", "ยโสธร", "ยะลา", 
        "ร้อยเอ็ด", "ระนอง", "ระยอง", "ราชบุรี", "ลพบุรี", "ลำปาง", "ลำพูน", "เลย", "ศรีสะเกษ", "สกลนคร", "สงขลา", "สตูล", 
        "สมุทรปราการ", "สมุทรสงคราม", "สมุทรสาคร", "สระแก้ว", "สระบุรี", "สิงห์บุรี", "สุโขทัย", "สุพรรณบุรี", 
        "สุราษฎร์ธานี", "สุรินทร์", "หนองคาย", "หนองบัวลำภู", "อ่างทอง", "อำนาจเจริญ", "อุดรธานี", "อุตรดิตถ์", 
        "อุทัยธานี", "อุบลราชธานี"
    ]
    
    var body: some View {
        NavigationView {
            List {
                Button("ทุกจังหวัด") {
                    selectedProvince = nil
                    dismiss()
                }
                .foregroundColor(.adaptiveText)
                
                ForEach(provinces.filter { $0 != "ทุกจังหวัด" }, id: \.self) { province in
                    Button(province) {
                        selectedProvince = province
                        dismiss()
                    }
                    .foregroundColor(.adaptiveText)
                }
            }
            .navigationTitle("เลือกจังหวัด")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ปิด") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct DatePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedDate: Date? // Used as Start Date
    // If we want range, we need to bind endDate too, but FilterBar calls this with 1 binding.
    // For now, I will add local state for range and update logic. 
    // Wait, the prompt implies "Home Page" datepicker.
    // I will modify the struct to accept endDate and update calls later.
    
    @Binding var selectedEndDate: Date? // Optional End Date
    
    @State private var selectionMode: Int = 0 // 0 = Single, 1 = Range
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400)
    
    // Initializer to handle optional bindings if needed (but we will update call sites)
    init(selectedDate: Binding<Date?>, selectedEndDate: Binding<Date?> = .constant(nil)) {
        self._selectedDate = selectedDate
        self._selectedEndDate = selectedEndDate
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Toggle Mode
                Picker("โหมด", selection: $selectionMode) {
                    Text("วันเดียว").tag(0)
                    Text("ช่วงเวลา").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if selectionMode == 0 {
                    // Single Date
                    DatePicker("เลือกวันที่", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(.black)
                        .padding(.horizontal)
                } else {
                    // Range
                    VStack {
                        DatePicker("วันเริ่มต้น", selection: $startDate, displayedComponents: .date)
                            .tint(.black)
                        DatePicker("วันสิ้นสุด", selection: $endDate, in: startDate..., displayedComponents: .date)
                            .tint(.black)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                Button(action: {
                    if selectionMode == 0 {
                        selectedDate = startDate
                        selectedEndDate = nil
                    } else {
                        selectedDate = startDate
                        selectedEndDate = endDate
                    }
                    dismiss()
                }) {
                    Text("ตกลง")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                
                Button("ล้างค่า") {
                    selectedDate = nil
                    selectedEndDate = nil
                    dismiss()
                }
                .foregroundColor(.red)
                .padding(.bottom)
            }
            .navigationTitle("เลือกวันที่เดินทาง")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ปิด") { dismiss() }
                        .foregroundColor(.black)
                }
            }
        }
        .presentationDetents([.medium, .fraction(0.7)])
        .onAppear {
            if let start = selectedDate {
                startDate = start
                if let end = selectedEndDate {
                    endDate = end
                    selectionMode = 1
                } else {
                    selectionMode = 0
                }
            }
        }
    }
}

struct CategoryPicker: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCategory: TripCategory?
    
    var body: some View {
        NavigationView {
            List {
                Button("ทุกหมวดหมู่") {
                    selectedCategory = nil
                    dismiss()
                }
                .foregroundColor(.adaptiveText)
                
                ForEach(TripCategory.allCases, id: \.self) { category in
                    Button(category.rawValue) {
                        selectedCategory = category
                        dismiss()
                    }
                    .foregroundColor(.adaptiveText)
                }
            }
            .navigationTitle("เลือกหมวดหมู่")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ปิด") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

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
        "ทุกจังหวัด",
        "กรุงเทพมหานคร", "กระบี่", "กาญจนบุรี", "กาฬสินธุ์", "กำแพงเพชร", "ขอนแก่น", "จันทบุรี", "ฉะเชิงเทรา",
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
    @Binding var selectedDate: Date?
    @Binding var selectedEndDate: Date?
    
    @State private var startDate: Date? = nil
    @State private var endDate: Date? = nil
    
    init(selectedDate: Binding<Date?>, selectedEndDate: Binding<Date?> = .constant(nil)) {
        self._selectedDate = selectedDate
        self._selectedEndDate = selectedEndDate
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Instruction text
                        Text("แตะวันเริ่ม แล้วแตะวันสิ้นสุดได้เลย")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 12)
                        
                        CustomDateRangePicker(
                            startDate: $startDate,
                            endDate: $endDate
                        )
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 16)
                }
                
                // Bottom Actions
                VStack(spacing: 12) {
                    Button(action: {
                        selectedDate = startDate
                        selectedEndDate = endDate
                        dismiss()
                    }) {
                        Text("ตกลง")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(startDate != nil ? Color.black : Color.gray.opacity(0.4))
                            .cornerRadius(14)
                    }
                    .disabled(startDate == nil)
                    
                    Button("ล้างค่า") {
                        startDate = nil
                        endDate = nil
                        selectedDate = nil
                        selectedEndDate = nil
                        dismiss()
                    }
                    .foregroundColor(.gray)
                    .font(.system(size: 15, weight: .semibold))
                }
                .padding()
                .background(Color.adaptiveBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
            }
            .background(Color.adaptiveBackground.ignoresSafeArea())
            .navigationTitle("เลือกวันเดินทาง")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ปิด") { dismiss() }
                        .foregroundColor(.adaptiveText)
                }
            }
        }
        .presentationDetents([.large])
        .onAppear {
            startDate = selectedDate
            endDate = selectedEndDate
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

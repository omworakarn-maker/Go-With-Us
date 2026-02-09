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
            .foregroundColor(isSelected ? .white : .black)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.black : Color.white)
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
                .foregroundColor(.black)
                
                ForEach(provinces.filter { $0 != "ทุกจังหวัด" }, id: \.self) { province in
                    Button(province) {
                        selectedProvince = province
                        dismiss()
                    }
                    .foregroundColor(.black)
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
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("เลือกวันที่", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                
                Button(action: {
                    selectedDate = date
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
                    dismiss()
                }
                .padding(.top)
                .foregroundColor(.red)
                
                Spacer()
            }
            .navigationTitle("เลือกวันที่เดินทาง")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
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
                .foregroundColor(.black)
                
                ForEach(TripCategory.allCases, id: \.self) { category in
                    Button(category.rawValue) {
                        selectedCategory = category
                        dismiss()
                    }
                    .foregroundColor(.black)
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

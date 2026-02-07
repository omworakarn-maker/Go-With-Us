import SwiftUI

struct FilterBar: View {
    @Binding var selectedProvince: String?
    @Binding var selectedDate: Date?
    @Binding var selectedCategory: TripCategory?
    
    // UI State for Sheets
    @State private var showProvinceSheet = false
    @State private var showDateSheet = false
    @State private var showCategorySheet = false
    
    // Constants
    let provinces = [
        "ทุกจังหวัด", "กรุงเทพฯ", "เชียงใหม่", "ภูเก็ต", "ชลบุรี", "กระบี่",
        "กาญจนบุรี", "ขอนแก่น", "นครราชสีมา", "ประจวบคีรีขันธ์", "สุราษฎร์ธานี"
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Province Filter
                FilterButton(
                    title: selectedProvince != nil && selectedProvince != "ทุกจังหวัด" ? selectedProvince! : "ทุกจังหวัด",
                    isSelected: selectedProvince != nil && selectedProvince != "ทุกจังหวัด",
                    icon: "map",
                    action: { showProvinceSheet = true }
                )
                
                // Date Filter
                FilterButton(
                    title: selectedDate != nil ? formatDate(selectedDate!) : "วันที่เดินทาง",
                    isSelected: selectedDate != nil,
                    icon: "calendar",
                    action: { showDateSheet = true }
                )
                
                // Category Filter
                FilterButton(
                    title: selectedCategory?.rawValue ?? "หมวดหมู่",
                    isSelected: selectedCategory != nil,
                    icon: "camera.macro",
                    action: { showCategorySheet = true }
                )
                
                // Clear Filters (Only show if any filter is active)
                if selectedProvince != nil || selectedDate != nil || selectedCategory != nil {
                    Button(action: {
                        withAnimation {
                            selectedProvince = nil
                            selectedDate = nil
                            selectedCategory = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        
        // Sheets
        .sheet(isPresented: $showProvinceSheet) {
            ProvincePicker(selectedProvince: $selectedProvince)
        }
        .sheet(isPresented: $showDateSheet) {
            DatePickerSheet(selectedDate: $selectedDate)
        }
        .sheet(isPresented: $showCategorySheet) {
            CategoryPicker(selectedCategory: $selectedCategory)
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "th_TH")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

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
        "ทุกจังหวัด", "กรุงเทพฯ", "เชียงใหม่", "ภูเก็ต", "ชลบุรี", "กระบี่",
        "กาญจนบุรี", "ขอนแก่น", "นครราชสีมา", "ประจวบคีรีขันธ์", "สุราษฎร์ธานี"
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
        .presentationDetents([.medium])
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

import SwiftUI

struct FilterBar: View {
    @Binding var selectedProvince: String?
    @Binding var selectedDate: Date?
    @Binding var selectedEndDate: Date? // Add binding for End Date
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
                    title: formatDateButtonTitle(),
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
                            selectedEndDate = nil
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
            DatePickerSheet(selectedDate: $selectedDate, selectedEndDate: $selectedEndDate)
        }
        .sheet(isPresented: $showCategorySheet) {
            CategoryPicker(selectedCategory: $selectedCategory)
        }
    }
    
    func formatDateButtonTitle() -> String {
        guard let start = selectedDate else { return "วันที่เดินทาง" }
        if let end = selectedEndDate {
            return "\(formatDate(start)) - \(formatDate(end))"
        }
        return formatDate(start)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "th_TH")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}



import SwiftUI

struct FilterBar: View {
    @ObservedObject private var settings = SettingsManager.shared
    @Binding var selectedProvince: String?
    @Binding var selectedDate: Date?
    @Binding var selectedEndDate: Date? // Add binding for End Date
    @Binding var selectedCategory: TripCategory?
    
    // UI State for Sheets
    @State private var showProvinceSheet = false
    @State private var showDateSheet = false
    @State private var showCategorySheet = false
    
    // Constants removed since using ProvincePicker
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Province Filter
                FilterButton(
                    title: selectedProvince != nil && selectedProvince != "ทุกจังหวัด" ? localizedPlaceName(selectedProvince!) : settings.text(thai: "ทุกจังหวัด", english: "All provinces"),
                    isSelected: selectedProvince != nil && selectedProvince != "ทุกจังหวัด",
                    icon: "📍",
                    action: { showProvinceSheet = true }
                )
                
                // Date Filter
                FilterButton(
                    title: formatDateButtonTitle(),
                    isSelected: selectedDate != nil,
                    icon: "🗓️",
                    action: { showDateSheet = true }
                )
                
                // Category Filter
                FilterButton(
                    title: selectedCategory?.displayName ?? settings.text(thai: "สไตล์", english: "Style"),
                    isSelected: selectedCategory != nil,
                    icon: "🧭",
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
        }
        .safeAreaPadding(.horizontal, 16)
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
        guard let start = selectedDate else { return settings.text(thai: "วันที่เดินทาง", english: "Travel dates") }
        if let end = selectedEndDate {
            return "\(formatDate(start)) - \(formatDate(end))"
        }
        return formatDate(start)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: settings.currentLanguage == .thai ? "th_TH" : "en_US")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

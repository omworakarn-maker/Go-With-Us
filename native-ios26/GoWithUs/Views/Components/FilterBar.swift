import SwiftUI

struct FilterBar: View {
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var selectedProvince: String?
    @Binding var selectedDate: Date?
    @Binding var selectedEndDate: Date? // Add binding for End Date
    @Binding var selectedCategory: TripCategory?
    var horizontalInset: CGFloat = 16

    // UI State for Sheets
    @State private var showProvinceSheet = false
    @State private var showDateSheet = false
    @State private var showCategorySheet = false

    // Constants removed since using ProvincePicker

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 10) {
                    // Province Filter
                    FilterButton(
                        title: selectedProvince != nil && selectedProvince != "ทุกจังหวัด" ? localizedPlaceName(selectedProvince!) : settings.text(thai: "ทุกจังหวัด", english: "All provinces"),
                        isSelected: selectedProvince != nil && selectedProvince != "ทุกจังหวัด",
                        icon: "mappin.and.ellipse",
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
                        title: selectedCategory?.displayName ?? settings.text(thai: "สไตล์", english: "Style"),
                        isSelected: selectedCategory != nil,
                        icon: "slider.horizontal.3",
                        action: { showCategorySheet = true }
                    )

                    // Clear Filters (Only show if any filter is active)
                    if selectedProvince != nil || selectedDate != nil || selectedCategory != nil {
                        Button(action: {
                            withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.78)) {
                                selectedProvince = nil
                                selectedDate = nil
                                selectedEndDate = nil
                                selectedCategory = nil
                            }
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 20, height: 20)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .accessibilityLabel(tr("ล้างตัวกรอง", "Clear filters"))
                    }
                }
            }
            .padding(.horizontal, horizontalInset)
            .padding(.vertical, 10)
        }
        .scrollClipDisabled()
        .zIndex(2)

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


// Search and filters share one row without placing a text field inside a scroller.
struct HomeSearchFilterBar: View {
    @Binding var searchText: String
    var focus: FocusState<Bool>.Binding
    @Binding var selectedProvince: String?
    @Binding var selectedDate: Date?
    @Binding var selectedEndDate: Date?
    @Binding var selectedCategory: TripCategory?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false

    var body: some View {
        HStack(spacing: 12) {
            ExpandingTripSearch(text: $searchText, focus: focus, expanded: $expanded)
                .zIndex(3)
            if !expanded {
                FilterBar(
                    selectedProvince: $selectedProvince,
                    selectedDate: $selectedDate,
                    selectedEndDate: $selectedEndDate,
                    selectedCategory: $selectedCategory,
                    horizontalInset: 8
                )
                .frame(maxWidth: .infinity)
                // Keep scrolling chips inside their own horizontal viewport;
                // preserve vertical room for the native glass shadow.
                .mask { Rectangle().padding(.vertical, -16) }
                .zIndex(0)
                .transition(.opacity)
            }
        }
        .frame(minHeight: 64)
        .padding(.horizontal, 16)
        .animation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.36, dampingFraction: 0.88), value: expanded)
    }
}

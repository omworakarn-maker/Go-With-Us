import SwiftUI

struct FilterBar: View {
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var selectedProvince: String?
    @Binding var selectedDate: Date?
    @Binding var selectedEndDate: Date? // Add binding for End Date
    @Binding var selectedCategory: TripCategory?
    var horizontalInset: CGFloat = 16
    var embedded = false

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
                        action: { showProvinceSheet = true },
                        embedded: embedded
                    )

                    // Date Filter
                    FilterButton(
                        title: formatDateButtonTitle(),
                        isSelected: selectedDate != nil,
                        icon: "calendar",
                        action: { showDateSheet = true },
                        embedded: embedded
                    )

                    // Category Filter
                    FilterButton(
                        title: selectedCategory?.displayName ?? settings.text(thai: "สไตล์", english: "Style"),
                        isSelected: selectedCategory != nil,
                        icon: "slider.horizontal.3",
                        action: { showCategorySheet = true },
                        embedded: embedded
                    )

                    // Clear Filters (Only show if any filter is active)
                    if !embedded && (selectedProvince != nil || selectedDate != nil || selectedEndDate != nil || selectedCategory != nil) {
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
                        .buttonStyle(.plain)
                        .buttonBorderShape(.circle)
                        .accessibilityLabel(tr("ล้างตัวกรอง", "Clear filters"))
                    }
                }
            }
            .padding(.horizontal, horizontalInset)
            .padding(.vertical, embedded ? 0 : 10)
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
        HStack(spacing: 8) {
            ExpandingTripSearch(text: $searchText, focus: focus, expanded: $expanded)
                .zIndex(3)
            if !expanded {
                FilterBar(
                    selectedProvince: $selectedProvince,
                    selectedDate: $selectedDate,
                    selectedEndDate: $selectedEndDate,
                    selectedCategory: $selectedCategory,
                    horizontalInset: 4,
                    embedded: true
                )
                .frame(maxWidth: .infinity)
                // Keep scrolling chips inside their own horizontal viewport;
                // preserve vertical room for the native glass shadow.
                .mask { Rectangle().padding(.vertical, -16) }
                .zIndex(0)
                .transition(.opacity)

                if selectedProvince != nil || selectedDate != nil || selectedEndDate != nil || selectedCategory != nil {
                    Button {
                        SettingsManager.shared.triggerSelection()
                        withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.78)) {
                            selectedProvince = nil
                            selectedDate = nil
                            selectedEndDate = nil
                            selectedCategory = nil
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.secondary)
                            .frame(width: 44, height: 48)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(SettingsManager.shared.text(thai: "ล้างตัวกรอง", english: "Clear filters"))
                    .transition(.opacity)
                }
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 16)
        .animation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.36, dampingFraction: 0.88), value: expanded)
    }
}

import SwiftUI

/// The system segmented picker owns its selection animation and accessibility.
struct SegmentedControl: View {
    let options: [String]
    var values: [String]? = nil
    @Binding var selected: String

    private func value(at index: Int) -> String {
        guard let values, values.indices.contains(index) else { return options[index] }
        return values[index]
    }

    var body: some View {
        Picker(tr("หมวดทริป", "Trip category"), selection: $selected) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Text(option).tag(value(at: index))
            }
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
        .tint(.appSecondary)
        .padding(.vertical, 4)
        .onChange(of: selected) { _, _ in
            SettingsManager.shared.triggerSelection()
        }
    }
}

#Preview {
    SegmentedControl(options: ["แนะนำ", "มาใหม่", "ยอดนิยม"], selected: .constant("แนะนำ"))
        .padding()
}

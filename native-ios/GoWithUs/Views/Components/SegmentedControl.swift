import SwiftUI

struct SegmentedControl: View {
    let options: [String]
    @Binding var selected: String
    @Namespace private var namespace
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Text(option)
                    .font(.system(size: 14, weight: selected == option ? .bold : .medium))
                    .foregroundColor(selected == option ? .white : .adaptiveText.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8) // Reduced from 10 to prevent overflow
                    .background(
                        ZStack {
                            if selected == option {
                                Capsule()
                                    .fill(Color.appSecondary) // Updated to Ocean Blue theme
                                    .matchedGeometryEffect(id: "THUMB", in: namespace)
                            }
                        }
                    )
                    .contentShape(Capsule())
                    .onTapGesture {
                        updateSelection(at: CGPoint(x: (CGFloat(options.firstIndex(of: option) ?? 0) * 100) + 50, y: 10), in: CGSize(width: 300, height: 40)) // Fallback tap, though drag gesture handles it
                    }
            }
        }
        .padding(4) // Tightened outer padding
        .background(Color.gray.opacity(0.15))
        .clipShape(Capsule()) // Ensures nothing bleeds out
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        // Invisible overlay to handle continuous drag
        .overlay(
            GeometryReader { geo in
                Color.clear
                    .contentShape(Capsule())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateSelection(at: value.location, in: geo.size)
                            }
                    )
            }
        )
    }
    
    private func updateSelection(at location: CGPoint, in size: CGSize) {
        guard !options.isEmpty else { return }
        let segmentWidth = size.width / CGFloat(options.count)
        let index = Int(location.x / segmentWidth)
        
        if index >= 0 && index < options.count {
            let newSelected = options[index]
            if selected != newSelected {
                SettingsManager.shared.triggerSelection()
                withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.65, blendDuration: 0.5)) {
                    selected = newSelected
                }
            }
        }
    }
}

#Preview {
    ZStack {
        // Colorful background to test glass effect
        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
        SegmentedControl(
            options: ["แนะนำ", "มาใหม่", "ยอดนิยม"],
            selected: .constant("แนะนำ")
        )
        .padding()
    }
}

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
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            if selected == option {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.appAccent, Color(hex: "#FF6B6B")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .matchedGeometryEffect(id: "THUMB", in: namespace)
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.6), .clear],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                            }
                        }
                    )
                    .contentShape(Capsule())
            }
        }
        .padding(5)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.15))
        )
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

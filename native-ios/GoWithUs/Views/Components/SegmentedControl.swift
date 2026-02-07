import SwiftUI

struct SegmentedControl: View {
    let options: [String]
    @Binding var selected: String
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selected = option
                    }
                }) {
                    Text(option)
                        .font(.system(size: 14, weight: selected == option ? .bold : .medium))
                        .foregroundColor(selected == option ? .black : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selected == option ?
                            Color.white
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            : nil
                        )
                }
            }
        }
        .padding(4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(24)
    }
}

#Preview {
    SegmentedControl(
        options: ["แนะนำ", "มาใหม่", "ยอดนิยม"],
        selected: .constant("แนะนำ")
    )
    .padding()
}

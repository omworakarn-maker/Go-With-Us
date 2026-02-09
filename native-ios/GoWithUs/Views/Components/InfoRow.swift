import SwiftUI

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .stroke(Color.black, lineWidth: 1.5)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            Spacer()
        }
    }
}

#Preview {
    InfoRow(icon: "mappin.circle", title: "Location", value: "Bangkok")
        .padding()
}

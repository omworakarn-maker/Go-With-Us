import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                if let user = authViewModel.currentUser {
                    ScrollView {
                        VStack(spacing: 32) {
                            // Profile Header
                            VStack(spacing: 16) {
                                // Avatar
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Text(String(user.name.prefix(1)))
                                            .font(.system(size: 40, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(spacing: 4) {
                                    Text(user.name)
                                        .font(.system(size: 24, weight: .black))
                                        .foregroundColor(.black)
                                        .tracking(-0.5)
                                    
                                    Text(user.email)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                
                                if user.role == .admin {
                                    Text("ADMIN")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(Color.black)
                                        .cornerRadius(20)
                                }
                            }
                            .padding(.top, 32)
                            
                            // User Info
                            VStack(spacing: 16) {
                                if let travelStyle = user.travelStyle {
                                    let styleText = "\(travelStyle.budget.rawValue), \(travelStyle.pace.rawValue), \(travelStyle.social.rawValue)"
                                    InfoCard(title: "สไตล์การเดินทาง", value: styleText)
                                }
                                
                                if let interests = user.interests, !interests.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("ความสนใจ")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.gray)
                                            .textCase(.uppercase)
                                            .tracking(1)
                                        
                                        FlowLayout(spacing: 8) {
                                            ForEach(interests, id: \.self) { interest in
                                                Text(interest)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(.black)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(Color.gray.opacity(0.1))
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                                    )
                                    .cornerRadius(16)
                                }
                            }
                            
                            // Logout Button
                            Button(action: { showLogoutAlert = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.right.square")
                                    Text("ออกจากระบบ")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .cornerRadius(12)
                            }
                            
                            Spacer()
                        }
                        .padding(24)
                    }
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.black)
                        Text("กำลังโหลด...")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("โปรไฟล์")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("ออกจากระบบ", isPresented: $showLogoutAlert) {
            Button("ยกเลิก", role: .cancel) {}
            Button("ออกจากระบบ", role: .destructive) {
                authViewModel.logout()
            }
        } message: {
            Text("คุณต้องการออกจากระบบใช่หรือไม่?")
        }
    }
}

// MARK: - Info Card
struct InfoCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .tracking(1)
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.black)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}

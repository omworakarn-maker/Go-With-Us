import SwiftUI

struct JoinTripSheet: View {
    @ObservedObject var viewModel: TripDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var interests = ""
    @State private var showErrorAlert = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.appPrimary)
                .padding(.top, 32)
            
            VStack(spacing: 8) {
                Text("ยืนยันการเข้าร่วม")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.adaptiveText)
                
                Text("คุณต้องการเข้าร่วมทริปนี้ใช่หรือไม่?")
                    .font(.system(size: 15))
                    .foregroundColor(.adaptiveSecondaryText)
            }
            
            HStack(spacing: 16) {
                Button(action: {
                    dismiss()
                }) {
                    Text("ยกเลิก")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.black)
                        .cornerRadius(14)
                }
                
                Button(action: {
                    Task {
                        let success = await viewModel.joinTrip(interests: [])
                        if success {
                            dismiss()
                        } else {
                            showErrorAlert = true
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isJoining {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        }
                        Text(viewModel.isJoining ? "กำลังเข้าร่วม..." : "ยืนยันเข้าร่วม")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [.appPrimary, .appSecondary], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(14)
                    .shadow(color: Color.appPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(viewModel.isJoining)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            
            Spacer()
        }
        .presentationDetents([.height(320)])
        .alert("ไม่สามารถเข้าร่วมได้", isPresented: $showErrorAlert) {
            Button("ตรวจสอบ", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง")
        }
    }
}

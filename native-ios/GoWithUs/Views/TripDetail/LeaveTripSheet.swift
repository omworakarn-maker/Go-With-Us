import SwiftUI

struct LeaveTripSheet: View {
    @ObservedObject var viewModel: TripDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showErrorAlert = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.fill.xmark")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#EF4444"))
                .padding(.top, 32)
            
            VStack(spacing: 8) {
                Text("ยืนยันการออกจากทริป")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.adaptiveText)
                
                Text("คุณต้องการออกจากทริปนี้ใช่หรือไม่?")
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
                        let success = await viewModel.leaveTrip()
                        if success {
                            dismiss()
                        } else {
                            showErrorAlert = true
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isLeaving {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        }
                        Text(viewModel.isLeaving ? "กำลังออก..." : "ยืนยัน")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#EF4444"))
                    .cornerRadius(14)
                    .shadow(color: Color(hex: "#EF4444").opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .disabled(viewModel.isLeaving)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            
            Spacer()
        }
        .presentationDetents([.height(300)])
        .alert("ไม่สามารถออกจากทริปได้", isPresented: $showErrorAlert) {
            Button("ตกลง", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง")
        }
    }
}

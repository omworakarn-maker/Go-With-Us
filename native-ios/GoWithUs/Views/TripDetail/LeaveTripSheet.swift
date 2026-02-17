import SwiftUI

struct LeaveTripSheet: View {
    @ObservedObject var viewModel: TripDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showErrorAlert = false
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("ยืนยันการออกจากทริป")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.black)
                
                Text("คุณต้องการออกจากทริปนี้ใช่หรือไม่?")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            .padding(.top, 32)
            
            HStack(spacing: 16) {
                Button(action: {
                    dismiss()
                }) {
                    Text("ยกเลิก")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(12)
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
                    Text(viewModel.isLeaving ? "กำลังออก..." : "ยืนยัน")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .disabled(viewModel.isLeaving)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .presentationDetents([.height(250)])
        .alert("ไม่สามารถออกจากทริปได้", isPresented: $showErrorAlert) {
            Button("ตกลง", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง")
        }
    }
}

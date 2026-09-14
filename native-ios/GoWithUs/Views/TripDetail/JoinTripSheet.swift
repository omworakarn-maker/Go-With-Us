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
                Text(SettingsManager.shared.text(thai: "ยืนยันการเข้าร่วม", english: "Confirm joining"))
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.adaptiveText)
                
                Text(SettingsManager.shared.text(thai: "คุณต้องการเข้าร่วมทริปนี้ใช่หรือไม่?", english: "Would you like to join this trip?"))
                    .font(.system(size: 15))
                    .foregroundColor(.adaptiveSecondaryText)
            }
            
            HStack(spacing: 16) {
                Button(action: {
                    dismiss()
                }) {
                    Text(SettingsManager.shared.text(thai: "ยกเลิก", english: "Cancel"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#EF4444"))
                        .cornerRadius(14)
                        .shadow(color: Color(hex: "#EF4444").opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                
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
                        Text(viewModel.isJoining ? tr("กำลังเข้าร่วม...", "Joining…") : tr("ยืนยันเข้าร่วม", "Confirm joining"))
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appPrimary)
                    .cornerRadius(14)
                    .shadow(color: Color.appPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(viewModel.isJoining)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            
            Spacer()
        }
        .presentationDetents([.height(280)])
        .alert(SettingsManager.shared.text(thai: "ไม่สามารถเข้าร่วมได้", english: "Unable to join"), isPresented: $showErrorAlert) {
            Button(SettingsManager.shared.text(thai: "ตรวจสอบ", english: "OK"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? tr("เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง", "Something went wrong. Please try again."))
        }
    }
}

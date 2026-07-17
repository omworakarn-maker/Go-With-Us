import SwiftUI

struct OTPVerificationView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var otp: String = ""
    @State private var isVerifying: Bool = false
    @State private var timeRemaining = 60
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "envelope.badge")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 10)
                
                Text("ยืนยันอีเมล")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("กรุณากรอกรหัส 6 หลักที่ส่งไปที่")
                    .foregroundColor(.secondary)
                Text(viewModel.email)
                    .fontWeight(.semibold)
            }
            .padding(.top, 40)
            
            // OTP Input
            TextField("รหัส OTP", text: $otp)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .multilineTextAlignment(.center)
                .font(.system(size: 32, weight: .bold))
                .tracking(10)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .frame(width: 250)
                .onChange(of: otp) { newValue in
                    if newValue.count > 6 {
                        otp = String(newValue.prefix(6))
                    }
                }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            // Verify Button
            Button(action: verifyOTP) {
                HStack {
                    if isVerifying {
                        ProgressView()
                            .tint(.white)
                            .padding(.trailing, 8)
                    }
                    Text("ยืนยันรหัส")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(otp.count == 6 ? Color.accentColor : Color.gray)
                .cornerRadius(12)
            }
            .disabled(otp.count < 6 || isVerifying)
            
            // Resend Button
            HStack {
                Text("ไม่ได้รับรหัส?")
                    .foregroundColor(.secondary)
                
                Button(action: resendOTP) {
                    Text(timeRemaining > 0 ? "ส่งใหม่ใน \(timeRemaining) วิ" : "ส่งรหัสใหม่")
                        .fontWeight(.semibold)
                        .foregroundColor(timeRemaining > 0 ? .gray : .accentColor)
                }
                .disabled(timeRemaining > 0)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func verifyOTP() {
        isVerifying = true
        Task {
            let success = await viewModel.verifyOTP(otp: otp)
            if success {
                dismiss() // This will pop back and since isAuthenticated = true, it goes to Main app or Onboarding
            } else {
                isVerifying = false
            }
        }
    }
    
    private func resendOTP() {
        timeRemaining = 60
        startTimer()
        Task {
            await viewModel.resendOTP()
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
            }
        }
    }
}

#Preview {
    let vm = AuthViewModel()
    vm.email = "test@example.com"
    return OTPVerificationView()
        .environmentObject(vm)
}

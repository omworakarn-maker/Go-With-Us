import SwiftUI

struct OTPVerificationView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var otp: String = ""
    @State private var isVerifying: Bool = false
    @State private var timeRemaining = 60
    @State private var timer: Timer? = nil
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "envelope.badge")
                        .font(.system(size: 50, weight: .light))
                        .foregroundColor(Color.appPrimary)
                        .padding(.bottom, 16)
                    
                    Text("ยืนยันอีเมล")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.adaptiveText)
                    
                    VStack(spacing: 4) {
                        Text("กรุณากรอกรหัส 6 หลักที่ส่งไปที่")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                        Text(viewModel.email)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.adaptiveText)
                    }
                }
                .padding(.top, 40)
                
                // OTP Input
                TextField("------", text: $otp)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .tracking(8)
                    .foregroundColor(.adaptiveText)
                    .tint(Color.appPrimary)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                    .background(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(otp.count == 6 ? Color.appPrimary : Color.gray.opacity(0.2), lineWidth: 1.5)
                    )
                    .cornerRadius(16)
                    .frame(width: 280)
                    .onChange(of: otp) { newValue in
                        // Keep only numbers
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            otp = filtered
                        }
                        if filtered.count > 6 {
                            otp = String(filtered.prefix(6))
                        } else if filtered.count == 6 && !isVerifying {
                            hideKeyboard()
                            verifyOTP()
                        }
                    }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                // Verify Button
                Button(action: verifyOTP) {
                    HStack(spacing: 8) {
                        if isVerifying {
                            ProgressView()
                                .tint(Color.adaptiveBackground)
                        } else {
                            Text("ยืนยันรหัส")
                                .font(.system(size: 15, weight: .bold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(otp.count == 6 && !isVerifying ? Color.appPrimary : Color.gray.opacity(0.3))
                    .foregroundColor(otp.count == 6 && !isVerifying ? .white : .gray)
                    .cornerRadius(12)
                }
                .disabled(otp.count < 6 || isVerifying)
                .padding(.horizontal, 32)
                .padding(.top, 16)
                
                // Resend Button
                HStack(spacing: 4) {
                    Text("ไม่ได้รับรหัส?")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Button(action: resendOTP) {
                        Text(timeRemaining > 0 ? "ส่งใหม่ใน \(timeRemaining) วิ" : "ส่งรหัสใหม่")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(timeRemaining > 0 ? .gray : Color.appPrimary)
                    }
                    .disabled(timeRemaining > 0)
                }
                .padding(.top, 8)
                
                Spacer()
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func verifyOTP() {
        withAnimation {
            isVerifying = true
        }
        Task {
            let success = await viewModel.verifyOTP(otp: otp)
            await MainActor.run {
                if success {
                    dismiss()
                } else {
                    withAnimation {
                        isVerifying = false
                    }
                }
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

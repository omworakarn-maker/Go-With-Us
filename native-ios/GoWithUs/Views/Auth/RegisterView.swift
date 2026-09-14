import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        ZStack {
            // White Background
            Color.adaptiveBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.adaptiveText)
                    }
                    Spacer()
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Title
                        VStack(spacing: 12) {
                            Text(tr("สมัครสมาชิก", "Sign up"))
                                .font(.system(size: 36, weight: .black))
                                .foregroundColor(.adaptiveText)
                                .tracking(-1)
                            
                            Text(tr("เริ่มต้นการผจญภัยของคุณ", "Start your adventure"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 32)
                        
                        // Register Form
                        VStack(spacing: 16) {
                            // Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text(tr("ชื่อ", "Name"))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                    .tracking(1)
                                
                                TextField("", text: $viewModel.name)
                                    .placeholder(when: viewModel.name.isEmpty) {
                                        Text(tr("ชื่อของคุณ", "Your name"))
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                    .foregroundColor(.adaptiveText)
                                    .tint(Color.appPrimary)
                                    .padding()
                                    .background(Color.gray.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .cornerRadius(12)
                            }
                            
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text(tr("อีเมล", "Email"))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                    .tracking(1)
                                
                                TextField("", text: $viewModel.email)
                                    .placeholder(when: viewModel.email.isEmpty) {
                                        Text(SettingsManager.shared.localizedString(for: "email_placeholder"))
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                    .foregroundColor(.adaptiveText)
                                    .tint(Color.appPrimary)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .padding()
                                    .background(Color.gray.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .cornerRadius(12)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text(tr("รหัสผ่าน", "Password"))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                    .tracking(1)
                                
                                HStack {
                                    if showPassword {
                                        TextField("", text: $viewModel.password)
                                            .placeholder(when: viewModel.password.isEmpty) {
                                                Text(tr("อย่างน้อย 6 ตัวอักษร", "At least 6 characters"))
                                                    .foregroundColor(.gray.opacity(0.5))
                                            }
                                            .foregroundColor(.adaptiveText)
                                            .tint(Color.appPrimary)
                                    } else {
                                        SecureField("", text: $viewModel.password)
                                            .placeholder(when: viewModel.password.isEmpty) {
                                                Text(tr("อย่างน้อย 6 ตัวอักษร", "At least 6 characters"))
                                                    .foregroundColor(.gray.opacity(0.5))
                                            }
                                            .foregroundColor(.adaptiveText)
                                            .tint(Color.appPrimary)
                                    }
                                    
                                    Button(action: { showPassword.toggle() }) {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .cornerRadius(12)
                            }
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text(tr("ยืนยันรหัสผ่าน", "Confirm password"))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                    .tracking(1)
                                
                                HStack {
                                    if showConfirmPassword {
                                        TextField("", text: $viewModel.confirmPassword)
                                            .placeholder(when: viewModel.confirmPassword.isEmpty) {
                                                Text(tr("พิมพ์รหัสผ่านอีกครั้ง", "Enter your password again"))
                                                    .foregroundColor(.gray.opacity(0.5))
                                            }
                                            .foregroundColor(.adaptiveText)
                                            .tint(Color.appPrimary)
                                    } else {
                                        SecureField("", text: $viewModel.confirmPassword)
                                            .placeholder(when: viewModel.confirmPassword.isEmpty) {
                                                Text(tr("พิมพ์รหัสผ่านอีกครั้ง", "Enter your password again"))
                                                    .foregroundColor(.gray.opacity(0.5))
                                            }
                                            .foregroundColor(.adaptiveText)
                                            .tint(Color.appPrimary)
                                    }
                                    
                                    Button(action: { showConfirmPassword.toggle() }) {
                                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .cornerRadius(12)
                            }
                            
                            // Error Message
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.adaptiveText)
                                    .padding(.horizontal)
                            }
                            
                            // Register Button
                            Button(action: {
                                Task {
                                    await viewModel.register()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text(tr("สมัครสมาชิก", "Sign up"))
                                            .font(.system(size: 15, weight: .bold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.appPrimary)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(viewModel.isLoading)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 32)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onTapGesture {
            hideKeyboard()
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthViewModel())
}

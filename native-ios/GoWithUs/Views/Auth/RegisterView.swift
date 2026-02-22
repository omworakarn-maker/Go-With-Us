import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
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
                            Text("สมัครสมาชิก")
                                .font(.system(size: 36, weight: .black))
                                .foregroundColor(.adaptiveText)
                                .tracking(-1)
                            
                            Text("เริ่มต้นการผจญภัยของคุณ")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 32)
                        
                        // Register Form
                        VStack(spacing: 16) {
                            // Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ชื่อ")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                    .tracking(1)
                                
                                TextField("", text: $viewModel.name)
                                    .placeholder(when: viewModel.name.isEmpty) {
                                        Text("ชื่อของคุณ")
                                            .foregroundColor(.gray.opacity(0.1))
                                    }
                                    .foregroundColor(.adaptiveText)
                                    .tint(.adaptiveText)
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
                                Text("อีเมล")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                    .tracking(1)
                                
                                TextField("", text: $viewModel.email)
                                    .placeholder(when: viewModel.email.isEmpty) {
                                        Text("your@email.com")
                                            .foregroundColor(.gray.opacity(0.1))
                                    }
                                    .foregroundColor(.adaptiveText)
                                    .tint(.adaptiveText)
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
                                Text("รหัสผ่าน")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                    .tracking(1)
                                
                                SecureField("", text: $viewModel.password)
                                    .placeholder(when: viewModel.password.isEmpty) {
                                        Text("อย่างน้อย 6 ตัวอักษร")
                                            .foregroundColor(.gray.opacity(0.1))
                                    }
                                    .foregroundColor(.adaptiveText)
                                    .tint(.adaptiveText)
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
                                    if viewModel.isAuthenticated {
                                        dismiss()
                                    }
                                }
                            }) {
                                HStack(spacing: 8) {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("สมัครสมาชิก")
                                            .font(.system(size: 15, weight: .bold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.adaptiveText)
                                .foregroundColor(Color.adaptiveBackground)
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

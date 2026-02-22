import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // White Background
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo - Minimal Black Circle
                    VStack(spacing: 24) {
                        Circle()
                            .fill(Color.adaptiveText)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .fill(Color.adaptiveBackground)
                                    .frame(width: 12, height: 12)
                            )
                        
                        VStack(spacing: 8) {
                            Text("GoWithUs")
                                .font(.system(size: 42, weight: .black))
                                .foregroundColor(.adaptiveText)
                                .tracking(-1)
                            
                            Text("ไปกับเรา สนุกกว่า")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // Login Form
                    VStack(spacing: 16) {
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
                                .tint(.black)
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
                                    Text("••••••••")
                                        .foregroundColor(.gray.opacity(0.1))
                                }
                                .foregroundColor(.adaptiveText)
                                .tint(.black)
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
                        
                        // Login Button
                        Button(action: {
                            Task {
                                await viewModel.login()
                            }
                        }) {
                            HStack(spacing: 8) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("เข้าสู่ระบบ")
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
                        
                        // Register Link
                        NavigationLink(destination: RegisterView()) {
                            HStack(spacing: 4) {
                                Text("ยังไม่มีบัญชี?")
                                    .foregroundColor(.gray)
                                Text("สมัครสมาชิก")
                                    .foregroundColor(.adaptiveText)
                                    .fontWeight(.bold)
                            }
                            .font(.system(size: 13))
                        }
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}

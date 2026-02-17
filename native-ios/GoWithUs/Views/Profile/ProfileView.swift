import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showLogoutAlert = false
    @State private var showEditProfile = false
    @State private var showAdminAlert = false
    @State private var showImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var localProfileImage: UIImage?
    
    var body: some View {

        NavigationStack {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                if let user = authViewModel.currentUser {
                    ScrollView {
                        VStack(spacing: 32) {
                            // Profile Header
                            VStack(spacing: 16) {
                                // Avatar with photo picker
                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    ZStack(alignment: .bottomTrailing) {
                                        if let image = localProfileImage {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipShape(Circle())
                                        } else if let profileImageStr = user.profileImage, !profileImageStr.isEmpty,
                                                  let uiImage = Self.decodeBase64Image(profileImageStr) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipShape(Circle())
                                        } else {
                                            Circle()
                                                .fill(Color.adaptiveText)
                                                .frame(width: 100, height: 100)
                                                .overlay(
                                                    Text(String(user.name.prefix(1)))
                                                        .font(.system(size: 40, weight: .bold))
                                                        .foregroundColor(Color.adaptiveBackground)
                                                )
                                        }
                                        
                                        // Camera icon overlay
                                        Circle()
                                            .fill(Color.appAccent)
                                            .frame(width: 30, height: 30)
                                            .overlay(
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.white)
                                            )
                                            .offset(x: 2, y: 2)
                                    }
                                }
                                .onChange(of: selectedItem) { newItem in
                                    Task {
                                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                                           let uiImage = UIImage(data: data) {
                                            localProfileImage = uiImage
                                            // Save locally as cache
                                            if let jpegData = uiImage.jpegData(compressionQuality: 0.5) {
                                                UserDefaults.standard.set(jpegData, forKey: "local_profile_image")
                                                // Upload to backend
                                                let base64Str = "data:image/jpeg;base64," + jpegData.base64EncodedString()
                                                await authViewModel.updateProfile(
                                                    name: user.name,
                                                    interests: user.interests ?? [],
                                                    profileImage: base64Str
                                                )
                                            }
                                        }
                                    }
                                }
                                
                                // Delete photo button
                                if localProfileImage != nil || (user.profileImage != nil && !user.profileImage!.isEmpty) {
                                    Button {
                                        Task {
                                            localProfileImage = nil
                                            UserDefaults.standard.removeObject(forKey: "local_profile_image")
                                            await authViewModel.updateProfile(
                                                name: user.name,
                                                interests: user.interests ?? [],
                                                profileImage: ""
                                            )
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 11))
                                            Text("ลบรูป")
                                                .font(.system(size: 12, weight: .bold))
                                        }
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(16)
                                    }
                                    .padding(.top, 4)
                                }
                                
                                VStack(spacing: 4) {
                                    Text(user.name)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.adaptiveText)
                                    
                                    // @ handle
                                    if let username = UserDefaults.standard.string(forKey: "user_handle"), !username.isEmpty {
                                        Text("@\(username)")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.appAccent)
                                    }
                                    
                                    Text(user.email)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.adaptiveSecondaryText)
                                }
                                
                                if user.role == .admin {
                                    Text("ADMIN")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(Color.adaptiveBackground)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(Color.adaptiveText)
                                        .cornerRadius(20)
                                }
                            }
                            .padding(.top, 32)
                            
                            // User Info
                            VStack(spacing: 16) {
                                // Basic Info Cards
                                if user.gender != nil || user.age != nil {
                                    HStack(spacing: 12) {
                                        if let gender = user.gender {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text("เพศ")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(.adaptiveSecondaryText)
                                                    .textCase(.uppercase)
                                                    .tracking(1)
                                                
                                                Text(gender == "male" ? "ชาย" : gender == "female" ? "หญิง" : "อื่นๆ")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.adaptiveText)
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.adaptiveCardTint)
                                            .cornerRadius(12)
                                        }
                                        
                                        if let age = user.age {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text("อายุ")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(.adaptiveSecondaryText)
                                                    .textCase(.uppercase)
                                                    .tracking(1)
                                                
                                                Text("\(age) ปี")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.adaptiveText)
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.adaptiveCardTint)
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                                
                                // Bio Section
                                if let bio = user.bio, !bio.trimmingCharacters(in: .whitespaces).isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("ประวัติส่วนตัว")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.adaptiveSecondaryText)
                                            .textCase(.uppercase)
                                            .tracking(1)
                                        
                                        Text(bio)
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.adaptiveText)
                                            .lineLimit(nil)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.adaptiveCardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.adaptiveBorder, lineWidth: 1)
                                    )
                                    .cornerRadius(16)
                                }
                                
                                if let style = user.travelStyle {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("สไตล์การเดินทาง")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.adaptiveSecondaryText)
                                            .textCase(.uppercase)
                                            .tracking(1)
                                        
                                        let tags = [
                                            style.budget, style.pace, style.social, style.accommodation,
                                            style.food, style.nightlife, style.transport, style.photography
                                        ].compactMap { $0?.replacingOccurrences(of: "_", with: " ").capitalized }
                                        
                                        if !tags.isEmpty {
                                            FlowLayout(spacing: 8) {
                                                ForEach(tags, id: \.self) { tag in
                                                    Text(tag)
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundColor(Color.adaptiveBackground)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 6)
                                                        .background(Color.adaptiveText)
                                                        .cornerRadius(20)
                                                }
                                            }
                                        } else {
                                            Text("ยังไม่ได้ระบุสไตล์การเดินทาง")
                                                .font(.system(size: 14))
                                                .foregroundColor(.adaptiveSecondaryText)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.adaptiveCardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.adaptiveBorder, lineWidth: 1)
                                    )
                                    .cornerRadius(16)
                                }
                                
                                if let interests = user.interests, !interests.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("ความสนใจ")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.adaptiveSecondaryText)
                                            .textCase(.uppercase)
                                            .tracking(1)
                                        
                                        FlowLayout(spacing: 8) {
                                            ForEach(interests, id: \.self) { interest in
                                                Text(interest)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(.adaptiveText)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(Color.adaptiveCardTint)
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.adaptiveCardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.adaptiveBorder, lineWidth: 1)
                                    )
                                    .cornerRadius(16)
                                }
                            }
                            
                            // Admin Alert Button (Admin Only)
                            if user.role == .admin {
                                Button(action: { showAdminAlert = true }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "bell.badge.fill")
                                        Text("สร้างการแจ้งเตือน")
                                            .font(.system(size: 15, weight: .bold))
                                    }
                                    .foregroundColor(Color.adaptiveBackground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.adaptiveText)
                                    .cornerRadius(12)
                                }
                            }
                            
                            // Logout Button
                            Button(action: { showLogoutAlert = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.right.square")
                                    Text("ออกจากระบบ")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .foregroundColor(.adaptiveText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.adaptiveCardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.adaptiveText, lineWidth: 2)
                                )
                                .cornerRadius(12)
                            }
                            
                            Spacer()
                        }
                        .padding(24)
                        .padding(.bottom, 80) // Space for TabBar
                    }
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.adaptiveText)
                        Text("กำลังโหลด...")
                            .foregroundColor(.adaptiveSecondaryText)
                    }
                }
            }
            .navigationTitle("โปรไฟล์")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("แก้ไข") {
                        showEditProfile = true
                    }
                    .foregroundColor(.appAccent)
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showAdminAlert) {
                AdminAlertView()
            }
            .onAppear {
                // Load saved profile image
                if let data = UserDefaults.standard.data(forKey: "local_profile_image"),
                   let image = UIImage(data: data) {
                    localProfileImage = image
                }
            }
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
    
    // MARK: - Helpers
    static func decodeBase64Image(_ str: String) -> UIImage? {
        let base64Str: String
        if str.contains(",") {
            base64Str = String(str.split(separator: ",").last ?? "")
        } else {
            base64Str = str
        }
        guard let data = Data(base64Encoded: base64Str) else { return nil }
        return UIImage(data: data)
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
                .foregroundColor(.adaptiveSecondaryText)
                .textCase(.uppercase)
                .tracking(1)
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.adaptiveText)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.adaptiveCardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.adaptiveBorder, lineWidth: 1)
        )
        .cornerRadius(16)
    }
}



#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}

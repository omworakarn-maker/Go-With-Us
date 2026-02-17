import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var username: String = ""
    @State private var selectedInterests: Set<String> = []
    @State private var gender: String = ""
    @State private var age: String = ""
    @State private var bio: String = ""
    @State private var birthDate = Date()
    @State private var showBirthDatePicker = false
    @State private var showQuiz = false
    
    // Photo picker
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Image Section
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                if let image = profileImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 90, height: 90)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.adaptiveText)
                                        .frame(width: 90, height: 90)
                                        .overlay(
                                            Text(String(name.prefix(1)))
                                                .font(.system(size: 36, weight: .bold))
                                                .foregroundColor(Color.adaptiveBackground)
                                        )
                                }
                                
                                Circle()
                                    .fill(Color.appAccent)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 2, y: 2)
                            }
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    profileImage = uiImage
                                }
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section(header: Text("ข้อมูลส่วนตัว")) {
                    TextField("ชื่อ", text: $name)
                        .font(.system(size: 16, weight: .medium))
                    
                    // @ Handle
                    HStack {
                        Text("@")
                            .foregroundColor(.adaptiveSecondaryText)
                            .font(.system(size: 16, weight: .medium))
                        TextField("username", text: $username)
                            .font(.system(size: 16, weight: .medium))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                    }
                    
                    // Gender Selection
                    Picker("เพศ", selection: $gender) {
                        Text("-- เลือกเพศ --").tag("")
                        Text("ชาย").tag("male")
                        Text("หญิง").tag("female")
                        Text("อื่นๆ").tag("other")
                    }
                    .font(.system(size: 16, weight: .medium))
                    
                    // Age Input
                    TextField("อายุ", text: $age)
                        .keyboardType(.numberPad)
                        .font(.system(size: 16, weight: .medium))
                    
                    // Birth Date Picker
                    HStack {
                        Text("วันเกิด")
                        Spacer()
                        DatePicker(
                            "",
                            selection: $birthDate,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }
                    
                    // Bio Input
                    Section(header: Text("ประวัติส่วนตัว")) {
                        TextEditor(text: $bio)
                            .frame(height: 100)
                            .font(.system(size: 16, weight: .regular))
                        Text("\(bio.count) / 500")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.adaptiveSecondaryText)
                    }
                }
                
                Section(header: Text("Lifestyle & Travel Style")) {
                    Button(action: { showQuiz = true }) {
                        HStack {
                            Image(systemName: "pencil.and.outline")
                            Text("ทำแบบสำรวจไลฟ์สไตล์ใหม่")
                                .fontWeight(.bold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.adaptiveSecondaryText)
                        }
                    }
                    .foregroundColor(.adaptiveText)
                    
                    if let style = authViewModel.currentUser?.travelStyle {
                        let tags = [style.budget, style.pace, style.social, style.accommodation].compactMap { $0 }
                        if !tags.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color.adaptiveBackground)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.adaptiveText)
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                Section(header: Text("สิ่งที่สนใจ (เลือกได้หลายข้อ)")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                        ForEach(INTEREST_CATEGORIES) { cat in
                            InterestTag(

                                label: cat.label,
                                emoji: cat.emoji,
                                isSelected: selectedInterests.contains(cat.label)
                            ) {
                                if selectedInterests.contains(cat.label) {
                                    selectedInterests.remove(cat.label)
                                } else {
                                    selectedInterests.insert(cat.label)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                if authViewModel.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("แก้ไขโปรไฟล์")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ยกเลิก") { dismiss() }
                        .foregroundColor(.appAccent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("บันทึก") {
                        Task {
                            // Convert profile image to base64 for backend
                            var profileImageBase64: String? = nil
                            if let image = profileImage,
                               let jpegData = image.jpegData(compressionQuality: 0.5) {
                                // Save locally as cache
                                UserDefaults.standard.set(jpegData, forKey: "local_profile_image")
                                // Convert to base64 data URI for backend
                                profileImageBase64 = "data:image/jpeg;base64," + jpegData.base64EncodedString()
                            }
                            
                            // Save @ handle locally
                            UserDefaults.standard.set(username, forKey: "user_handle")
                            
                            let ageInt = Int(age) ?? nil
                            await authViewModel.updateProfile(
                                name: name,
                                interests: Array(selectedInterests),
                                gender: gender.isEmpty ? nil : gender,
                                age: ageInt,
                                bio: bio.isEmpty ? nil : bio,
                                birthDate: birthDate,
                                travelStyle: authViewModel.currentUser?.travelStyle,
                                profileImage: profileImageBase64
                            )
                            dismiss()
                        }
                    }
                    .foregroundColor(.appAccent)
                    .disabled(authViewModel.isLoading || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let user = authViewModel.currentUser {
                    name = user.name
                    selectedInterests = Set(user.interests ?? [])
                    gender = user.gender ?? ""
                    age = user.age.map { String($0) } ?? ""
                    bio = user.bio ?? ""
                    if let birthDate = user.birthDate {
                        self.birthDate = birthDate
                    }
                }
                // Load saved handle
                username = UserDefaults.standard.string(forKey: "user_handle") ?? ""
                // Load saved image (local cache first, then backend)
                if let data = UserDefaults.standard.data(forKey: "local_profile_image"),
                   let image = UIImage(data: data) {
                    profileImage = image
                } else if let profileImageStr = authViewModel.currentUser?.profileImage,
                          !profileImageStr.isEmpty,
                          let image = ProfileView.decodeBase64Image(profileImageStr) {
                    profileImage = image
                }
            }
            .sheet(isPresented: $showQuiz) {
                TravelStyleQuizView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

struct InterestTag: View {
    let label: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(emoji)
                Text(label)
                    .font(.system(size: 12, weight: .bold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.adaptiveText : Color.adaptiveCardTint)
            .foregroundColor(isSelected ? Color.adaptiveBackground : .adaptiveText)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.adaptiveText : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


#Preview {
    EditProfileView()
        .environmentObject(AuthViewModel())
}

import SwiftUI

/// A read-only profile view for viewing other users' profiles
struct UserProfileView: View {
    let user: User
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Profile Header
                        VStack(spacing: 16) {
                            // Avatar
                            if let profileImage = user.profileImage,
                               let url = URL(string: profileImage) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    avatarPlaceholder
                                }
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                            } else {
                                avatarPlaceholder
                            }
                            
                            VStack(spacing: 4) {
                                Text(user.name)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.adaptiveText)
                                
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
                            
                            // Travel Style
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
                            
                            // Interests
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
                        
                        Spacer()
                    }
                    .padding(24)
                }
            }
            .navigationTitle(user.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.adaptiveText)
                    }
                }
            }
        }
    }
    
    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color.adaptiveText)
            .frame(width: 100, height: 100)
            .overlay(
                Text(String(user.name.prefix(1)))
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(Color.adaptiveBackground)
            )
    }
}

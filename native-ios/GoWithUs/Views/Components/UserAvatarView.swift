import SwiftUI

struct UserAvatarView: View {
    let user: User?
    let size: CGFloat
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // To explicitly handle local changes without reloading the whole object, 
    // we use the live current user if IDs match.
    private var displayUser: User? {
        if let u = user, let currentUser = authViewModel.currentUser, u.id == currentUser.id {
            return currentUser
        }
        return user
    }
    
    var body: some View {
        ZStack {
            // Default Colorful Gradient Background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            if let displayUser = displayUser {
                if let profileImage = displayUser.profileImage, !profileImage.isEmpty {
                    CustomAsyncImage(url: profileImage, contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    let initial = displayUser.name.isEmpty ? "" : String(displayUser.name.prefix(1))
                    Text(initial)
                        .font(.system(size: size * 0.4, weight: .bold))
                        .foregroundColor(.white)
                }
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(width: size, height: size)
    }
}

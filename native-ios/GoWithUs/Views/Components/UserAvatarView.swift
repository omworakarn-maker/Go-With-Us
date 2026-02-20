import SwiftUI

struct UserAvatarView: View {
    let user: User?
    let size: CGFloat
    var imageLoadDelay: Double = 0 // Set to ~0.35 in side menu to wait for slide animation
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    private var displayUser: User? {
        if let u = user, let currentUser = authViewModel.currentUser, u.id == currentUser.id {
            return currentUser
        }
        return user
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black)
                .frame(width: size, height: size)
            
            if let displayUser = displayUser {
                if let profileImage = displayUser.profileImage, !profileImage.isEmpty {
                    CustomAsyncImage(url: profileImage, contentMode: .fill, loadDelay: imageLoadDelay)
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


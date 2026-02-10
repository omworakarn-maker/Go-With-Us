import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            if isShowing {
                // Dimmed Background
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isShowing = false
                        }
                    }
                
                // Menu Content
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        VStack(alignment: .leading, spacing: 12) {
                            if let user = authViewModel.currentUser {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Text(String(user.name.prefix(1)))
                                            .foregroundColor(.white)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.name)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                    Text(user.email)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.gray)
                                Text("Guest")
                                    .font(.headline)
                            }
                        }
                        .padding(.top, 60)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        
                        Divider()
                            .padding(.bottom, 20)
                        
                        // Menu Items
                        VStack(alignment: .leading, spacing: 24) {
                            NavigationLink(destination: HomeView()) { // Navigate to Home
                                MenuRow(icon: "house", text: "หน้าแรก")
                            }
                            
                            NavigationLink(destination: MatchTripView()) {
                                MenuRow(icon: "sparkles", text: "แมตช์ทริป")
                            }
                            
                            NavigationLink(destination: MyTripsView()) {
                                MenuRow(icon: "map", text: "ทริปของฉัน")
                            }
                            
                            NavigationLink(destination: AIChatView()) {
                                MenuRow(icon: "brain.head.profile", text: "คุยกับ AI")
                            }
                            
                            NavigationLink(destination: ProfileView()) {
                                MenuRow(icon: "person", text: "โปรไฟล์")
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        // Bottom Actions
                        if authViewModel.currentUser != nil {
                            Button(action: {
                                authViewModel.logout()
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "arrow.right.square")
                                        .font(.system(size: 20))
                                    Text("ออกจากระบบ")
                                        .font(.headline)
                                }
                                .foregroundColor(.red)
                                .padding()
                            }
                        }
                    }
                    .frame(width: 270)
                    .background(Color.white)
                    .offset(x: isShowing ? 0 : -270)
                    
                    Spacer()
                }
            }
        }
        .animation(.easeInOut, value: isShowing)
    }
}

struct MenuRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.black)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
            
            Spacer()
        }
    }
}

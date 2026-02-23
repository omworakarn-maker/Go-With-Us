import SwiftUI

struct FindBuddyView: View {
    @StateObject private var viewModel = FindBuddyViewModel()
    @State private var showMutualMatches = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView(SettingsManager.shared.localizedString(for: "loading_buddies"))
                        .tint(.appAccent)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.gray)
                        Button(SettingsManager.shared.localizedString(for: "try_again")) {
                            Task { await viewModel.fetchMatches() }
                        }
                        .padding()
                        .background(Color.adaptiveText.opacity(0.1))
                        .cornerRadius(12)
                    }
                } else if viewModel.matches.isEmpty || viewModel.currentCardIndex >= viewModel.matches.count {
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.slash.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.3))
                        Text(SettingsManager.shared.currentLanguage == .thai ? "ยังไม่มีเพื่อนใหม่ใกล้ตัวคุณ" : "No new buddies near you")
                            .font(.headline)
                        Text(SettingsManager.shared.currentLanguage == .thai ? "ลองปรับความสนใจในโปรไฟล์ของคุณ\nเพื่อให้เจอเพื่อนที่ตรงใจมากขึ้น" : "Try updating your interests\nfor better recommendations")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { Task { await viewModel.fetchMatches() } }) {
                            Text(SettingsManager.shared.localizedString(for: "refresh"))
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .background(Color.black)
                                .cornerRadius(25)
                        }
                    }
                } else {
                    // Swipe Cards
                    ZStack {
                        ForEach((viewModel.currentCardIndex..<min(viewModel.currentCardIndex + 3, viewModel.matches.count)).reversed(), id: \.self) { index in
                            BuddySwipeCard(user: viewModel.matches[index]) { status in
                                withAnimation(.spring()) {
                                    let targetId = viewModel.matches[index].id
                                    viewModel.currentCardIndex += 1
                                    Task {
                                        await viewModel.swipeUser(targetId: targetId, status: status)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 40)
                        }
                    }
                }
                
                // Match Celebration Overlay
                if viewModel.showMatchCelebration {
                    MatchCelebrationView(name: viewModel.lastMatchedUserName) {
                        viewModel.showMatchCelebration = false
                        showMutualMatches = true
                    }
                    .transition(.opacity)
                    .zIndex(10)
                }
            }
            .navigationTitle(SettingsManager.shared.localizedString(for: "find_friend"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showMutualMatches = true }) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundColor(.adaptiveText)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { Task { await viewModel.fetchMatches() } }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.adaptiveText)
                    }
                }
            }
            .sheet(isPresented: $showMutualMatches) {
                MutualMatchesView()
            }
            .onAppear {
                if viewModel.matches.isEmpty {
                    Task { await viewModel.fetchMatches() }
                }
            }
        }
    }
}

struct BuddySwipeCard: View {
    let user: MatchUser
    let onSwipe: (String) -> Void
    
    @State private var offset = CGSize.zero
    @State private var color: Color = .black.opacity(0.8)
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image/Color
            Group {
                if let imageStr = user.profileImage, !imageStr.isEmpty, let uiImage = ProfileView.decodeBase64Image(imageStr) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.adaptiveCardBackground)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.gray.opacity(0.3))
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(24)
            .clipped()
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            // Subtle Gradient Overlay for text readability
            LinearGradient(colors: [.black.opacity(0.6), .clear, .clear], startPoint: .bottom, endPoint: .top)
                .cornerRadius(24)
            
            // Info Overlay
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(user.name)
                        .font(.system(size: 32, weight: .bold))
                    
                    if user.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.appAccent)
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    if let score = user.matchScore {
                        Text("\(score)% Match")
                            .font(.system(size: 14, weight: .black))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(score >= 80 ? Color.green : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                
                if let interests = user.interests, !interests.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(interests, id: \.self) { interest in
                            Text(interest)
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.adaptiveText.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                
                // Potential bio here if available in MatchUser
            }
            .padding(24)
            .foregroundColor(.white) // Always white on image background
            
            // Labels for swipe status
            HStack {
                Text("LIKE")
                    .font(.system(size: 40, weight: .black))
                    .foregroundColor(.green)
                    .padding()
                    .border(Color.green, width: 4)
                    .cornerRadius(8)
                    .opacity(Double(offset.width / 150))
                    .rotationEffect(.degrees(-20))
                
                Spacer()
                
                Text("NOPE")
                    .font(.system(size: 40, weight: .black))
                    .foregroundColor(.red)
                    .padding()
                    .border(Color.red, width: 4)
                    .cornerRadius(8)
                    .opacity(Double(-offset.width / 150))
                    .rotationEffect(.degrees(20))
            }
            .padding(40)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .offset(x: offset.width, y: offset.height * 0.4)
        .rotationEffect(.degrees(Double(offset.width / 20)))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                }
                .onEnded { gesture in
                    if gesture.translation.width > 150 {
                        onSwipe("like")
                    } else if gesture.translation.width < -150 {
                        onSwipe("dislike")
                    } else {
                        withAnimation(.spring()) {
                            offset = .zero
                        }
                    }
                }
        )
    }
}

struct MatchCelebrationView: View {
    let name: String
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("It's a Match! 🎉")
                    .font(.system(size: 40, weight: .black))
                    .foregroundColor(.white)
                
                Text(SettingsManager.shared.currentLanguage == .thai ? "คุณและ \(name) อยากไปเที่ยวด้วยกัน!" : "You and \(name) want to travel together!")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: onDismiss) {
                    Text(SettingsManager.shared.currentLanguage == .thai ? "เริ่มคุยกันเลย!" : "Start Chatting!")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(30)
                }
                
                Button(action: { 
                    // Just dismiss and keep matching
                    onDismiss()
                }) {
                    Text(SettingsManager.shared.currentLanguage == .thai ? "ปัดหาเพื่อนต่อ" : "Keep Swiping")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 10)
                }
            }
        }
    }
}

struct MutualMatchesView: View {
    @State private var matches: [MatchUser] = []
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                } else if matches.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.3))
                        Text(SettingsManager.shared.currentLanguage == .thai ? "ยังไม่มีคนแมตช์ด้วย" : "No matches yet")
                            .font(.headline)
                        Text(SettingsManager.shared.currentLanguage == .thai ? "ปัดขวาให้คนที่คุณสนใจ\nเพื่อเริ่มบทสนทนา!" : "Swipe right on people you like\nto start a conversation!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    List(matches) { user in
                        NavigationLink(destination: ChatDetailView(chatTitle: user.name, partnerId: user.id)) {
                            HStack(spacing: 16) {
                                UserAvatarView(user: user.toUser(), size: 50)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.name)
                                        .font(.headline)
                                    Text(SettingsManager.shared.currentLanguage == .thai ? "แตะเพื่อเริ่มคุย" : "Tap to chat")
                                        .font(.caption)
                                        .foregroundColor(.appAccent)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle(SettingsManager.shared.currentLanguage == .thai ? "เพื่อนใหม่" : "My Matches")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(SettingsManager.shared.localizedString(for: "close")) { dismiss() }
                }
            }
            .task {
                do {
                    let response = try await MatchService.shared.getMutualMatches()
                    self.matches = response.matches
                    self.isLoading = false
                } catch {
                    print("Failed to fetch mutual matches: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
}

extension MatchUser {
    func toUser() -> User {
        return User(
            id: id,
            name: name,
            email: email,
            role: UserRole(rawValue: role) ?? .user,
            profileImage: profileImage,
            interests: interests,
            isVerified: isVerified
        )
    }
}

#Preview {
    FindBuddyView()
}

import SwiftUI

struct FindBuddyView: View {
    @StateObject private var viewModel = FindBuddyViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("กำลังค้นหาเพื่อนที่แมตช์กัน...")
                } else if let error = viewModel.errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.gray)
                        Button("ลองใหม่") {
                            Task { await viewModel.fetchMatches() }
                        }
                        .padding()
                    }
                } else if viewModel.matches.isEmpty {
                    VStack {
                        Image(systemName: "person.slash")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("ยังไม่พบเพื่อนที่แมตช์กันในขณะนี้")
                            .foregroundColor(.gray)
                            .padding(.top)
                    }
                } else {
                    List(viewModel.matches) { user in
                        HStack(spacing: 16) {
                            // Avatar Placeholder
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(String(user.name.prefix(1)).uppercased())
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.headline)
                                    .foregroundColor(.black)
                                
                                if let interests = user.interests, !interests.isEmpty {
                                    Text(interests.prefix(3).joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            if let score = user.matchScore {
                                VStack {
                                    Text("\(score)%")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(scoreColor(score))
                                    Text("Match")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                .padding(8)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await viewModel.fetchMatches()
                    }
                }
            }
            .navigationTitle("หาเพื่อน")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await viewModel.fetchMatches()
                }
            }
        }
    }
    
    func scoreColor(_ score: Int) -> Color {
        if score >= 80 { return .green }
        if score >= 50 { return .orange }
        return .red
    }
}

#Preview {
    FindBuddyView()
}

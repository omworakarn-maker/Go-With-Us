import SwiftUI

struct MatchTripView: View {
    @StateObject private var viewModel = MatchTripViewModel()
    @Binding var showSideMenu: Bool
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            NavigationStack {
                VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        Button(action: {
                            withAnimation {
                                showSideMenu.toggle()
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.adaptiveText)
                        }
                        
                        Spacer()
                        
                        Text("แมตช์ทริป")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.appPrimary)
                        
                        Spacer()
                        
                        Button(action: {
                            Task { await viewModel.fetchMatches() }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.adaptiveText)
                                .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                                .animation(viewModel.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                        }
                    }
                    .padding()
                    
                    Group {
                        if viewModel.isLoading {
                            Spacer()
                            ProgressView()
                                .tint(.appPrimary)
                                .scaleEffect(1.5)
                            Spacer()
                        } else if let error = viewModel.errorMessage {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.orange)
                                Text(error)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                Button("ลองใหม่") {
                                    Task { await viewModel.fetchMatches() }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.appPrimary)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                            }
                            Spacer()
                        } else if viewModel.matches.isEmpty {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "sparkles.rectangle.stack.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.appPrimary.opacity(0.4))
                                Text("ไม่มีทริปแมตช์ใหม่ๆ ตอนนี้")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.adaptiveText)
                                Text("กลับมาเช็คดูใหม่ หรือเพิ่มความสนใจในโปรไฟล์")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                
                                Button("รีเฟรช") {
                                    Task { await viewModel.fetchMatches() }
                                }
                                .padding(.top, 10)
                                .foregroundColor(.appPrimary)
                            }
                            Spacer()
                        } else {
                            // Tinder Swipe Area
                            ZStack {
                                let matchCount = viewModel.matches.count
                                ForEach(0..<matchCount, id: \.self) { i in
                                    let index = matchCount - 1 - i
                                    let distance = CGFloat(i)
                                    let scale = 1.0 - (distance * 0.05)
                                    let yOffset = distance * 10
                                    
                                    TinderSwipeCardView(
                                        trip: viewModel.matches[index],
                                        onRemove: {
                                            withAnimation(.spring()) {
                                                let tripIdToRemove = viewModel.matches[index].id
                                                viewModel.matches.removeAll { $0.id == tripIdToRemove }
                                            }
                                        }
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 40)
                                    // Scale down back cards slightly for depth
                                    .scaleEffect(scale)
                                    .offset(y: yOffset)
                                    .allowsHitTesting(index == matchCount - 1)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .padding(.bottom, 80) // Added for TabBar
                }
            }
        }
        .task {
            await viewModel.fetchMatches()
        }
    }
}

// MARK: - Tinder Swipe Card
struct TinderSwipeCardView: View {
    let trip: Trip
    let onRemove: () -> Void
    
    @State private var offset: CGSize = .zero
    @State private var color: Color = .clear
    @State private var contentNavigation = false
    
    var body: some View {

        ZStack {
            TripCardView(trip: trip) // Reusing existing UI properly inside a gesture frame
                .background(Color.adaptiveCardBackground)
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            // Interaction overlay (Match Score, Tap, Swipe effects)
            ZStack(alignment: .topTrailing) {
                Color.clear
                
                if let score = trip.matchScore {
                    Text("\(score)% Match")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black)
                        .cornerRadius(20)
                        .padding(16)
                }
            }
            
            // Swipe feedback colors
            if offset.width > 0 {
                // Liked/Passed Right
                Color.appPrimary.opacity(Double(offset.width / 400))
                    .cornerRadius(24)
            } else if offset.width < 0 {
                // Rejected/Passed Left
                Color.red.opacity(Double(abs(offset.width) / 400))
                    .cornerRadius(24)
            }
        }
        .offset(x: offset.width, y: offset.height * 0.4)
        .rotationEffect(.degrees(Double(offset.width / 40)))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                }
                .onEnded { _ in
                    if abs(offset.width) > 100 {
                        // Swipe recognized
                        onRemove()
                    } else {
                        // Reset back to center if swipe isn't far enough
                        withAnimation(.spring()) {
                            offset = .zero
                        }
                    }
                }
        )
        .onTapGesture {
            contentNavigation = true
        }
        .navigationDestination(isPresented: $contentNavigation) {
            TripDetailView(tripId: trip.id)
        }
    }
}

class MatchTripViewModel: ObservableObject {
    @Published var matches: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchMatches() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            // Clear out matches momentarily for a fresh bounce effect if desired, or keep them.
        }
        
        do {
            let response: MatchTripResponse = try await APIService.shared.request(endpoint: "/match/trips", method: .get)
            await MainActor.run {
                self.matches = response.matches
                self.isLoading = false
            }
        } catch let error as URLError where error.code == .cancelled {
            // Ignore cancellation
        } catch {
            await MainActor.run {
                self.errorMessage = "เกิดข้อผิดพลาดในการโหลดข้อมูล"
                self.isLoading = false
                print("Error fetching match trips: \(error)")
            }
        }
    }
}

struct MatchTripResponse: Decodable {
    let matches: [Trip]
}

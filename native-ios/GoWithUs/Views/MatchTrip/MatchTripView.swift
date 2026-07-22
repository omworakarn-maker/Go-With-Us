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
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.adaptiveText)
                        
                        Spacer()
                        
                        // State for navigation
                        NavigationLink(value: "placeholder") { EmptyView() } // Hack for destiny
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
                            VStack {
                                Spacer()
                                ProgressView()
                                    .tint(.adaptiveText)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.identity)
                            .animation(nil, value: UUID())
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
                                .background(Color.adaptiveText)
                                .foregroundColor(Color.adaptiveBackground)
                                .cornerRadius(20)
                            }
                            Spacer()
                        } else if viewModel.matches.isEmpty {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "sparkles.rectangle.stack.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.adaptiveText.opacity(0.25))
                                Text("ไม่มีทริปแมตช์ใหม่ๆ ตอนนี้")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.adaptiveText)
                                Text("กลับมาเช็คดูใหม่ หรือเพิ่มสไตล์การเที่ยวในโปรไฟล์")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                
                                Button("รีเฟรช") {
                                    Task { await viewModel.fetchMatches() }
                                }
                                .padding(.top, 10)
                                .foregroundColor(.adaptiveText)
                            }
                            Spacer()
                        } else {
                            // Tinder Swipe Area
                            ZStack {
                                let matchCount = viewModel.matches.count
                                // Only show top 3-4 cards for performance
                                let displayCount = min(matchCount, 4)
                                
                                ForEach(0..<displayCount, id: \.self) { i in
                                    // Index 0 is the TOP card, Index (count-1) is the BOTTOM card
                                    // But ZStack renders last-item-on-top.
                                    // So we render from BOTTOM (back) to TOP (front).
                                    let index = displayCount - 1 - i
                                    let trip = viewModel.matches[index]
                                    
                                    TinderSwipeCardView(
                                        trip: trip,
                                        onRemove: {
                                            withAnimation(.spring()) {
                                                viewModel.matches.removeAll { $0.id == trip.id }
                                            }
                                        },
                                        onRightSwipe: {
                                            viewModel.selectedTripForJoin = trip
                                            withAnimation(.spring()) {
                                                viewModel.matches.removeAll { $0.id == trip.id }
                                            }
                                        }
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 40)
                                    // Scale and dynamic depth
                                    .scaleEffect(1.0 - (CGFloat(index) * 0.05))
                                    .offset(y: CGFloat(index) * 12)
                                    .opacity(index <= 3 ? 1.0 : 0)
                                    .zIndex(Double(displayCount - index))
                                    .allowsHitTesting(index == 0) // Only the top card interacts
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .padding(.bottom, 80) // Added for TabBar
                }
                .navigationDestination(item: $viewModel.selectedTripForJoin) { trip in
                    TripDetailView(tripId: trip.id, autoShowJoin: true)
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
    var onRightSwipe: () -> Void = {}
    
    @State private var offset: CGSize = .zero
    @State private var color: Color = .clear
    @State private var contentNavigation = false
    
    var body: some View {

        ZStack {
            TripCardView(trip: trip) // Reusing existing UI properly inside a gesture frame
                .background(Color.adaptiveCardBackground)
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
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
                .onEnded { gesture in
                    if gesture.translation.width > 120 {
                        // Swipe Right - Interested/Join
                        onRightSwipe()
                    } else if gesture.translation.width < -120 {
                        // Swipe Left - Reject
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
    @Published var selectedTripForJoin: Trip?
    private static var lastLoaded: Date? = nil
    private static var cachedMatches: [Trip] = []
    
    static func invalidateCache() {
        lastLoaded = nil
        cachedMatches = []
    }
    
    init() {
        self.matches = Self.cachedMatches
    }
    
    func fetchMatches(force: Bool = false) async {
        if !force, let lastLoaded = Self.lastLoaded, Date().timeIntervalSince(lastLoaded) < 180, !Self.cachedMatches.isEmpty {
            self.matches = Self.cachedMatches
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            // Clear out matches momentarily for a fresh bounce effect if desired, or keep them.
        }
        
        do {
            let response: MatchTripResponse = try await APIService.shared.request(endpoint: "/match/trips", method: .get)
            await MainActor.run {
                self.matches = response.matches
                Self.cachedMatches = response.matches
                Self.lastLoaded = Date()
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

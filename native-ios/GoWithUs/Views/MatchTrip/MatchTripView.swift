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
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.adaptiveText)
                        
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
                                .tint(.adaptiveText)
                            Spacer()
                        } else if let error = viewModel.errorMessage {
                            Spacer()
                            VStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.orange)
                                Text(error)
                                    .foregroundColor(.gray)
                                    .padding()
                                Button("ลองใหม่") {
                                    Task { await viewModel.fetchMatches() }
                                }
                                .padding()
                                .background(Color.adaptiveText)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            Spacer()
                        } else if viewModel.matches.isEmpty {
                            Spacer()
                            VStack {
                                Image(systemName: "map")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.3))
                                Text("ยังไม่พบทริปที่แมตช์กับคุณ")
                                    .font(.headline)
                                    .padding(.top)
                                Text("ลองเพิ่มความสนใจในโปรไฟล์ดูสิ")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 20) {
                                    ForEach(viewModel.matches) { trip in
                                        NavigationLink(destination: TripDetailView(tripId: trip.id)) {
                                            TripCardView(trip: trip) // Reusing existing card
                                                .overlay(
                                                    ZStack {
                                                        if let score = trip.matchScore {
                                                             VStack {
                                                                 HStack {
                                                                     Spacer()
                                                                     Text("\(score)% Match")
                                                                         .font(.system(size: 10, weight: .bold))
                                                                         .foregroundColor(.white)
                                                                         .padding(.horizontal, 8)
                                                                         .padding(.vertical, 4)
                                                                         .background(Color.black)
                                                                         .cornerRadius(12)
                                                                         .padding(8)
                                                                 }
                                                                 Spacer()
                                                             }
                                                        }
                                                    }
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding()
                            }
                            .refreshable {
                                await viewModel.fetchMatches()
                            }
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

class MatchTripViewModel: ObservableObject {
    @Published var matches: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchMatches() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let response: MatchTripResponse = try await APIService.shared.request(endpoint: "/match/trips", method: .get)
            await MainActor.run {
                self.matches = response.matches
                self.isLoading = false
            }
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

import SwiftUI

struct MyTripsView: View {
    @StateObject private var viewModel = MyTripsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showSideMenu: Bool
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            NavigationStack {
                VStack(spacing: 0) {
                    // Header
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
                        
                        Text("ทริปของฉัน")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.adaptiveText)
                        
                        Spacer()
                        
                        // Balance space
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.clear)
                    }
                    .padding()
                    .background(Color.adaptiveBackground)
                    
                    Group {
                        if viewModel.isLoading {
                            Spacer()
                            ProgressView()
                            Spacer()
                        } else if viewModel.myTrips.isEmpty {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "airplane.departure")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.3))
                                Text("คุณยังไม่มีทริปที่สร้างไว้")
                                    .font(.headline)
                                
                                NavigationLink(destination: CreateTripView()) {
                                     Text("สร้างทริปเลย")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.black)
                                        .cornerRadius(12)
                                }
                            }
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 20) {
                                    ForEach(viewModel.myTrips) { trip in
                                        NavigationLink(destination: TripDetailView(tripId: trip.id)) {
                                            TripCardView(trip: trip)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding()
                            }
                            .refreshable {
                                if let userId = authViewModel.currentUser?.id {
                                    await viewModel.fetchMyTrips(userId: userId)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 80) // Added for TabBar
                }
            }
        }
        .task {
            if let userId = authViewModel.currentUser?.id {
                await viewModel.fetchMyTrips(userId: userId)
            }
        }
    }
}

class MyTripsViewModel: ObservableObject {
    @Published var myTrips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchMyTrips(userId: String) async {
        await MainActor.run { isLoading = true }
        
        do {
            let response: TripListResponse = try await APIService.shared.request(endpoint: "/trips", method: .get)
            let filtered = response.trips.filter { $0.creatorId == userId }
            
            await MainActor.run {
                self.myTrips = filtered
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "โหลดข้อมูลล้มเหลว"
                self.isLoading = false
                print("Error loading my trips: \(error)")
            }
        }
    }
}

struct TripListResponse: Decodable {
    let trips: [Trip]
}

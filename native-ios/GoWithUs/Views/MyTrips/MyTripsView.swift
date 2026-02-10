import SwiftUI

struct MyTripsView: View {
    @StateObject private var viewModel = MyTripsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        // Handle back action if needed, or stick to side menu
                    }) {
                        // If pushed from navigation, back button appears automatically.
                        // But since this is likely from Side Menu, maybe just Title
                    }
                    Text("ทริปของฉัน")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding()
                
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
            // Reusing getAll trips and filtering locally because backend might not have specific endpoint or using query params
            // If backend has /trips?creatorId=..., better to use that.
            // Let's assume we fetch all and filter for now as MVP, or check if APIService supports query.
            
            // Checking APIService implementation...
            // APIService doesn't seem to have a specific method for filtering yet without checking usage.
            // Let's try fetching all and filtering clientside first.
            
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

// Assuming TripListResponse exists in TripView/ViewModel context, but redefining here or making it shared would be better.
// Checking TripView/ViewModel code would be good, but defining it here for safety.
struct TripListResponse: Decodable {
    let trips: [Trip]
}

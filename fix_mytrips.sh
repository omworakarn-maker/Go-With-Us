cat << 'INNER_EOF' > /tmp/MyTripsViewModel.swift
class MyTripsViewModel: ObservableObject {
    @Published var createdTrips: [Trip] = []
    @Published var joinedTrips: [Trip] = []
    @Published var interestedTrips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchMyTrips(userId: String) async {
        await MainActor.run { isLoading = true }
        
        do {
            async let createdFetch = TripService.shared.getAllTrips(creatorId: userId, limit: 100)
            async let participatedFetch = TripService.shared.getAllTrips(participantId: userId, limit: 100)
            
            let createdResult = try await createdFetch
            let participatedResult = try await participatedFetch
            
            let created = createdResult.trips
            let participated = participatedResult.trips
            
            let joined = participated.filter { $0.participants?.contains(where: { $0.userId == userId && $0.status == "going" }) == true }
            let interested = participated.filter { $0.participants?.contains(where: { $0.userId == userId && $0.status == "interested" }) == true }
            
            await MainActor.run {
                self.createdTrips = created
                self.joinedTrips = joined
                self.interestedTrips = interested
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = SettingsManager.shared.currentLanguage == .thai ? "โหลดข้อมูลล้มเหลว" : "Failed to load data"
                self.isLoading = false
                print("Error loading my trips: \(error)")
            }
        }
    }
}
INNER_EOF

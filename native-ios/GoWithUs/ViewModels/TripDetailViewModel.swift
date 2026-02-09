import Foundation
import Combine

// MARK: - Trip Detail ViewModel
@MainActor
class TripDetailViewModel: ObservableObject {
    @Published var trip: Trip?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showJoinSheet = false
    @Published var interests: [String] = []
    @Published var isJoining = false
    @Published var isLeaving = false
    @Published var isDeleting = false
    
    let tripId: String
    
    var currentUserId: String? {
        return AuthService.shared.getCurrentUserId()
    }
    
    init(tripId: String) {
        self.tripId = tripId
    }
    
    // MARK: - Computed Properties
    var isCreator: Bool {
        guard let trip = trip, let userId = currentUserId else { return false }
        return trip.creatorId == userId
    }
    
    var isAdmin: Bool {
        // Check if current user is admin
        return false // TODO: Implement admin check
    }
    
    var hasJoined: Bool {
        guard let trip = trip, let userId = currentUserId else { return false }
        return trip.participants?.contains(where: { $0.userId == userId }) ?? false
    }
    
    // MARK: - Load Trip
    func loadTrip() async {
        isLoading = true
        errorMessage = nil
        
        do {
            trip = try await TripService.shared.getTrip(id: tripId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Join Trip
    func joinTrip(interests: [String]) async -> Bool {
        isJoining = true
        errorMessage = nil
        
        do {
            // Get current user's name
            let user = try await AuthService.shared.getCurrentUser()
            
            trip = try await TripService.shared.joinTrip(id: tripId, name: user.name, interests: interests)
            showJoinSheet = false
            isJoining = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isJoining = false
            return false
        }
    }
    
    // MARK: - Leave Trip
    func leaveTrip() async {
        isLeaving = true
        errorMessage = nil
        
        do {
            try await TripService.shared.leaveTrip(id: tripId)
            await loadTrip() // Reload to get updated participant list
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLeaving = false
    }
    
    // MARK: - Delete Trip
    func deleteTrip() async -> Bool {
        isDeleting = true
        errorMessage = nil
        
        do {
            try await TripService.shared.deleteTrip(id: tripId)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

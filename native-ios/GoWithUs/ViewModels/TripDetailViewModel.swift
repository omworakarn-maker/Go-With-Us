import Foundation
import Combine

// MARK: - Trip Detail ViewModel
@MainActor
class TripDetailViewModel: ObservableObject {
    @Published var trip: Trip?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showJoinSheet = false
    @Published var showLeaveSheet = false
    @Published var interests: [String] = []
    @Published var isJoining = false
    @Published var isLeaving = false
    @Published var isDeleting = false
    
    @Published var currentUser: User?
    
    let tripId: String
    
    var currentUserId: String? {
        return AuthService.shared.getCurrentUserId()
    }
    
    init(tripId: String) {
        self.tripId = tripId
        Task {
            await fetchCurrentUser()
        }
    }
    
    // MARK: - Computed Properties
    var isCreator: Bool {
        guard let trip = trip, let userId = currentUserId else { return false }
        return trip.creatorId == userId
    }
    
    var isAdmin: Bool {
        return currentUser?.role == .admin
    }
    
    var hasJoined: Bool {
        guard let trip = trip, let userId = currentUserId else { return false }
        return trip.participants?.contains(where: { $0.userId == userId }) ?? false
    }
    
    // MARK: - Load Utils
    func fetchCurrentUser() async {
        do {
             currentUser = try await AuthService.shared.getCurrentUser()
        } catch {
            print("Failed to fetch current user: \(error)")
        }
    }
    
    // MARK: - Load Trip
    func loadTrip() async {
        isLoading = true
        errorMessage = nil
        
        do {
            trip = try await TripService.shared.getTrip(id: tripId)
            await fetchCurrentUser() // Refresh user data as well
        } catch let error as URLError where error.code == .cancelled {
            return // Ignore cancellation
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Join Trip
    func joinTrip(interests: [String], status: String = "going") async -> Bool {
        isJoining = true
        errorMessage = nil
        
        do {
            // Get current user's name
            let user = try await AuthService.shared.getCurrentUser()
            
            trip = try await TripService.shared.joinTrip(id: tripId, name: user.name, interests: interests, status: status)
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
    func leaveTrip() async -> Bool {
        isLeaving = true
        errorMessage = nil
        
        do {
            try await TripService.shared.leaveTrip(id: tripId)
            await loadTrip() // Reload to get updated participant list
            showLeaveSheet = false
            isLeaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLeaving = false
            return false
        }
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
    
    // MARK: - Remove Participant
    func removeParticipant(userId: String) async {
        guard let tripId = trip?.id else { return }
        errorMessage = nil
        
        do {
            try await TripService.shared.removeParticipant(tripId: tripId, userId: userId)
            await loadTrip() // Reload participants
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

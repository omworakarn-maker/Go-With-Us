import Foundation

// MARK: - Participant Model
struct Participant: Codable, Identifiable {
    let id: String
    let tripId: String?
    let userId: String
    let user: User?
    let name: String
    let interests: [String]?
    let joinedAt: Date
    
    init(
        id: String,
        tripId: String? = nil,
        userId: String,
        user: User? = nil,
        name: String,
        interests: [String]? = nil,
        joinedAt: Date = Date()
    ) {
        self.id = id
        self.tripId = tripId
        self.userId = userId
        self.user = user
        self.name = name
        self.interests = interests
        self.joinedAt = joinedAt
    }
}

import Foundation

struct MatchUser: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let role: String
    let interests: [String]?
    let matchScore: Int?
    let isVerified: Bool?
    let verificationStatus: String?
}

struct MatchResponse: Codable {
    let matches: [MatchUser]
}

class MatchService {
    static let shared = MatchService()
    
    private init() {}
    
    func getBuddyMatches() async throws -> MatchResponse {
        return try await APIService.shared.request(
            endpoint: "/match/buddy",
            method: .get
        )
    }
}

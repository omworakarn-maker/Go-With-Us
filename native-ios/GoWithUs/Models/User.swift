import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let role: UserRole
    let travelStyle: TravelStyle?
    let interests: [String]?
    let createdAt: Date?
    let updatedAt: Date?
    
    init(
        id: String,
        name: String,
        email: String,
        role: UserRole = .user,
        travelStyle: TravelStyle? = nil,
        interests: [String]? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.travelStyle = travelStyle
        self.interests = interests
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - User Role
enum UserRole: String, Codable {
    case user = "user"
    case admin = "admin"
}

// MARK: - Travel Style
struct TravelStyle: Codable {
    let budget: BudgetType
    let pace: PaceType
    let social: SocialType
    let accommodation: AccommodationType
}

enum BudgetType: String, Codable {
    case budget = "Budget"
    case moderate = "Moderate"
    case luxury = "Luxury"
}

enum PaceType: String, Codable {
    case relaxed = "Relaxed"
    case moderate = "Moderate"
    case fast = "Fast-Paced"
}

enum SocialType: String, Codable {
    case solo = "Solo"
    case smallGroup = "Small Group"
    case largeGroup = "Large Group"
}

enum AccommodationType: String, Codable {
    case hostel = "Hostel"
    case hotel = "Hotel"
    case resort = "Resort"
    case airbnb = "Airbnb"
}

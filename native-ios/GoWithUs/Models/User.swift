import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let role: UserRole
    let gender: String?
    let age: Int?
    let bio: String?
    let birthDate: Date?
    let profileImage: String?
    let travelStyle: TravelStyle?
    let interests: [String]?
    let createdAt: Date?
    let updatedAt: Date?
    
    init(
        id: String,
        name: String,
        email: String,
        role: UserRole = .user,
        gender: String? = nil,
        age: Int? = nil,
        bio: String? = nil,
        birthDate: Date? = nil,
        profileImage: String? = nil,
        travelStyle: TravelStyle? = nil,
        interests: [String]? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.gender = gender
        self.age = age
        self.bio = bio
        self.birthDate = birthDate
        self.profileImage = profileImage
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
    let budget: String?
    let pace: String?
    let social: String?
    let accommodation: String?
    let food: String?
    let nightlife: String?
    let transport: String?
    let photography: String?
}


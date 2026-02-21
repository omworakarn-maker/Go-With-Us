import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let name: String
    let username: String?
    let email: String?
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
    
    // Privacy
    let isProfilePublic: Bool?
    let showGender: Bool?
    let showAge: Bool?
    let showBio: Bool?
    let showInterests: Bool?
    let showEmail: Bool?
    
    // Verification
    let isVerified: Bool?
    let verificationStatus: String?
    
    init(
        id: String,
        name: String,
        username: String? = nil,
        email: String? = nil,
        role: UserRole = .user,
        gender: String? = nil,
        age: Int? = nil,
        bio: String? = nil,
        birthDate: Date? = nil,
        profileImage: String? = nil,
        travelStyle: TravelStyle? = nil,
        interests: [String]? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        isProfilePublic: Bool? = nil,
        showGender: Bool? = nil,
        showAge: Bool? = nil,
        showBio: Bool? = nil,
        showInterests: Bool? = nil,
        showEmail: Bool? = nil,
        isVerified: Bool? = nil,
        verificationStatus: String? = nil
    ) {
        self.id = id
        self.name = name
        self.username = username
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
        self.isProfilePublic = isProfilePublic
        self.showGender = showGender
        self.showAge = showAge
        self.showBio = showBio
        self.showInterests = showInterests
        self.showEmail = showEmail
        self.isVerified = isVerified
        self.verificationStatus = verificationStatus
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


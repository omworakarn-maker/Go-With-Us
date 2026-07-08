import Foundation

// MARK: - User Model
struct User: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let username: String?
    let usernameUpdatedAt: Date?
    let email: String?
    let role: UserRole
    let gender: String?
    let age: Int?
    let bio: String?
    let birthDate: Date?
    let profileImage: String?
    let gallery: [String]?
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
        usernameUpdatedAt: Date? = nil,
        email: String? = nil,
        role: UserRole = .user,
        gender: String? = nil,
        age: Int? = nil,
        bio: String? = nil,
        birthDate: Date? = nil,
        profileImage: String? = nil,
        gallery: [String]? = nil,
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
        self.usernameUpdatedAt = usernameUpdatedAt
        self.email = email
        self.role = role
        self.gender = gender
        self.age = age
        self.bio = bio
        self.birthDate = birthDate
        self.profileImage = profileImage
        self.gallery = gallery
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
enum UserRole: String, Codable, Hashable {
    case user = "user"
    case admin = "admin"
}

// MARK: - TravelStyle
struct TravelStyle: Codable, Hashable {
    var budget: Int?
    var activityStyle: Int?
    var timeOfDay: [String]?
    
    enum CodingKeys: String, CodingKey {
        case budget, activityStyle, timeOfDay
    }
    
    init(budget: Int? = nil, activityStyle: Int? = nil, timeOfDay: [String]? = nil) {
        self.budget = budget
        self.activityStyle = activityStyle
        self.timeOfDay = timeOfDay
    }
    
    init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        
        if let b = try? container?.decodeIfPresent(Int.self, forKey: .budget) {
            self.budget = b
        } else if let bStr = try? container?.decodeIfPresent(String.self, forKey: .budget) {
            self.budget = Int(bStr)
        }
        
        if let a = try? container?.decodeIfPresent(Int.self, forKey: .activityStyle) {
            self.activityStyle = a
        } else if let aStr = try? container?.decodeIfPresent(String.self, forKey: .activityStyle) {
            self.activityStyle = Int(aStr)
        }
        
        self.timeOfDay = try? container?.decodeIfPresent([String].self, forKey: .timeOfDay)
    }
}


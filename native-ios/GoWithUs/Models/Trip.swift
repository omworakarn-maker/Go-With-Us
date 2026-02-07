import Foundation

// MARK: - Trip Model
struct Trip: Codable, Identifiable {
    let id: String
    let title: String
    let destination: String
    let description: String?  // Optional since backend can return null
    let startDate: Date
    let endDate: Date?  // Optional since backend can return null
    let budget: Int
    let maxParticipants: Int
    let category: TripCategory
    let imageUrl: String? // Added for image display
    let creatorId: String
    let creator: User
    let participants: [Participant]?  // Optional since backend doesn't always include it
    let aiAnalysis: AIAnalysis?
    let createdAt: Date?
    let updatedAt: Date?
    
    // Custom initializer for preview/testing
    init(
        id: String,
        title: String,
        destination: String,
        description: String? = nil,
        startDate: Date,
        endDate: Date? = nil,
        budget: Int,
        maxParticipants: Int,
        category: TripCategory,
        imageUrl: String? = nil,
        creator: User,
        participants: [Participant]? = nil,
        creatorId: String? = nil,
        aiAnalysis: AIAnalysis? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.destination = destination
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.budget = budget
        self.maxParticipants = maxParticipants
        self.category = category
        self.imageUrl = imageUrl
        self.creator = creator
        self.participants = participants
        self.creatorId = creatorId ?? creator.id
        self.aiAnalysis = aiAnalysis
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed properties
    var currentParticipants: Int {
        participants?.count ?? 0
    }
    
    var isFull: Bool {
        currentParticipants >= maxParticipants
    }
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        if let endDate = endDate {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        } else {
            return formatter.string(from: startDate)
        }
    }
    
    var formattedBudget: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return "฿\(formatter.string(from: NSNumber(value: budget)) ?? "\(budget)")"
    }
}

// MARK: - Trip Category
enum TripCategory: String, Codable, CaseIterable {
    case adventure = "ผจญภัย"
    case beach = "ทะเล"
    case mountain = "ภูเขา"
    case city = "เมือง"
    case culture = "วัฒนธรรม"
    case food = "อาหาร"
    case nature = "ธรรมชาติ"
    case shopping = "ช้อปปิ้ง"
    case sport = "กีฬา"
    case other = "อื่นๆ"
    
    var icon: String {
        switch self {
        case .adventure: return "🏔️"
        case .beach: return "🏖️"
        case .mountain: return "⛰️"
        case .city: return "🏙️"
        case .culture: return "🎭"
        case .food: return "🍜"
        case .nature: return "🌿"

        case .shopping: return "🛍️"
        case .sport: return "⚽️"
        case .other: return "✨"
        }
    }
    
    var assetName: String {
        switch self {
        case .adventure: return "category_adventure"
        case .beach: return "category_beach"
        case .mountain: return "category_mountain"
        case .city: return "category_city"
        case .culture: return "category_culture"
        case .food: return "category_food"
        case .nature: return "category_nature"
        case .shopping: return "category_shopping"
        case .sport: return "category_sport"
        case .other: return "category_other"
        }
    }
}

// MARK: - AI Analysis
struct AIAnalysis: Codable {
    let summary: String
    let highlights: [String]
    let recommendations: [String]
    let compatibility: Int?
}

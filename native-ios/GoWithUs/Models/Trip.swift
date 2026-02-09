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
    let gallery: [String]? // Added for additional images
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
        gallery: [String]? = nil,
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
        self.gallery = gallery
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
    case camping = "แคมป์ปิ้ง"
    case city = "เมือง"
    case culture = "วัฒนธรรม"
    case history = "ประวัติศาสตร์"
    case food = "อาหาร"
    case cafe = "คาเฟ่"
    case nature = "ธรรมชาติ"
    case photography = "ถ่ายรูป"
    case shopping = "ช้อปปิ้ง"
    case sport = "กีฬา"
    case party = "ปาร์ตี้"
    case volunteer = "จิตอาสา"
    case family = "ครอบครัว"
    case other = "อื่นๆ"
    
    var icon: String {
        switch self {
        case .adventure: return "🧗"
        case .beach: return "🏖️"
        case .mountain: return "⛰️"
        case .camping: return "⛺"
        case .city: return "🏙️"
        case .culture: return "🎭"
        case .history: return "🏛️"
        case .food: return "🍜"
        case .cafe: return "☕"
        case .nature: return "🌳"
        case .photography: return "📸"
        case .shopping: return "🛍️"
        case .sport: return "🏃"
        case .party: return "🎉"
        case .volunteer: return "🤝"
        case .family: return "👨‍👩‍👧‍👦"
        case .other: return "✨"
        }
    }
    
    var assetName: String {
        switch self {
        case .adventure: return "category_adventure"
        case .beach: return "category_beach"
        case .mountain: return "category_mountain"
        case .camping: return "category_camping" // Ensure asset exists or use placeholder logic
        case .city: return "category_city"
        case .culture: return "category_culture"
        case .history: return "category_history"
        case .food: return "category_food"
        case .cafe: return "category_cafe"
        case .nature: return "category_nature"
        case .photography: return "category_photography"
        case .shopping: return "category_shopping"
        case .sport: return "category_sport"
        case .party: return "category_party"
        case .volunteer: return "category_volunteer"
        case .family: return "category_family"
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

import Foundation

// MARK: - Trip Model
struct Trip: Codable, Identifiable {
    let id: String
    let title: String
    let destination: String
    let description: String?
    let startDate: Date
    let endDate: Date?
    let budget: Int
    let maxParticipants: Int
    let category: TripCategory
    let isPublic: Bool
    let imageUrl: String?
    let gallery: [String]?
    let creatorId: String
    let creator: User
    let participants: [Participant]?
    let itinerary: [DayPlan]?
    let aiAnalysis: AIAnalysis?
    let matchScore: Int?
    let createdAt: Date?
    let updatedAt: Date?
    
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
        isPublic: Bool = true,
        imageUrl: String? = nil,
        gallery: [String]? = nil,
        creator: User,
        participants: [Participant]? = nil,
        itinerary: [DayPlan]? = nil,
        creatorId: String? = nil,
        aiAnalysis: AIAnalysis? = nil,
        matchScore: Int? = nil,
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
        self.isPublic = isPublic
        self.imageUrl = imageUrl
        self.gallery = gallery
        self.creator = creator
        self.participants = participants
        self.itinerary = itinerary
        self.creatorId = creatorId ?? creator.id
        self.aiAnalysis = aiAnalysis
        self.matchScore = matchScore
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, destination, description, startDate, endDate, budget, maxParticipants, category, isPublic, imageUrl, gallery, creatorId, creator, participants, itinerary, aiAnalysis, matchScore, createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        destination = try container.decode(String.self, forKey: .destination)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        budget = try container.decode(Int.self, forKey: .budget)
        maxParticipants = try container.decode(Int.self, forKey: .maxParticipants)
        category = try container.decode(TripCategory.self, forKey: .category)
        isPublic = try container.decodeIfPresent(Bool.self, forKey: .isPublic) ?? true
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        gallery = try container.decodeIfPresent([String].self, forKey: .gallery)
        creatorId = try container.decode(String.self, forKey: .creatorId)
        creator = try container.decode(User.self, forKey: .creator)
        participants = try container.decodeIfPresent([Participant].self, forKey: .participants)
        itinerary = try container.decodeIfPresent([DayPlan].self, forKey: .itinerary)
        aiAnalysis = try container.decodeIfPresent(AIAnalysis.self, forKey: .aiAnalysis)
        matchScore = try container.decodeIfPresent(Int.self, forKey: .matchScore)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
    
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

// MARK: - Trip Category (Simplified temporarily to fix build)
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
    case eatAndTravel = "กินเที่ยว"
    case workshop = "เวิร์กชอป"
    case concert = "คอนเสิร์ต"
    case relax = "พักผ่อน"
    case other = "อื่นๆ"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = TripCategory(rawValue: rawValue) ?? .other
    }
    
    var icon: String {
        return "📌"
    }
    
    var assetName: String {
        return "category_other"
    }
}

// MARK: - AI Analysis
struct AIAnalysis: Codable {
    let summary: String
    let highlights: [String]
    let recommendations: [String]
    let compatibility: Int?
}

// MARK: - Itinerary
struct DayPlan: Codable, Identifiable {
    var id = UUID()
    let day: Int
    let activities: [Activity]
    
    enum CodingKeys: String, CodingKey {
        case day, activities
    }
}

struct Activity: Codable, Identifiable {
    var id = UUID()
    let time: String
    let name: String
    let location: String
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case time, name, location, description
    }
}

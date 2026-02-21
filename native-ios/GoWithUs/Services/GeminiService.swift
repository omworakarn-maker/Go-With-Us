import Foundation

enum AIError: LocalizedError {
    case invalidURL
    case invalidAPIKey
    case noData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL มีปัญหา"
        case .invalidAPIKey: return "API Key ไม่ถูกต้อง"
        case .noData: return "เซิร์ฟเวอร์ AI มีปัญหา กรุณาลองใหม่"
        case .decodingError: return "ข้อมูลที่ตอบกลับผิดพลาด"
        }
    }
}

class GeminiService {
    static let shared = GeminiService()
    // 👉 คำเตือน: ห้ามนำ API Key จริง push ขึ้น GitHub เด็ดขาดเพื่อความปลอดภัย!
    // กรุณาใส่ API Key ของคุณเวลาต้องการรันทดสอบในเครื่องตัวเอง 
    // หรือใช้วิธีเก็บใน Secrets.xcconfig / Backend proxy แทน
    private let apiKey = "" // ใส่ Key ตรงนี้ตอนจะรันในเครื่อง
    private let model = "gemini-2.5-flash-lite"
    
    private init() {}
    
    func chat(message: String, history: [ChatMessage]) async throws -> String {
        guard !apiKey.isEmpty else { throw AIError.invalidAPIKey }
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw AIError.invalidURL }
        
        var contents: [[String: Any]] = []
        
        let systemPrompt = """
        คุณคือ 'ที่ปรึกษา' ผู้เชี่ยวชาญด้านการท่องเที่ยว หน้าที่ของคุณคือช่วยหาทริปเที่ยว ให้คำแนะนำสถานที่ท่องเที่ยว และร่างแผนการเดินทาง (Itinerary)
        
        กฎสำคัญ:
        1. ห้ามตอบคำถามที่ไม่เกี่ยวข้องกับการท่องเที่ยว
        2. ถ้าผู้ใช้ขอให้ร่างทริป ให้จัดทำแผนการเดินทางรายวันละเอียดที่สุด (Day 1, Day 2, ...) และใส่ลงใน description ของ JSON ด้วยเสมอ
        3. โครงสร้าง JSON สำหรับร่างทริป:
        {
          "title": "ชื่อทริป",
          "destination": "จังหวัด",
          "description": "แผนการเดินทางรายวันอย่างละเอียด",
          "startDate": "YYYY-MM-DD",
          "endDate": "YYYY-MM-DD",
          "budget": 5000,
          "maxParticipants": 10,
          "category": "หมวดหมู่ไทย",
              "tags": ["tag1"]
        }
        """
        
        contents.append(["role": "user", "parts": [["text": systemPrompt]]])
        contents.append(["role": "model", "parts": [["text": "รับทราบครับ พร้อมช่วยจัดทริปครับ"]]])
        
        for msg in history {
            contents.append([
                "role": msg.isUser ? "user" : "model",
                "parts": [["text": msg.content]]
            ])
        }
        
        contents.append([
            "role": "user",
            "parts": [["text": message]]
        ])
        
        let body: [String: Any] = ["contents": contents]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown Error"
            print("Gemini API Error: \(errorString)")
            throw AIError.noData
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        return geminiResponse.candidates?.first?.content.parts.first?.text ?? "ขออภัยครับ ลองใหม่อีกครั้ง"
    }
}

// MARK: - Models
struct GeminiResponse: Decodable {
    let candidates: [Candidate]?
}
struct Candidate: Decodable {
    let content: Content
}
struct Content: Decodable {
    let parts: [Part]
}
struct Part: Decodable {
    let text: String?
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

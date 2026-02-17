import Foundation

enum AIError: Error {
    case invalidURL
    case invalidAPIKey
    case noData
    case decodingError
}

class GeminiService {
    static let shared = GeminiService()
    // Hardcoding for now as Env vars in iOS are tricky without a plist or huge setup.
    // Using the key found in .env: AIzaSyCBxIlQroyzGdy1jb1br9f671z9pDsg6cM
    private let apiKey = "AIzaSyCBxIlQroyzGdy1jb1br9f671z9pDsg6cM"
    private let model = "gemini-2.5-flash-lite" // Using the model seen in web code
    
    private init() {}
    
    func chat(message: String, history: [ChatMessage]) async throws -> String {
        guard !apiKey.isEmpty else { throw AIError.invalidAPIKey }
        
        // Endpoint
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw AIError.invalidURL }
        
        // Prepare Body
        // Gemini API expects: { contents: [{ role: "user"|"model", parts: [{ text: "..." }] }] }
        var contents: [[String: Any]] = []
        
        // Add System Instruction (Travel Advisor Scope)
        let systemPrompt = """
        คุณคือ 'ที่ปรึกษา' ผู้เชี่ยวชาญด้านการท่องเที่ยว หน้าที่ของคุณคือช่วยหาทริปเที่ยว ให้คำแนะนำสถานที่ท่องเที่ยว และสร้าง/ร่างทริปตามหมวดหมู่
        
        กฎสำคัญ:
        1. ห้ามตอบคำถามที่ไม่เกี่ยวข้องกับการท่องเที่ยว
        2. ถ้าผู้ใช้ขอให้ "ร่างทริป", "สร้างทริป", หรือ "จัดทริป" ให้ตอบกลับมาเป็น JSON Block เท่านั้น โดยใช้โครงสร้างนี้:
        ```json
        {
          "title": "ชื่อทริปที่น่าสนใจ",
          "destination": "จังหวัดหรือสถานที่หลัก",
          "description": "รายละเอียดทริปแบบย่อ",
          "startDate": "YYYY-MM-DD (ถ้าไม่ระบุให้ใส่วันพรุ่งนี้)",
          "endDate": "YYYY-MM-DD (คำนวณจากจำนวนวัน)",
          "budget": 5000 (ใส่ตัวเลขประมาณการ ถ้าฟรีใส่ 0),
          "maxParticipants": 10 (ใส่ตัวเลขที่เหมาะสม),
          "category": "ชื่อหมวดหมู่ภาษาไทย (เช่น ทะเล, ภูเขา, คาเฟ่)",
          "tags": ["keyword1", "keyword2"] (แท็กหรือคีย์เวิร์ดที่เกี่ยวข้อง เช่น ชื่อสถานที่ กิจกรรม)
        }
        ```
        3. ถ้าเป็นการพูดคุยปกติ ให้ตอบเป็นข้อความธรรมดา
        """
        
        contents.append([
            "role": "user",
            "parts": [["text": systemPrompt]]
        ])
        contents.append([
            "role": "model",
            "parts": [["text": "รับทราบครับ ผมพร้อมให้คำปรึกษาเรื่องการท่องเที่ยวครับ"]]
        ])
        
        // Add History
        for msg in history {
            let role = msg.isUser ? "user" : "model"
            contents.append([
                "role": role,
                "parts": [["text": msg.content]]
            ])
        }
        
        // Add Current Message
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
            if let errorText = String(data: data, encoding: .utf8) {
                print("Gemini API Error: \(errorText)")
            }
            throw AIError.noData
        }
        
        // Decode Response
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        return geminiResponse.candidates?.first?.content.parts.first?.text ?? "ขออภัย ฉันไม่สามารถตอบคำถามนี้ได้"
    }
}

// MARK: - Gemini Response Models
struct GeminiResponse: Decodable {
    let candidates: [Candidate]?
}

struct Candidate: Decodable {
    let content: Content
}

struct Content: Decodable {
    let parts: [Part]
    let role: String?
}

struct Part: Decodable {
    let text: String?
}

// MARK: - Chat Message Model for UI
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

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
    
    // ✅ NO MORE HARDCODED API KEY!
    // The key is now stored securely on the backend.
    // iOS app calls our own backend proxy instead.
    
    private init() {}
    
    func chat(message: String, history: [ChatMessage]) async throws -> String {
        var contents: [GeminiContent] = []
        
        let systemPrompt = """
        คุณคือ 'ที่ปรึกษา' ผู้เชี่ยวชาญด้านการท่องเที่ยว หน้าที่ของคุณคือช่วยหาทริปเที่ยว ให้คำแนะนำสถานที่ท่องเที่ยว และร่างแผนการเดินทาง (Itinerary)
        
        กฎสำคัญเด็ดขาด:
        1. ห้ามตอบคำถามที่ไม่เกี่ยวข้องกับการท่องเที่ยว
        2. ถ้าผู้ใช้ขอให้ร่างทริป ให้จัดทำแผนการเดินทางรายวันละเอียดที่สุด และใส่ลงใน "itinerary" array (ห้ามใส่ใน description) โดย description ให้เขียนแค่สรุปย่อๆ ของทริปเท่านั้น
        3. วันที่ (startDate, endDate) ต้องเป็นวันที่ในอนาคตเสมอ **ปีปัจจุบันคือปี 2026 (กุมภาพันธ์)** ดังนั้นห้ามสร้างทริปในปี 2024 หรือ 2025 เด็ดขาด! Format ต้องเป็น YYYY-MM-DD
        4. หมวดหมู่ (category) ต้องเลือกจากรายการนี้เท่านั้น: ผจญภัย, ทะเล, ภูเขา, แคมป์ปิ้ง, เมือง, วัฒนธรรม, ประวัติศาสตร์, อาหาร, คาเฟ่, ธรรมชาติ, ถ่ายรูป, ช้อปปิ้ง, กีฬา, ปาร์ตี้, จิตอาสา, ครอบครัว, กินเที่ยว, เวิร์กชอป, คอนเสิร์ต, พักผ่อน, อื่นๆ
        
        โครงสร้าง JSON สำหรับร่างทริป:
        {
          "title": "ชื่อทริป",
          "destination": "จังหวัดในประเทศไทย",
          "description": "คำอธิบายภาพรวมของทริปสั้นๆ (ไม่เกิน 2-3 ประโยค)",
          "startDate": "2026-XX-XX",
          "endDate": "2026-XX-XX",
          "budget": 5000,
          "maxParticipants": 10,
          "category": "หมวดหมู่ภาษาไทยจากรายการข้อ 4",
          "tags": ["tag1", "tag2"],
          "itinerary": [
            {
              "day": 1,
              "activities": [
                {
                  "time": "09:00",
                  "name": "ชื่อสถานที่/กิจกรรม",
                  "location": "สถานที่",
                  "description": "รายละเอียดกิจกรรม"
                }
              ]
            }
          ]
        }
        """
        
        contents.append(GeminiContent(role: "user", parts: [GeminiPart(text: systemPrompt)]))
        contents.append(GeminiContent(role: "model", parts: [GeminiPart(text: "รับทราบครับ พร้อมช่วยจัดทริปครับ")]))
        
        for msg in history {
            contents.append(GeminiContent(
                role: msg.isUser ? "user" : "model",
                parts: [GeminiPart(text: msg.content)]
            ))
        }
        
        contents.append(GeminiContent(
            role: "user",
            parts: [GeminiPart(text: message)]
        ))
        
        let requestBody = GeminiChatRequest(contents: contents)
        
        do {
            let response: GeminiResponse = try await APIService.shared.request(
                endpoint: "/ai/chat",
                method: .post,
                body: requestBody,
                requiresAuth: true
            )
            
            return response.candidates?.first?.content.parts.first?.text ?? "ขออภัยครับ ลองใหม่อีกครั้ง"
        } catch {
            print("❌ Proxy AI Error: \(error.localizedDescription)")
            throw AIError.noData
        }
    }
}

// MARK: - Models
struct GeminiChatRequest: Codable {
    let contents: [GeminiContent]
}

struct GeminiContent: Codable {
    let role: String
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]?
}
struct Candidate: Codable {
    let content: Content
}
struct Content: Codable {
    let parts: [Part]
}
struct Part: Codable {
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

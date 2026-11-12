import Foundation


// Decode a draft without ever falling back to displaying its raw JSON.
enum AITripResponse {
    static func parse(_ text: String) -> (draft: TripDraft?, message: String) {
        guard let start = text.firstIndex(of: "{") else { return (nil, text) }
        var depth = 0
        var quoted = false
        var escaped = false
        var end: String.Index?
        for index in text.indices where index >= start {
            let character = text[index]
            if quoted {
                if escaped { escaped = false }
                else if character == "\\" { escaped = true }
                else if character == "\"" { quoted = false }
            } else if character == "\"" { quoted = true }
            else if character == "{" { depth += 1 }
            else if character == "}" {
                depth -= 1
                if depth == 0 { end = text.index(after: index); break }
            }
        }
        guard let end, let data = String(text[start..<end]).data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return (nil, "แผนทริปที่ได้รับยังไม่ครบ กรุณาลองขอให้จัดแผนใหม่อีกครั้ง")
        }
        var object = (root["trip"] as? [String: Any]) ?? root
        // Only treat trip-shaped JSON as a draft.
        guard object["title"] != nil || object["destination"] != nil else {
            return (nil, (root["message"] as? String) ?? (root["text"] as? String) ??
                "ได้รับคำตอบในรูปแบบข้อมูล กรุณาขอให้ AI อธิบายเป็นข้อความอีกครั้ง")
        }
        for key in ["budget", "maxParticipants", "activityStyle"] {
            if let string = object[key] as? String,
               let number = Double(string.replacingOccurrences(of: ",", with: "")),
               number.isFinite, number >= 0, number <= Double(Int32.max) {
                object[key] = Int(number)
            }
        }
        if object["description"] == nil { object["description"] = "" }
        if let days = object["itinerary"] as? [[String: Any]] {
            object["itinerary"] = days.enumerated().map { index, day -> [String: Any] in
                var day = day
                if day["day"] == nil { day["day"] = index + 1 }
                if let activities = day["activities"] as? [[String: Any]] {
                    day["activities"] = activities.map { activity -> [String: Any] in
                        var activity = activity
                        for key in ["time", "location", "description"] where activity[key] == nil {
                            activity[key] = ""
                        }
                        return activity
                    }
                }
                return day
            }
        }
        let normalized = try? JSONSerialization.data(withJSONObject: object)
        let draft = normalized.flatMap { try? JSONDecoder().decode(TripDraft.self, from: $0) }
        if let draft, !draft.title.isEmpty, !draft.destination.isEmpty, !draft.startDate.isEmpty {
            let prose = (String(text[..<start]) + String(text[end...]))
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (draft, prose.isEmpty ? "จัดแผนทริปให้แล้วครับ ดูรายละเอียดในการ์ดด้านล่างได้เลย" : prose)
        }
        let title = object["title"] as? String ?? "แผนทริป"
        let description = object["description"] as? String ?? ""
        return (nil, title + (description.isEmpty ? "" : "\n\n" + description) +
            "\n\nรายละเอียดแผนยังไม่ครบสำหรับสร้างทริป กรุณาขอให้ AI จัดแผนใหม่อีกครั้ง")
    }
}


struct TripDraft: Codable {
    let title: String
    let destination: String
    let description: String
    let startDate: String // Format: YYYY-MM-DD
    let endDate: String?  // Format: YYYY-MM-DD
    let budget: Int
    let budgetType: String?
    let maxParticipants: Int
    let category: String
    let interestTags: [String]?
    let tags: [String]?
    let itinerary: [DayPlan]?
    let activityStyle: Int?
    let timeOfDay: [String]?
}

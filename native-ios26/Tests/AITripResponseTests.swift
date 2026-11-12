import Foundation

// Host-side decoding fixtures; compile with the production TripDraft.swift.
struct DayPlan: Codable {
    let day: Int
    let activities: [Activity]
}
struct Activity: Codable {
    let time: String
    let name: String
    let location: String
    let description: String
}

@main
struct AITripResponseTests {
    static func main() {
        let json = #"{"title":"เที่ยว {กรุงเทพ}","destination":"กรุงเทพมหานคร","startDate":"2026-12-01","budget":"1,500","maxParticipants":"4","category":"คาเฟ่","itinerary":[{"activities":[{"name":"คาเฟ่"}]}]}"#
        let result = AITripResponse.parse("```json\n" + json + "\n```")
        assert(result.draft?.budget == 1500)
        assert(result.draft?.maxParticipants == 4)
        assert(result.draft?.itinerary?.first?.day == 1)
        assert(result.draft?.itinerary?.first?.activities.first?.location == "")
        assert(!result.message.contains("{"))
        assert(!result.message.contains("```"))
        let wrapped = AITripResponse.parse("{\"trip\":" + json + "}")
        assert(wrapped.draft != nil)
        let incomplete = AITripResponse.parse(#"{"title":"เที่ยวไทย"}"#)
        assert(incomplete.draft == nil)
        assert(!incomplete.message.contains("{"))
        let truncated = AITripResponse.parse(#"{"title":"เที่ยวไทย""#)
        assert(truncated.draft == nil && !truncated.message.contains("{"))
        let plain = AITripResponse.parse("แนะนำให้เดินทางช่วงเช้าครับ")
        assert(plain.draft == nil && plain.message == "แนะนำให้เดินทางช่วงเช้าครับ")
        print("PASS: draft JSON normalization, braces in text, wrappers, incomplete/truncated responses, and plain chat")
    }
}

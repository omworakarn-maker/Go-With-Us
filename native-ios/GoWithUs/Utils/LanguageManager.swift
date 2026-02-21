import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable {
    case thai = "th"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .thai: return "ภาษาไทย"
        case .english: return "English"
        }
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")
            // Normally you would change the Locale here or notify the app
        }
    }
    
    private init() {
        let savedLang = UserDefaults.standard.string(forKey: "AppLanguage") ?? "th"
        self.currentLanguage = AppLanguage(rawValue: savedLang) ?? .thai
    }
    
    // Helper translation string
    func localizedString(for key: String) -> String {
        // Implement basic mapping for the most used text
        let map: [String: [AppLanguage: String]] = [
            "home": [.thai: "หน้าแรก", .english: "Home"],
            "explore": [.thai: "ที่ปรึกษา", .english: "Explore"],
            "find_friend": [.thai: "หาเพื่อน", .english: "Find Buddy"],
            "match": [.thai: "แมตช์", .english: "Match"],
            "my_trips": [.thai: "ทริปของฉัน", .english: "My Trips"],
            "create": [.thai: "สร้างทริป", .english: "Create"],
            "profile": [.thai: "โปรไฟล์", .english: "Profile"],
            "settings": [.thai: "ตั้งค่า", .english: "Settings"],
            "language": [.thai: "ภาษา", .english: "Language"],
            "logout": [.thai: "ออกจากระบบ", .english: "Logout"]
        ]
        
        return map[key]?[currentLanguage] ?? key
    }
}

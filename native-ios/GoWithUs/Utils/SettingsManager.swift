import SwiftUI
import UIKit

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

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // MARK: - Haptic Settings
    @Published var isHapticEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isHapticEnabled, forKey: "haptic_enabled")
        }
    }
    
    // MARK: - Language Settings
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")
        }
    }
    
    // MARK: - Layout Preference
    @Published var homeLayoutPreference: AppScreen {
        didSet {
            UserDefaults.standard.set(homeLayoutPreference.rawValue, forKey: "home_layout_preference")
        }
    }
    
    private init() {
        // Load Haptics
        self.isHapticEnabled = UserDefaults.standard.object(forKey: "haptic_enabled") as? Bool ?? true
        
        // Load Language
        let savedLang = UserDefaults.standard.string(forKey: "AppLanguage") ?? "th"
        self.currentLanguage = AppLanguage(rawValue: savedLang) ?? .thai
        
        // Load Home Layout Preference
        let savedLayout = UserDefaults.standard.string(forKey: "home_layout_preference") ?? AppScreen.home.rawValue
        self.homeLayoutPreference = AppScreen(rawValue: savedLayout) ?? .home
    }
    
    // MARK: - Localized String Helper
    func localizedString(for key: String) -> String {
        let map: [String: [AppLanguage: String]] = [
            // Menu / Tabs
            "home": [.thai: "หน้าแรก", .english: "Home"],
            "explore": [.thai: "ที่ปรึกษา", .english: "Explore"],
            "find_friend": [.thai: "หาเพื่อน", .english: "Find Buddy"],
            "match": [.thai: "แมตช์", .english: "Match"],
            "my_trips": [.thai: "ทริปของฉัน", .english: "My Trips"],
            "create": [.thai: "สร้างทริป", .english: "Create"],
            "profile": [.thai: "โปรไฟล์", .english: "Profile"],
            "settings": [.thai: "ตั้งค่า", .english: "Settings"],
            "language": [.thai: "ภาษา", .english: "Language"],
            "logout": [.thai: "ออกจากระบบ", .english: "Logout"],
            "ai_chat": [.thai: "คุยกับ AI", .english: "AI Consultant"],
            "vibration": [.thai: "การสั่น", .english: "Vibration"],
            
            // Home / Search
            "search_placeholder": [.thai: "ค้นหาทริป...", .english: "Search trips..."],
            "tab_recommended": [.thai: "แนะนำ", .english: "Recommended"],
            "tab_new": [.thai: "มาใหม่", .english: "New"],
            "tab_popular": [.thai: "ยอดนิยม", .english: "Popular"],
            "loading_trips": [.thai: "กำลังโหลดทริป...", .english: "Loading trips..."],
            "no_trips_found": [.thai: "ไม่พบทริป", .english: "No trips found"],
            "try_another_search": [.thai: "ลองค้นหาด้วยคำอื่นหรือสร้างทริปใหม่", .english: "Try searching something else or create a new trip"],
            
            // AI Chat
            "ai_header": [.thai: "ที่ปรึกษา", .english: "AI Consultant"],
            "ai_input_placeholder": [.thai: "พิมพ์ข้อความ...", .english: "Type a message..."],
            "ai_welcome_message": [.thai: "สวัสดีครับ! ผมคือที่ปรึกษาการท่องเที่ยว มีอะไรให้ผมช่วยแนะนำหรือวางแผนทริปไหมครับ? 🌍\n\n💡 ลองบอกผมว่า:\n• อยากไปเที่ยวที่ไหน\n• งบประมาณเท่าไหร่\n• หรือพิมพ์ \"ร่างทริป\" เพื่อให้ผมสร้างแผนทริปให้", .english: "Hello! I am your travel consultant. How can I help you plan your trip? 🌍\n\n💡 Try telling me:\n• Where you want to go\n• Your budget\n• Or type \"Draft trip\" so I can create a plan for you"],
            "ai_draft_ready": [.thai: "🎉 ร่างทริปพร้อมแล้ว!", .english: "🎉 Trip draft is ready!"],
            "ai_create_now": [.thai: "สร้างเลย", .english: "Create Now"],
            "ai_edit_before": [.thai: "ดูและแก้ไข", .english: "Review & Edit"],
            
            // Profile
            "edit": [.thai: "แก้ไข", .english: "Edit"],
            "save": [.thai: "บันทึก", .english: "Save"],
            "cancel": [.thai: "ยกเลิก", .english: "Cancel"],
            "gender": [.thai: "เพศ", .english: "Gender"],
            "age": [.thai: "อายุ", .english: "Age"],
            "bio": [.thai: "ประวัติส่วนตัว", .english: "Bio"],
            "interests": [.thai: "ความสนใจ", .english: "Interests"],
            "travel_style": [.thai: "สไตล์การเดินทาง", .english: "Travel Style"],
            "not_verified": [.thai: "ยังไม่ยืนยันตัวตน", .english: "Not Verified"],
            "verified": [.thai: "ยืนยันตัวตนแล้ว", .english: "Verified"],
            
            // Edit Profile
            "username_available": [.thai: "ชื่อผู้ใช้นี้สามารถใช้ได้", .english: "Username is available"],
            "username_taken": [.thai: "ชื่อผู้ใช้ต้องไม่ซ้ำกับผู้อื่น", .english: "Username must be unique"],
            "lifestyle_header": [.thai: "ไลฟ์สไตล์และสไตล์การท่องเที่ยว", .english: "Lifestyle & Travel Style"],
            
            // Find Buddy
            "like": [.thai: "สนใจ", .english: "LIKE"],
            "nope": [.thai: "ผ่าน", .english: "NOPE"],
            "match_success": [.thai: "แมตช์แล้ว! 🎉", .english: "It's a Match! 🎉"],
            
            // Questionnaire
            "step_prefix": [.thai: "ขั้นตอนที่", .english: "Step"],
            "step_suffix": [.thai: "จาก", .english: "of"],
            
            // Other
            "guest_user": [.thai: "ผู้เยี่ยมชม", .english: "Guest"],
            "email_placeholder": [.thai: "อีเมลของคุณ@email.com", .english: "your@email.com"],
            
            // Alerts
            "logout_confirm": [.thai: "คุณต้องการออกจากระบบใช่หรือไม่?", .english: "Are you sure you want to logout?"],
            "language_change_title": [.thai: "เปลี่ยนภาษาสำเร็จ", .english: "Language Changed"],
            "language_change_message": [.thai: "กรุณาปิดแอพและเปิดใหม่เพื่อให้การเปลี่ยนแปลงมีผลสมบูรณ์", .english: "Please close and restart the app for the changes to take full effect."],
            "ok": [.thai: "ตกลง", .english: "OK"],
            "refresh": [.thai: "รีเฟรช", .english: "Refresh"],
            "loading_buddies": [.thai: "กำลังค้นหาเพื่อนใหม่...", .english: "Finding new buddies..."],
            "try_again": [.thai: "ลองใหม่", .english: "Try Again"],
            "close": [.thai: "ปิด", .english: "Close"]
        ]
        return map[key]?[currentLanguage] ?? key
    }
    
    // MARK: - Haptic Triggering
    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isHapticEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func triggerNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    func triggerSelection() {
        guard isHapticEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

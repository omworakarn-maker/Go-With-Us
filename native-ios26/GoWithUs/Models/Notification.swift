import Foundation

// MARK: - Notification Model
struct AppNotification: Codable, Identifiable {
    let id: String
    let title: String
    let message: String
    let type: String // "alert", "trip", "system"
    let targetId: String? // Trip ID if type is "trip"
    let createdAt: String // API returns ISO string
    let isRead: Bool
}

// MARK: - Create Notification Request
struct CreateNotificationRequest: Encodable {
    let title: String
    let message: String
    let type: String
    let targetId: String?
}

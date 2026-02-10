import Foundation

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    // MARK: - Get Notifications
    func getNotifications() async throws -> [AppNotification] {
        return try await APIService.shared.request(
            endpoint: "/notifications",
            method: .get
        )
    }
    
    // MARK: - Mark as Read
    func markAsRead(id: String) async throws {
        let _: EmptyResponse = try await APIService.shared.request(
            endpoint: "/notifications/\(id)/read",
            method: .put
        )
    }
    
    // MARK: - Create Notification (Admin only)
    func createNotification(title: String, message: String, type: String, targetId: String?) async throws -> AppNotification {
        let request = CreateNotificationRequest(
            title: title,
            message: message,
            type: type,
            targetId: targetId
        )
        
        return try await APIService.shared.request(
            endpoint: "/notifications",
            method: .post,
            body: request
        )
    }
    
    // MARK: - Get Unread Count
    func getUnreadCount() async throws -> Int {
        struct UnreadCountResponse: Decodable {
            let count: Int
        }
        
        let response: UnreadCountResponse = try await APIService.shared.request(
            endpoint: "/notifications/unread-count",
            method: .get
        )
        
        return response.count
    }
    
    // MARK: - Delete Notification
    func deleteNotification(id: String) async throws {
        let _: EmptyResponse = try await APIService.shared.request(
            endpoint: "/notifications/\(id)",
            method: .delete
        )
    }
    
    // MARK: - Clear All Notifications
    func clearAllNotifications() async throws {
        let _: EmptyResponse = try await APIService.shared.request(
            endpoint: "/notifications/clear-all",
            method: .delete
        )
    }
    // MARK: - Register Device Token
    func registerDeviceToken(token: String) async throws {
        struct TokenRequest: Encodable {
            let token: String
        }
        
        let request = TokenRequest(token: token)
        
        let _: EmptyResponse = try await APIService.shared.request(
            endpoint: "/users/device-token",
            method: .post,
            body: request
        )
    }
}

// Empty response for endpoints that don't return data
private struct EmptyResponse: Decodable {}

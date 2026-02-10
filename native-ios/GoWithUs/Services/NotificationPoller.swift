import Foundation
import UserNotifications
import UIKit

class NotificationPoller: ObservableObject {
    static let shared = NotificationPoller()
    
    private var timer: Timer?
    private var lastChecked: Date = Date()
    @Published var unreadCount: Int = 0
    
    private init() {}
    
    func startPolling() {
        stopPolling()
        
        // Initial check
        checkNotifications()
        
        // Poll every 10 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.checkNotifications()
        }
        print("⏰ Notification Polling Started")
    }
    
    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
    
    func checkNotifications() {
        Task {
            do {
                // 1. Get unread count for badge
                let count = try await NotificationService.shared.getUnreadCount()
                
                await MainActor.run {
                    self.unreadCount = count
                    self.unreadCount = count
                    UNUserNotificationCenter.current().setBadgeCount(count) { _ in }
                }
                
                // 2. Get latest notifications to see if we need to alert
                let notifications = try await NotificationService.shared.getNotifications()
                
                // Filter for new notifications (created after last checked time)
                let newNotifications = notifications.filter { notification in
                    if let date = self.date(from: notification.createdAt) {
                        return date > self.lastChecked
                    }
                    return false
                }
                
                if !newNotifications.isEmpty {
                    print("🔔 Found \(newNotifications.count) new notifications")
                    self.lastChecked = Date() // Update last checked time
                    
                    for notification in newNotifications {
                        self.triggerLocalNotification(title: notification.title, body: notification.message)
                    }
                    
                    // Notify app to refresh UI
                    NotificationCenter.default.post(name: NSNotification.Name("NewNotificationReceived"), object: nil)
                }
                
            } catch {
                print("⚠️ Polling Error: \(error)")
            }
        }
    }
    
    private func triggerLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to add local notification: \(error)")
            } else {
                print("✅ Local Notification Scheduled: \(title)")
            }
        }
    }
    
    private func date(from string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string)
    }
}

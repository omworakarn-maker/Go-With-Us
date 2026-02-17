import Foundation

class LocalNotificationStore: ObservableObject {
    static let shared = LocalNotificationStore()
    @Published private(set) var notifications: [AppNotification] = []

    private let key = "local_notifications_v1"
    private init() {
        load()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(notifications)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("❌ Failed to save local notifications: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        do {
            notifications = try JSONDecoder().decode([AppNotification].self, from: data)
        } catch {
            print("⚠️ Failed to load local notifications: \(error)")
        }
    }

    func add(notification: AppNotification) {
        // Prepend newest
        DispatchQueue.main.async {
            self.notifications.insert(notification, at: 0)
            self.save()
        }
    }

    func markAsRead(id: String) {
        if let idx = notifications.firstIndex(where: { $0.id == id }) {
            var n = notifications[idx]
            // create a new copy with isRead true
            let updated = AppNotification(id: n.id, title: n.title, message: n.message, type: n.type, targetId: n.targetId, createdAt: n.createdAt, isRead: true)
            notifications[idx] = updated
            save()
        }
    }

    func clearAll() {
        notifications = []
        save()
    }
}

import UIKit
import UserNotifications
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure User Notifications
        UNUserNotificationCenter.current().delegate = self
        
        // Request Permission
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                if granted {
                    print("✅ Notification Permission Granted")
                    // Register with APNs on the main thread
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } else {
                    print("❌ Notification Permission Denied")
                }
            }
        )
        
        // Register for Background Fetch
        // iOS will decide when to wake up the app based on usage
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)

        // Start message polling to keep chat badges up-to-date
        MessagePoller.shared.startPolling()
        
        // Initialize Haptic Settings
        HapticManager.setupInitial()
        
        return true
    }

    // MARK: - Lock Portrait Orientation
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    // MARK: - Remote Notifications (APNs)
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let token = tokenParts.joined()
        print("📲 APNs Device Token: \(token)")

        Task {
            do {
                try await NotificationService.shared.registerDeviceToken(token: token)
                print("✅ Device token registered on server")
            } catch {
                print("❌ Failed to register device token: \(error)")
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }

    // Called when a remote notification arrives (background/terminated) and requests background fetch
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("🔔 Remote notification received: \(userInfo)")

        // Trigger a fresh check for notifications which will schedule local alerts & update badge
        NotificationPoller.shared.checkNotifications()
        completionHandler(.newData)
    }
    
    // MARK: - Background Fetch
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("🔄 Background Fetch Started")
        
        Task {
            do {
                // Check for unread notifications
                let count = try await NotificationService.shared.getUnreadCount()
                
                if count > 0 {
                    // Trigger Local Notification
                    let content = UNMutableNotificationContent()
                    content.title = "GoWithUs"
                    content.body = "คุณมี \(count) ข้อความที่ยังไม่ได้อ่าน"
                    content.sound = .default
                    content.badge = NSNumber(value: count)
                    
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil) // Deliver immediately
                    try await UNUserNotificationCenter.current().add(request)
                    
                    print("🔔 Background Notification Scheduled: \(count) unread")
                    completionHandler(.newData)
                } else {
                    print("✅ No new data")
                    completionHandler(.noData)
                }
            } catch {
                print("❌ Background Fetch Failed: \(error)")
                completionHandler(.failed)
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Receive notification while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 Received Foreground Notification")
        // Post notification for in-app updates (Badge counts etc)
        NotificationCenter.default.post(name: NSNotification.Name("NewNotificationReceived"), object: nil)
        
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 Notification Tapped")
        // Reset badge count
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error { print("❌ Failed to reset badge: \(error)") }
        }

        // Extract payload and post open-chat event
        let userInfo = response.notification.request.content.userInfo

        var partnerId: String? = nil
        var tripId: String? = nil

        if let p = userInfo["partnerId"] as? String { partnerId = p }
        if let t = userInfo["tripId"] as? String { tripId = t }
        if let t = userInfo["targetId"] as? String, tripId == nil { tripId = t }

        // Post to app to open specific chat/section
        var info: [String: Any] = [:]
        if let p = partnerId { info["partnerId"] = p }
        if let t = tripId { info["tripId"] = t }

        NotificationCenter.default.post(name: NSNotification.Name("OpenChatDetail"), object: nil, userInfo: info)

        completionHandler()
    }
}

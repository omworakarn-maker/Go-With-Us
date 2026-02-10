import UIKit
import UserNotifications

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
                    print("✅ Push Notifications Permission Granted")
                } else {
                    print("❌ Push Notifications Permission Denied")
                }
                if let error = error {
                    print("❌ Push Auth Error: \(error)")
                }
            }
        )
        

        
        return true
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Receive notification while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show banner even if app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("🔔 Notification Tapped: \(userInfo)")
        
        // Reset badge count
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
        
        completionHandler()
    }
}

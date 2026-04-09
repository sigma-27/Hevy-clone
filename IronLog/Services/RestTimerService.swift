import Foundation
import UserNotifications

/// Handles background local notifications for the rest timer.
/// The in-app countdown is driven by AppState's Combine timer.
enum RestTimerService {
    private static let notificationID = "IronLog.restTimer"

    static func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Schedule a local notification to fire after `seconds`.
    /// Call this when the rest timer starts in case the user backgrounds the app.
    static func scheduleNotification(seconds: TimeInterval) {
        cancelNotification()
        guard seconds > 1 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Rest Complete 💪"
        content.body = "Time for your next set!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Cancel any pending rest timer notification.
    /// Call when the user skips the timer or returns to foreground.
    static func cancelNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
}

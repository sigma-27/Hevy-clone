import Foundation
import UserNotifications
import Combine

@Observable
class RestTimerService {
    var remaining: TimeInterval = 0
    var total: TimeInterval = 90
    var isRunning = false

    private var timer: AnyCancellable?
    private static let notificationID = "IronLog.restTimer"

    func start(seconds: TimeInterval) {
        stop()
        total = seconds
        remaining = seconds
        isRunning = true
        scheduleNotification(after: seconds)
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.remaining > 0 {
                    self.remaining -= 1
                } else {
                    self.stop()
                }
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
        isRunning = false
        remaining = 0
        cancelNotification()
    }

    func addTime(_ seconds: TimeInterval) {
        remaining = max(0, remaining + seconds)
        cancelNotification()
        if isRunning { scheduleNotification(after: remaining) }
    }

    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func scheduleNotification(after seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Rest Complete"
        content.body = "Time to do your next set!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.notificationID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
    }
}

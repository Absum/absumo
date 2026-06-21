import Foundation
import UserNotifications

/// A single, gentle daily reminder — opt-in, easy to turn off. Never nags;
/// it's a nudge toward the habit, not the point of the app.
enum Reminders {
    private static let id = "absumo.daily"

    /// Ask permission and schedule a daily reminder at ~19:00 local.
    static func enable() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            var date = DateComponents()
            date.hour = 19
            let content = UNMutableNotificationContent()
            content.title = "Un po' d'italiano?"
            content.body = "A few minutes today keeps your words alive."
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(request)
        }
    }

    static func disable() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}

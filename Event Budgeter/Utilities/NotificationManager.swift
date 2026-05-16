//
//  NotificationManager.swift
//  Event Budgeter
//

import UserNotifications
import SwiftData

struct NotificationManager {
    static func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    static func scheduleEventNotification(for event: Event) {
        cancelNotification(for: event)
        guard event.notifyOnDay else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(event.displayEmoji) \(event.title)"
        content.body = "Today is \(event.title)!"
        content.sound = .default

        let cal = Calendar.current
        let trigger: UNNotificationTrigger?

        switch event.recurrenceRule {
        case .yearly:
            let components = cal.dateComponents([.month, .day], from: event.canonicalDate)
            var dc = DateComponents()
            dc.month = components.month
            dc.day = components.day
            dc.hour = 9
            trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        case .nthWeekdayYearly:
            // Date shifts each year — schedule only for next occurrence, non-repeating.
            // rescheduleNthWeekdayNotifications() is called on app launch to refresh.
            guard let next = event.nextOccurrence else { return }
            var dc = cal.dateComponents([.year, .month, .day], from: next)
            dc.hour = 9
            trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
        case .none:
            var dc = cal.dateComponents([.year, .month, .day], from: event.canonicalDate)
            dc.hour = 9
            trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
        }

        guard let trigger else { return }
        let id = notificationID(for: event)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func rescheduleNthWeekdayNotifications(for events: [Event]) {
        for event in events where event.notifyOnDay && event.recurrenceRule == .nthWeekdayYearly {
            scheduleEventNotification(for: event)
        }
    }

    static func cancelNotification(for event: Event) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationID(for: event)]
        )
    }

    private static func notificationID(for event: Event) -> String {
        "event-\(event.persistentModelID)"
    }
}

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
        let components = cal.dateComponents([.month, .day], from: event.canonicalDate)
        let trigger: UNNotificationTrigger

        if event.recurrenceRule == .yearly {
            var dc = DateComponents()
            dc.month = components.month
            dc.day = components.day
            dc.hour = 9
            trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        } else {
            var dc = cal.dateComponents([.year, .month, .day], from: event.canonicalDate)
            dc.hour = 9
            trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
        }

        let id = notificationID(for: event)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
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

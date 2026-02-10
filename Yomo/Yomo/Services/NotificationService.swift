//
//  NotificationService.swift
//  Yomo
//
//  Local notification scheduling, cancellation, and permission management
//

import Foundation
import UIKit
import UserNotifications
import FirebaseFirestore

final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            if granted {
                await registerCategories()
            }
            return granted
        } catch {
            return false
        }
    }

    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Categories & Actions

    private func registerCategories() async {
        // No action buttons on notifications — user interacts via the in-app snooze view instead.
        // Tapping the notification opens the app and shows the snooze sheet.
        let freeCategory = UNNotificationCategory(
            identifier: NotificationCategory.reminderFree,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let proCategory = UNNotificationCategory(
            identifier: NotificationCategory.reminderPro,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([freeCategory, proCategory])
    }

    // MARK: - Schedule Notification

    func scheduleNotification(for reminder: Reminder) async {
        guard let reminderId = reminder.id else { return }

        // Cancel any existing notification for this reminder
        cancelNotification(for: reminderId)

        let triggerDate = reminder.snoozedUntil?.dateValue() ?? reminder.triggerDate.dateValue()

        // Don't schedule for past dates
        guard triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Yomo"
        content.body = reminder.title
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "reminderId": reminderId,
            "title": reminder.title
        ]

        if let notes = reminder.notes, !notes.isEmpty {
            content.subtitle = notes
        }

        // Set category based on Pro status
        let isPro = await AppState.shared.isPro
        content.categoryIdentifier = isPro
            ? NotificationCategory.reminderPro
            : NotificationCategory.reminderFree

        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: triggerDate
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: reminderId,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            // Notification scheduling failed silently
        }
    }

    // MARK: - Cancel Notification

    func cancelNotification(for reminderId: String) {
        center.removePendingNotificationRequests(withIdentifiers: [reminderId])
        center.removeDeliveredNotifications(withIdentifiers: [reminderId])
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: - Snooze

    func snoozeNotification(reminderId: String, title: String, minutes: Int) async {
        cancelNotification(for: reminderId)

        let snoozeDate = Date().addingTimeInterval(TimeInterval(minutes * 60))

        let content = UNMutableNotificationContent()
        content.title = "Yomo"
        content.body = title
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "reminderId": reminderId,
            "title": title
        ]

        let isPro = await AppState.shared.isPro
        content.categoryIdentifier = isPro
            ? NotificationCategory.reminderPro
            : NotificationCategory.reminderFree

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: reminderId,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            // Snooze notification scheduling failed silently
        }

        // Update storage with snoozed time
        if FirebaseAuthHelper.currentUserId != nil {
            await updateSnoozedUntilFirestore(reminderId: reminderId, date: snoozeDate)
        } else {
            LocalReminderStore.shared.snoozeReminder(id: reminderId, until: snoozeDate)
        }
    }

    private func updateSnoozedUntilFirestore(reminderId: String, date: Date) async {
        guard let userId = FirebaseAuthHelper.currentUserId else { return }

        let db = Firestore.firestore()
        let ref = db.collection("users").document(userId)
            .collection("reminders").document(reminderId)

        try? await ref.updateData([
            "snoozedUntil": Timestamp(date: date),
            "updatedAt": Timestamp(date: Date())
        ])
    }

    // MARK: - Sync All Notifications

    func syncAllNotifications(reminders: [Reminder]) async {
        // Cancel all pending
        center.removeAllPendingNotificationRequests()

        // Re-schedule active reminders
        for reminder in reminders where reminder.status == .active {
            await scheduleNotification(for: reminder)
        }
    }

    // MARK: - Badge Management

    @MainActor
    func setBadgeCount(_ count: Int) {
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(count)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
}

// MARK: - Constants

enum NotificationCategory {
    static let reminderFree = "YOMO_REMINDER_FREE"
    static let reminderPro = "YOMO_REMINDER_PRO"
}

enum NotificationAction {
    static let complete = "YOMO_COMPLETE"
    static let snooze5 = "YOMO_SNOOZE_5"
    static let snooze15 = "YOMO_SNOOZE_15"
    static let snooze30 = "YOMO_SNOOZE_30"
    static let customSnooze = "YOMO_CUSTOM_SNOOZE"
}

// MARK: - Firebase Auth Helper

import FirebaseAuth

enum FirebaseAuthHelper {
    static var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
}

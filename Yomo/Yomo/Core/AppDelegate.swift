//
//  AppDelegate.swift
//  Yomo
//
//  Application delegate for Firebase, RevenueCat, and notification handling
//

import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import GoogleSignIn
import UserNotifications
import RevenueCat

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize Firebase
        FirebaseApp.configure()

        // Initialize RevenueCat
        if !Constants.revenueCatAPIKey.isEmpty {
            Purchases.logLevel = .debug
            Purchases.configure(withAPIKey: Constants.revenueCatAPIKey)
        }

        // Register for remote notifications (for FCM)
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()

        // Set Firebase Messaging delegate
        Messaging.messaging().delegate = self

        // Request notification permission
        Task {
            let granted = await NotificationService.shared.requestPermission()
            if granted {
                await MainActor.run {
                    application.registerForRemoteNotifications()
                }
            }
        }

        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let reminderId = userInfo["reminderId"] as? String ?? ""
        let title = userInfo["title"] as? String ?? ""

        switch response.actionIdentifier {
        case NotificationAction.complete:
            handleComplete(reminderId: reminderId)

        case NotificationAction.snooze5:
            handleSnooze(reminderId: reminderId, title: title, minutes: 5)

        case NotificationAction.snooze15:
            handleSnooze(reminderId: reminderId, title: title, minutes: 15)

        case NotificationAction.snooze30:
            handleSnooze(reminderId: reminderId, title: title, minutes: 30)

        case NotificationAction.customSnooze:
            // Opens the app — navigate to snooze view
            Task { @MainActor in
                AppState.shared.pendingSnoozeReminderId = reminderId
                AppState.shared.pendingSnoozeTitle = title
            }

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification — navigate to snooze view
            Task { @MainActor in
                AppState.shared.pendingSnoozeReminderId = reminderId
                AppState.shared.pendingSnoozeTitle = title
            }

        default:
            break
        }

        completionHandler()
    }

    private func handleComplete(reminderId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let ref = db.collection("users").document(userId)
            .collection("reminders").document(reminderId)

        NotificationService.shared.cancelNotification(for: reminderId)

        Task {
            do {
                let doc = try await ref.getDocument()
                let recurrenceData = doc.data()?["recurrence"] as? [String: Any]
                let recurrenceType = recurrenceData?["type"] as? String

                if let recurrenceType, recurrenceType != "none" {
                    // Recurring: calculate next date
                    let triggerDate = (doc.data()?["triggerDate"] as? Timestamp)?.dateValue() ?? Date()
                    let interval = recurrenceData?["interval"] as? Int ?? 1
                    let unit = recurrenceData?["unit"] as? String ?? "day"

                    let nextDate = Self.calculateNextDate(
                        from: triggerDate,
                        interval: interval,
                        unit: unit
                    )

                    try await ref.updateData([
                        "triggerDate": Timestamp(date: nextDate),
                        "snoozedUntil": FieldValue.delete(),
                        "updatedAt": Timestamp(date: Date())
                    ])
                } else {
                    try await ref.updateData([
                        "status": "completed",
                        "updatedAt": Timestamp(date: Date())
                    ])
                }
            } catch {
                // Error handling complete action
            }
        }
    }

    private func handleSnooze(reminderId: String, title: String, minutes: Int) {
        Task {
            await NotificationService.shared.snoozeNotification(
                reminderId: reminderId,
                title: title,
                minutes: minutes
            )
        }
    }

    static func calculateNextDate(from date: Date, interval: Int, unit: String) -> Date {
        let calendar = Calendar.current
        let now = Date()
        var nextDate = date

        let component: Calendar.Component = {
            switch unit {
            case "hour": return .hour
            case "week": return .weekOfYear
            case "month": return .month
            default: return .day
            }
        }()

        while nextDate <= now {
            nextDate = calendar.date(byAdding: component, value: interval, to: nextDate) ?? nextDate
        }

        return nextDate
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken,
              let userId = Auth.auth().currentUser?.uid else { return }

        // Save FCM token to Firestore for cross-device sync
        Task {
            await DeviceSyncService.shared.registerDevice(
                userId: userId,
                fcmToken: token
            )
        }
    }
}

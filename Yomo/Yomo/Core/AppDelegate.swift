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
    /// Firebase uses AppDelegate/SceneDelegate swizzling by default unless
    /// `FirebaseAppDelegateProxyEnabled` is explicitly set to `NO`/`false` in Info.plist.
    /// When swizzling is enabled, Firebase Auth & Messaging will automatically observe APNs
    /// callbacks, so we should not manually forward them.
    private var isFirebaseAppDelegateProxyEnabled: Bool {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "FirebaseAppDelegateProxyEnabled")
        else {
            return true
        }

        if let b = raw as? Bool { return b }
        if let n = raw as? NSNumber { return n.boolValue }
        if let s = raw as? String { return (s as NSString).boolValue }
        return true
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize Firebase
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Initialize RevenueCat
        if RevenueCatConfig.hasAPIKey {
            guard RevenueCatConfig.isReleaseConfigurationValid else {
                // Safety fallback: if a release build is misconfigured, avoid initializing purchases.
                return true
            }
            #if DEBUG
            Purchases.logLevel = .debug
            #else
            Purchases.logLevel = .error
            #endif
            Purchases.configure(withAPIKey: RevenueCatConfig.apiKey)
            RevenueCatConfig.markConfigured()
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
        // Always provide the APNs token to FCM when we implement this callback.
        Messaging.messaging().apnsToken = deviceToken

        // Only forward APNs token to Firebase Auth when AppDelegate swizzling is disabled.
        // With swizzling enabled, Firebase Auth will observe APNs callbacks automatically.
        //
        // This also avoids a crash in FirebaseAuth (12.9.0) when the internal APNs token manager
        // has not completed initialization yet.
        if !isFirebaseAppDelegateProxyEnabled, FirebaseApp.app() != nil {
            #if DEBUG
            Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
            #else
            Auth.auth().setAPNSToken(deviceToken, type: .prod)
            #endif
        }

        // Now that APNS token is set, FCM token can be generated/refreshed.
        Task {
            await DeviceSyncService.shared.refreshFCMToken()
        }
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // If AppDelegate swizzling is disabled, forward Auth-related pushes for Phone Auth.
        if !isFirebaseAppDelegateProxyEnabled, FirebaseApp.app() != nil,
           Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }

        // Handle FCM silent pushes for cross-device notification sync.
        Task {
            await DeviceSyncService.shared.handleSilentPush(userInfo: userInfo)
            completionHandler(.newData)
        }
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
        NotificationService.shared.cancelNotification(for: reminderId)

        // Local mode
        if Auth.auth().currentUser == nil {
            if let reminder = LocalReminderStore.shared.findReminder(byId: reminderId) {
                LocalReminderStore.shared.completeReminder(reminder)
            }
            return
        }

        // Firebase mode
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let ref = db.collection("users").document(userId)
            .collection("reminders").document(reminderId)

        Task {
            do {
                let doc = try await ref.getDocument()
                let recurrenceData = doc.data()?["recurrence"] as? [String: Any]
                let recurrenceType = recurrenceData?["type"] as? String

                if let recurrenceType, recurrenceType != "none" {
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

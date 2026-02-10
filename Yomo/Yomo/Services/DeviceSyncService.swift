//
//  DeviceSyncService.swift
//  Yomo
//
//  Cross-device sync via FCM token registration and device management
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

final class DeviceSyncService {
    static let shared = DeviceSyncService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Device Registration

    func registerDevice(userId: String, fcmToken: String) async {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let deviceRef = db.collection("users").document(userId)
            .collection("devices").document(deviceId)

        let deviceData: [String: Any] = [
            "fcmToken": fcmToken,
            "platform": "ios",
            "deviceName": UIDevice.current.name,
            "lastActiveAt": Timestamp(date: Date()),
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        ]

        try? await deviceRef.setData(deviceData, merge: true)
    }

    // MARK: - Update Last Active

    func updateLastActive() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let deviceRef = db.collection("users").document(userId)
            .collection("devices").document(deviceId)

        try? await deviceRef.updateData([
            "lastActiveAt": Timestamp(date: Date())
        ])
    }

    // MARK: - Refresh FCM Token

    func refreshFCMToken() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            let token = try await Messaging.messaging().token()
            await registerDevice(userId: userId, fcmToken: token)
        } catch {
            // FCM token refresh failed
        }
    }

    // MARK: - Handle Silent Push

    func handleSilentPush(userInfo: [AnyHashable: Any]) async {
        guard let action = userInfo["action"] as? String,
              let reminderId = userInfo["reminderId"] as? String else { return }

        switch action {
        case "completed":
            NotificationService.shared.cancelNotification(for: reminderId)

        case "snoozed":
            NotificationService.shared.cancelNotification(for: reminderId)
            if let title = userInfo["title"] as? String,
               let newTriggerDateString = userInfo["newTriggerDate"] as? String {
                let formatter = ISO8601DateFormatter()
                if let newDate = formatter.date(from: newTriggerDateString) {
                    let content = UNMutableNotificationContent()
                    content.title = "Yomo"
                    content.body = title
                    content.sound = .default
                    content.userInfo = ["reminderId": reminderId, "title": title]

                    let isPro = await AppState.shared.isPro
                    content.categoryIdentifier = isPro
                        ? NotificationCategory.reminderPro
                        : NotificationCategory.reminderFree

                    let components = Calendar.current.dateComponents(
                        [.year, .month, .day, .hour, .minute, .second],
                        from: newDate
                    )
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: reminderId,
                        content: content,
                        trigger: trigger
                    )
                    try? await UNUserNotificationCenter.current().add(request)
                }
            }

        case "deleted":
            NotificationService.shared.cancelNotification(for: reminderId)

        default:
            break
        }
    }
}

import UserNotifications

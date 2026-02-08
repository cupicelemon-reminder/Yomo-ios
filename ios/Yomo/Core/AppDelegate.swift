//
//  AppDelegate.swift
//  Yomo
//
//  Application delegate for Firebase and RevenueCat initialization
//

import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize Firebase
        FirebaseApp.configure()

        // TODO: Initialize RevenueCat in Day 6
        // Purchases.configure(withAPIKey: Constants.revenueCatAPIKey)

        // Register for remote notifications (for FCM in Day 5)
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()

        // Set Firebase Messaging delegate
        Messaging.messaging().delegate = self

        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Handle Google Sign-In URL
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notifications even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap (will implement in Day 3)
        completionHandler()
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // Save FCM token (will implement device registration in Day 5)
        if let token = fcmToken {
            print("FCM Token: \(token)")
            // TODO: Save to Firestore in Day 5
        }
    }
}

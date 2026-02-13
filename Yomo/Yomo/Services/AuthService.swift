//
//  AuthService.swift
//  Yomo
//
//  Authentication service for Google Sign-In and Email/Password
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import GoogleSignIn

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: AuthError?

    private let db = Firestore.firestore()
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    enum AuthError: LocalizedError {
        case signInFailed(String)
        case emailSignInFailed(String)
        case emailSignUpFailed(String)
        case userCreationFailed

        var errorDescription: String? {
            switch self {
            case .signInFailed(let message):
                return "Sign in failed: \(message)"
            case .emailSignInFailed(let message):
                return "Email sign in failed: \(message)"
            case .emailSignUpFailed(let message):
                return "Email sign up failed: \(message)"
            case .userCreationFailed:
                return "Failed to create user profile"
            }
        }
    }

    private init() {
        self.currentUser = Auth.auth().currentUser

        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                if let user = user {
                    await self?.loadOrCreateUserProfile(for: user)
                }
            }
        }
    }

    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Google Sign-In
    func signInWithGoogle() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.signInFailed("No root view controller")
        }

        isLoading = true
        defer { isLoading = false }

        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw AuthError.signInFailed("Missing Firebase client ID")
            }

            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.signInFailed("Missing ID token")
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            currentUser = authResult.user

            await loadOrCreateUserProfile(for: authResult.user)

            // Login to RevenueCat with user ID
            await SubscriptionService.shared.loginUser(userId: authResult.user.uid)

        } catch {
            self.error = .signInFailed(error.localizedDescription)
            throw error
        }
    }

    // MARK: - Email Authentication
    func signUpWithEmail(email: String, password: String, displayName: String?) async throws {
        isLoading = true
        defer { isLoading = false }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedDisplayName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let authResult = try await Auth.auth().createUser(withEmail: normalizedEmail, password: password)

            if let normalizedDisplayName, !normalizedDisplayName.isEmpty {
                let profileChangeRequest = authResult.user.createProfileChangeRequest()
                profileChangeRequest.displayName = normalizedDisplayName
                try await profileChangeRequest.commitChanges()
            }

            let user = Auth.auth().currentUser ?? authResult.user
            currentUser = user

            await loadOrCreateUserProfile(for: user)
            await SubscriptionService.shared.loginUser(userId: user.uid)
        } catch {
            self.error = .emailSignUpFailed(error.localizedDescription)
            throw error
        }
    }

    func signInWithEmail(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        do {
            let authResult = try await Auth.auth().signIn(withEmail: normalizedEmail, password: password)
            currentUser = authResult.user

            await loadOrCreateUserProfile(for: authResult.user)
            await SubscriptionService.shared.loginUser(userId: authResult.user.uid)
        } catch {
            self.error = .emailSignInFailed(error.localizedDescription)
            throw error
        }
    }

    // MARK: - User Profile Management
    private func loadOrCreateUserProfile(for user: User) async {
        let userRef = db.collection("users").document(user.uid)

        // Build a fallback profile from Firebase Auth data in case Firestore fails
        let fallbackProfile = UserProfile(
            id: user.uid,
            displayName: user.displayName ?? "User",
            email: user.email ?? "",
            phone: user.phoneNumber,
            photoURL: user.photoURL?.absoluteString,
            createdAt: Timestamp(date: Date()),
            hasCompletedOnboarding: false
        )

        do {
            let snapshot = try await userRef.getDocument()

            if !snapshot.exists {
                let profileData: [String: Any] = [
                    "displayName": user.displayName ?? "User",
                    "email": user.email ?? "",
                    "phone": user.phoneNumber ?? "",
                    "photoURL": user.photoURL?.absoluteString ?? "",
                    "createdAt": Timestamp(date: Date()),
                    "hasCompletedOnboarding": false
                ]

                try await userRef.setData(profileData)

                try await userRef.collection("subscription").document("current").setData([
                    "isPro": false,
                    "plan": NSNull(),
                    "expiresAt": NSNull()
                ])

                // Seed tutorial reminders for new users
                await seedTutorialReminders(userId: user.uid)
            } else {
                // Backfill missing profile fields when a user signs in with a new provider.
                var updates: [String: Any] = [:]
                let data = snapshot.data() ?? [:]

                if (data["email"] == nil || (data["email"] as? String)?.isEmpty == true),
                   let email = user.email, !email.isEmpty {
                    updates["email"] = email
                }

                if (data["phone"] == nil || (data["phone"] as? String)?.isEmpty == true),
                   let phone = user.phoneNumber, !phone.isEmpty {
                    updates["phone"] = phone
                }

                // Migrate legacy onboarding flag from UserDefaults to Firestore
                if data["hasCompletedOnboarding"] == nil {
                    let legacyCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                        || UserDefaults.standard.bool(forKey: "hasCompletedFeatureTour")
                    if legacyCompleted {
                        updates["hasCompletedOnboarding"] = true
                    }
                }

                if !updates.isEmpty {
                    try await userRef.setData(updates, merge: true)
                }
            }

            let fetchedData = try await userRef.getDocument().data()
            if let data = fetchedData {
                let profile = UserProfile(
                    id: user.uid,
                    displayName: data["displayName"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    phone: data["phone"] as? String,
                    photoURL: data["photoURL"] as? String,
                    createdAt: data["createdAt"] as? Timestamp ?? Timestamp(date: Date()),
                    hasCompletedOnboarding: data["hasCompletedOnboarding"] as? Bool ?? false
                )
                AppState.shared.updateUser(profile)
            } else {
                AppState.shared.updateUser(fallbackProfile)
            }

            // Register device with FCM token
            await registerDevice(userId: user.uid)

        } catch {
            // Firestore failed but auth succeeded — still navigate the user
            AppState.shared.updateUser(fallbackProfile)
            self.error = .userCreationFailed
        }
    }

    private func registerDevice(userId: String) async {
        do {
            let token = try await Messaging.messaging().token()
            await DeviceSyncService.shared.registerDevice(userId: userId, fcmToken: token)
        } catch {
            // FCM token not available yet — will be registered via MessagingDelegate
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
            let deviceRef = db.collection("users").document(userId)
                .collection("devices").document(deviceId)

            try? await deviceRef.setData([
                "platform": "ios",
                "deviceName": UIDevice.current.name,
                "lastActiveAt": Timestamp(date: Date()),
                "fcmToken": ""
            ], merge: true)
        }
    }

    // MARK: - Sign Out
    func signOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
        currentUser = nil
        AppState.shared.updateUser(nil)
        AppState.shared.resetOnboardingState()
        NotificationService.shared.cancelAllNotifications()

        Task {
            await SubscriptionService.shared.logoutUser()
        }
    }

    // MARK: - Onboarding
    func completeOnboardingInFirestore() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("users").document(userId)
        try? await userRef.setData(["hasCompletedOnboarding": true], merge: true)
    }

    private func seedTutorialReminders(userId: String) async {
        let remindersRef = db.collection("users").document(userId).collection("reminders")
        let now = Date()

        let tutorialReminders: [(String, TimeInterval)] = [
            ("Welcome to Yomo! Swipe right on me to mark as complete", 0),
            ("Try swiping left on this reminder to delete it", 5 * 60),
            ("Tap the + button to create your own reminder", 60 * 60),
            ("Hold the mic button to speak your reminder naturally", 3 * 60 * 60),
            ("Tap the gear icon to explore themes and settings", 24 * 60 * 60)
        ]

        for (title, offset) in tutorialReminders {
            let triggerDate = now.addingTimeInterval(offset)
            let data: [String: Any] = [
                "title": title,
                "notes": "",
                "triggerDate": Timestamp(date: triggerDate),
                "recurrence": ["type": "none"],
                "status": "active",
                "createdAt": Timestamp(date: now),
                "updatedAt": Timestamp(date: now)
            ]
            try? await remindersRef.addDocument(data: data)
        }
    }
}

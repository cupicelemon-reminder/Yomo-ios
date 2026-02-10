//
//  AuthService.swift
//  Yomo
//
//  Authentication service for Google Sign-In and Phone Auth
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import GoogleSignIn

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: AuthError?

    private let db = Firestore.firestore()
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    enum AuthError: LocalizedError {
        case signInFailed(String)
        case userCreationFailed
        case phoneAuthFailed

        var errorDescription: String? {
            switch self {
            case .signInFailed(let message):
                return "Sign in failed: \(message)"
            case .userCreationFailed:
                return "Failed to create user profile"
            case .phoneAuthFailed:
                return "Phone authentication failed"
            }
        }
    }

    init() {
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

    // MARK: - Phone Authentication
    func startPhoneAuth(phoneNumber: String) async throws -> String {
        isLoading = true
        defer { isLoading = false }

        do {
            let verificationID = try await PhoneAuthProvider.provider()
                .verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            return verificationID
        } catch {
            self.error = .phoneAuthFailed
            throw error
        }
    }

    func verifyPhoneCode(verificationID: String, code: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationID,
                verificationCode: code
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            currentUser = authResult.user

            await loadOrCreateUserProfile(for: authResult.user)

            // Login to RevenueCat
            await SubscriptionService.shared.loginUser(userId: authResult.user.uid)
        } catch {
            self.error = .phoneAuthFailed
            throw error
        }
    }

    // MARK: - User Profile Management
    private func loadOrCreateUserProfile(for user: User) async {
        let userRef = db.collection("users").document(user.uid)

        do {
            let snapshot = try await userRef.getDocument()

            if !snapshot.exists {
                let profile: [String: Any] = [
                    "displayName": user.displayName ?? "User",
                    "email": user.email ?? "",
                    "photoURL": user.photoURL?.absoluteString ?? "",
                    "createdAt": Timestamp(date: Date())
                ]

                try await userRef.setData(profile)

                try await userRef.collection("subscription").document("current").setData([
                    "isPro": false,
                    "plan": NSNull(),
                    "expiresAt": NSNull()
                ])
            }

            let profileData = try await userRef.getDocument().data()
            if let data = profileData {
                let profile = UserProfile(
                    id: user.uid,
                    displayName: data["displayName"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    photoURL: data["photoURL"] as? String,
                    createdAt: data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
                )
                AppState.shared.updateUser(profile)
            }

            // Register device with FCM token
            await registerDevice(userId: user.uid)

        } catch {
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
        NotificationService.shared.cancelAllNotifications()

        Task {
            await SubscriptionService.shared.logoutUser()
        }
    }
}

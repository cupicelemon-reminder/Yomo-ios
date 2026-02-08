//
//  AuthService.swift
//  Yomo
//
//  Authentication service for Google Sign-In and Phone Auth
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: AuthError?

    private let db = Firestore.firestore()

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

        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                if let user = user {
                    await self?.loadOrCreateUserProfile(for: user)
                }
            }
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
            // Get Google Sign-In configuration
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw AuthError.signInFailed("Missing Firebase client ID")
            }

            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            // Start sign-in flow
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.signInFailed("Missing ID token")
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            // Sign in to Firebase
            let authResult = try await Auth.auth().signIn(with: credential)
            currentUser = authResult.user

            // Create or update user profile
            await loadOrCreateUserProfile(for: authResult.user)

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
                // Create new user profile
                let profile: [String: Any] = [
                    "displayName": user.displayName ?? "User",
                    "email": user.email ?? "",
                    "photoURL": user.photoURL?.absoluteString ?? "",
                    "createdAt": Timestamp(date: Date())
                ]

                try await userRef.setData(profile)

                // Initialize subscription document
                try await userRef.collection("subscription").document("current").setData([
                    "isPro": false,
                    "plan": NSNull(),
                    "expiresAt": NSNull()
                ])
            }

            // Load profile into AppState
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

            // Register device for FCM (will implement in Day 5)
            await registerDevice(userId: user.uid)

        } catch {
            self.error = .userCreationFailed
        }
    }

    private func registerDevice(userId: String) async {
        // TODO: Implement in Day 5 with FCM token
        // For now, just update lastActiveAt
        let deviceRef = db.collection("users").document(userId)
            .collection("devices").document(UIDevice.current.identifierForVendor?.uuidString ?? "unknown")

        try? await deviceRef.setData([
            "platform": "ios",
            "deviceName": UIDevice.current.name,
            "lastActiveAt": Timestamp(date: Date()),
            "fcmToken": "" // Will add in Day 5
        ], merge: true)
    }

    // MARK: - Sign Out
    func signOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
        currentUser = nil
        AppState.shared.updateUser(nil)
    }
}

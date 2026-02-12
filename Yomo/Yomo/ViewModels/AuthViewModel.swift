//
//  AuthViewModel.swift
//  Yomo
//
//  View model for authentication flow
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
    enum EmailAuthMode: String, CaseIterable, Identifiable {
        case signIn
        case signUp

        var id: String { rawValue }
        var title: String {
            switch self {
            case .signIn: return "Sign In"
            case .signUp: return "Create Account"
            }
        }
    }

    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var displayName = ""
    @Published var emailAuthMode: EmailAuthMode = .signIn

    private let authService = AuthService.shared

    init() {
        // Check initial auth state
        isAuthenticated = Auth.auth().currentUser != nil
    }

    func signInWithGoogle() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                try await authService.signInWithGoogle()
                isAuthenticated = true
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }

    func signOut() {
        do {
            try authService.signOut()
            isAuthenticated = false
        } catch {
            errorMessage = "Failed to sign out"
        }
    }

    func signInWithEmail() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }

        Task {
            isLoading = true
            errorMessage = nil

            do {
                try await authService.signInWithEmail(email: trimmedEmail, password: password)
                isAuthenticated = true
            } catch {
                errorMessage = Self.friendlyAuthMessage(for: error)
            }

            isLoading = false
        }
    }

    func signUpWithEmail() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email."
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        Task {
            isLoading = true
            errorMessage = nil

            do {
                try await authService.signUpWithEmail(
                    email: trimmedEmail,
                    password: password,
                    displayName: trimmedName.isEmpty ? nil : trimmedName
                )
                isAuthenticated = true
            } catch {
                errorMessage = Self.friendlyAuthMessage(for: error)
            }

            isLoading = false
        }
    }

    func resetEmailAuthForm() {
        errorMessage = nil
        password = ""
        confirmPassword = ""
        if emailAuthMode == .signIn {
            displayName = ""
        }
    }

    private static func friendlyAuthMessage(for error: Error) -> String {
        let nsError = error as NSError

        guard nsError.domain == AuthErrorDomain,
              let code = AuthErrorCode(rawValue: nsError.code) else {
            return error.localizedDescription
        }

        switch code {
        case .tooManyRequests:
            return "Too many requests. Please try again later."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .emailAlreadyInUse:
            return "This email is already in use."
        case .weakPassword:
            return "Password is too weak. Use at least 6 characters."
        case .wrongPassword:
            return "Incorrect password."
        case .userNotFound:
            return "No account found for this email."
        case .invalidCredential:
            return "Invalid email or password."
        case .operationNotAllowed:
            return "Email/password login is not enabled in Firebase Auth."
        default:
            return error.localizedDescription
        }
    }

    #if DEBUG
    /// Skip auth entirely — directly set AppState to navigate past login
    func devLogin() {
        let profile = UserProfile(
            id: "dev-tester-\(UUID().uuidString.prefix(8))",
            displayName: "Dev Tester",
            email: "dev@yomo.test",
            phone: nil,
            photoURL: nil,
            createdAt: FirebaseFirestore.Timestamp(date: Date())
        )
        AppState.shared.updateUser(profile)
        isAuthenticated = true
    }
    #endif
}

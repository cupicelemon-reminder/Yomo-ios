//
//  AuthViewModel.swift
//  Yomo
//
//  View model for authentication flow
//

import Foundation
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var phoneNumber = ""
    @Published var verificationCode = ""
    @Published var verificationID: String?
    @Published var showPhoneInput = false
    @Published var showCodeInput = false

    private let authService = AuthService()

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

    func startPhoneAuth() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                verificationID = try await authService.startPhoneAuth(phoneNumber: phoneNumber)
                showPhoneInput = false
                showCodeInput = true
            } catch {
                errorMessage = "Failed to send verification code"
            }

            isLoading = false
        }
    }

    func verifyCode() {
        guard let verificationID = verificationID else {
            errorMessage = "No verification ID found"
            return
        }

        Task {
            isLoading = true
            errorMessage = nil

            do {
                try await authService.verifyPhoneCode(
                    verificationID: verificationID,
                    code: verificationCode
                )
                isAuthenticated = true
            } catch {
                errorMessage = "Invalid verification code"
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
}

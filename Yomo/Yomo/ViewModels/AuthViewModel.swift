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
    @Published var phoneNumber = ""
    @Published var verificationCode = ""
    @Published var verificationID: String?
    @Published var showPhoneInput = false
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

    func startPhoneAuth() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                verificationID = try await authService.startPhoneAuth(phoneNumber: phoneNumber)
            } catch {
                errorMessage = Self.friendlyAuthMessage(for: error)
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
                errorMessage = Self.friendlyAuthMessage(for: error)
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
        case .invalidPhoneNumber:
            return "手机号格式不正确，请检查国家区号和号码。"
        case .tooManyRequests:
            return "请求过于频繁，请稍后再试。"
        case .quotaExceeded:
            return "短信发送已达上限，请稍后再试。"
        case .networkError:
            return "网络错误，请检查网络后重试。"
        case .invalidVerificationCode:
            return "验证码错误，请重新输入。"
        case .sessionExpired:
            return "验证码已过期，请重新获取。"
        case .missingVerificationCode:
            return "请输入验证码。"
        case .appNotAuthorized:
            return "当前 App 未被授权使用短信验证（请检查 Bundle ID、Firebase 配置与 APNs 设置）。"
        case .notificationNotForwarded:
            return "推送通知配置异常，请确保已启用通知权限后重试。"
        case .missingClientIdentifier:
            return "设备验证失败，请确保已启用通知权限后重试。"
        case .captchaCheckFailed:
            return "验证检查失败，请重试。"
        case .webContextCancelled:
            return "验证流程已取消。"
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

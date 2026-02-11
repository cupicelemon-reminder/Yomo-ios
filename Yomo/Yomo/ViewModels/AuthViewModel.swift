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
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var phoneNumber = ""
    @Published var verificationCode = ""
    @Published var verificationID: String?
    @Published var showPhoneInput = false

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

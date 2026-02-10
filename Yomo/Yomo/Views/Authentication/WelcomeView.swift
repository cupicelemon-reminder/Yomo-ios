//
//  WelcomeView.swift
//  Yomo
//
//  Welcome screen with Google and Phone authentication (Screen 1)
//

import SwiftUI

struct WelcomeView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var animateContent = false

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                Spacer()

                // Logo + Tagline
                VStack(spacing: Spacing.md) {
                    Image("logo-nobg")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateContent ? 1 : 0.7)
                        .opacity(animateContent ? 1 : 0)

                    VStack(spacing: Spacing.xs) {
                        Text("Your moment.")
                            .font(.titleLarge)
                            .foregroundColor(.textPrimary)

                        Text("Don't miss it.")
                            .font(.bodyRegular)
                            .foregroundColor(.textSecondary)
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 16)
                }

                Spacer()
                Spacer()

                // Auth Buttons
                VStack(spacing: Spacing.md) {
                    AuthButton(
                        icon: "envelope.fill",
                        title: "Continue with Google"
                    ) {
                        viewModel.signInWithGoogle()
                    }

                    AuthButton(
                        icon: "phone.fill",
                        title: "Continue with Phone"
                    ) {
                        viewModel.showPhoneInput = true
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 24)

                // Error
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.bodySmall)
                        .foregroundColor(.dangerRed)
                        .padding(Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .fill(Color.dangerRed.opacity(0.1))
                        )
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, Spacing.sm)
                }

                if viewModel.isLoading {
                    ProgressView()
                        .tint(.brandBlue)
                        .padding(.top, Spacing.md)
                }

                Spacer()
                    .frame(height: Spacing.lg)

                // Legal text
                Text("By continuing, you agree to our Terms of Service & Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.bottom, Spacing.lg)
                    .opacity(animateContent ? 1 : 0)
            }
        }
        .sheet(isPresented: $viewModel.showPhoneInput) {
            PhoneInputSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showCodeInput) {
            CodeVerificationSheet(viewModel: viewModel)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Phone Input Sheet
struct PhoneInputSheet: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.lg) {
                Text("Enter your phone number")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)

                TextField("+1 (555) 123-4567", text: $viewModel.phoneNumber)
                    .keyboardType(.phonePad)
                    .font(.bodyRegular)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm + 2)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.sm + 2)
                            .fill(Color.brandBlueBg)
                    )
                    .padding(.horizontal, Spacing.lg)

                PrimaryButton(
                    "Send Code",
                    isLoading: viewModel.isLoading,
                    isDisabled: viewModel.phoneNumber.isEmpty
                ) {
                    viewModel.startPhoneAuth()
                }
                .padding(.horizontal, Spacing.lg)

                Spacer()
            }
            .padding(.top, Spacing.xl)
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}

// MARK: - Code Verification Sheet
struct CodeVerificationSheet: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.lg) {
                Text("Enter verification code")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)

                TextField("123456", text: $viewModel.verificationCode)
                    .keyboardType(.numberPad)
                    .font(.bodyRegular)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm + 2)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.sm + 2)
                            .fill(Color.brandBlueBg)
                    )
                    .padding(.horizontal, Spacing.lg)

                PrimaryButton(
                    "Verify",
                    isLoading: viewModel.isLoading,
                    isDisabled: viewModel.verificationCode.isEmpty
                ) {
                    viewModel.verifyCode()
                }
                .padding(.horizontal, Spacing.lg)

                Spacer()
            }
            .padding(.top, Spacing.xl)
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}

#Preview {
    WelcomeView()
}

//
//  EmailAuthSheet.swift
//  Yomo
//
//  Email and password authentication flow
//

import SwiftUI
import UIKit

struct EmailAuthSheet: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: FocusedField?

    private enum FocusedField {
        case displayName
        case email
        case password
        case confirmPassword
    }

    private var isSignUp: Bool {
        viewModel.emailAuthMode == .signUp
    }

    private var trimmedEmail: String {
        viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isPrimaryDisabled: Bool {
        if viewModel.isLoading { return true }
        if isSignUp {
            return trimmedEmail.isEmpty ||
                viewModel.password.isEmpty ||
                viewModel.confirmPassword.isEmpty ||
                viewModel.password != viewModel.confirmPassword ||
                viewModel.password.count < 6
        }
        return trimmedEmail.isEmpty || viewModel.password.isEmpty
    }

    private var primaryTitle: String {
        isSignUp ? "Create Account" : "Sign In"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    VStack(spacing: Spacing.xs) {
                        Text("Continue with Email")
                            .font(.titleMedium)
                            .foregroundColor(.textPrimary)

                        Text("Sync reminders across devices")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, Spacing.lg)

                    Picker("Email auth mode", selection: $viewModel.emailAuthMode) {
                        ForEach(AuthViewModel.EmailAuthMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Spacing.lg)

                    VStack(spacing: Spacing.md) {
                        if isSignUp {
                            inputTextField(
                                title: "Name (optional)",
                                text: $viewModel.displayName,
                                placeholder: "Your name",
                                focused: .displayName,
                                contentType: .name,
                                keyboardType: .default,
                                capitalization: .words
                            )
                        }

                        inputTextField(
                            title: "Email",
                            text: $viewModel.email,
                            placeholder: "name@example.com",
                            focused: .email,
                            contentType: .emailAddress,
                            keyboardType: .emailAddress,
                            capitalization: .never
                        )

                        inputSecureField(
                            title: "Password",
                            text: $viewModel.password,
                            placeholder: "At least 6 characters",
                            focused: .password,
                            contentType: isSignUp ? .newPassword : .password
                        )

                        if isSignUp {
                            inputSecureField(
                                title: "Confirm Password",
                                text: $viewModel.confirmPassword,
                                placeholder: "Repeat password",
                                focused: .confirmPassword,
                                contentType: .newPassword
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.lg)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.bodySmall)
                            .foregroundColor(.dangerRed)
                            .padding(Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.sm)
                                    .fill(Color.dangerRed.opacity(0.1))
                            )
                            .padding(.horizontal, Spacing.lg)
                    }

                    PrimaryButton(
                        primaryTitle,
                        icon: isSignUp ? "person.badge.plus" : "envelope.badge",
                        isLoading: viewModel.isLoading,
                        isDisabled: isPrimaryDisabled
                    ) {
                        if isSignUp {
                            viewModel.signUpWithEmail()
                        } else {
                            viewModel.signInWithEmail()
                        }
                    }
                    .padding(.horizontal, Spacing.lg)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.brandBlue)
                }
            }
        }
        .onAppear {
            viewModel.errorMessage = nil
            focusedField = .email
        }
        .onChange(of: viewModel.emailAuthMode) { _ in
            viewModel.resetEmailAuthForm()
            focusedField = isSignUp ? .displayName : .email
        }
        .onChange(of: viewModel.isAuthenticated) { isAuthed in
            if isAuthed {
                dismiss()
            }
        }
    }

    @ViewBuilder
    private func inputTextField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        focused: FocusedField,
        contentType: UITextContentType?,
        keyboardType: UIKeyboardType,
        capitalization: TextInputAutocapitalization
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.textSecondary)
                .tracking(0.5)

            TextField(placeholder, text: text)
                .textContentType(contentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled(true)
                .focused($focusedField, equals: focused)
                .font(.bodyRegular)
                .foregroundColor(.textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm + 2)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm + 2)
                        .fill(Color.brandBlueBg)
                )
        }
    }

    @ViewBuilder
    private func inputSecureField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        focused: FocusedField,
        contentType: UITextContentType
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.textSecondary)
                .tracking(0.5)

            SecureField(placeholder, text: text)
                .textContentType(contentType)
                .focused($focusedField, equals: focused)
                .font(.bodyRegular)
                .foregroundColor(.textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm + 2)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm + 2)
                        .fill(Color.brandBlueBg)
                )
        }
    }
}

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
            // Gradient Background
            LinearGradient(
                colors: [
                    Color.brandBlue.opacity(0.1),
                    Color.brandBlueLight.opacity(0.05),
                    Color.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Logo and Title
                VStack(spacing: Spacing.md) {
                    // TODO: Add app icon/logo here
                    Circle()
                        .fill(Color.brandBlue)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text("Y")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .scaleEffect(animateContent ? 1 : 0.5)
                        .opacity(animateContent ? 1 : 0)

                    Text("Yomo")
                        .font(.titleLarge)
                        .foregroundColor(.textPrimary)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    Text("Never forget what matters")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                }

                Spacer()

                // Auth Buttons
                VStack(spacing: Spacing.md) {
                    // Google Sign-In Button
                    Button {
                        viewModel.signInWithGoogle()
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                            Text("Continue with Google")
                                .font(.button)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.textPrimary)
                        .cornerRadius(CornerRadius.md)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .disabled(viewModel.isLoading)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)

                    // Phone Sign-In Button
                    Button {
                        viewModel.showPhoneInput = true
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "phone.circle.fill")
                                .font(.title2)
                            Text("Continue with Phone")
                                .font(.button)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandBlue)
                        .foregroundColor(.white)
                        .cornerRadius(CornerRadius.md)
                        .shadow(color: Color.brandBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(viewModel.isLoading)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                }
                .padding(.horizontal, Spacing.lg)

                // Error Message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.bodySmall)
                        .foregroundColor(.dangerRed)
                        .padding()
                        .background(Color.dangerRed.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)
                        .padding(.horizontal, Spacing.lg)
                }

                // Loading Indicator
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.brandBlue)
                }

                Spacer()
                    .frame(height: Spacing.xxl)
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
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Button {
                    viewModel.startPhoneAuth()
                } label: {
                    Text("Send Code")
                        .font(.button)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandBlue)
                        .foregroundColor(.white)
                        .cornerRadius(CornerRadius.md)
                }
                .padding(.horizontal)
                .disabled(viewModel.phoneNumber.isEmpty || viewModel.isLoading)

                if viewModel.isLoading {
                    ProgressView()
                }

                Spacer()
            }
            .padding()
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
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Button {
                    viewModel.verifyCode()
                } label: {
                    Text("Verify")
                        .font(.button)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandBlue)
                        .foregroundColor(.white)
                        .cornerRadius(CornerRadius.md)
                }
                .padding(.horizontal)
                .disabled(viewModel.verificationCode.isEmpty || viewModel.isLoading)

                if viewModel.isLoading {
                    ProgressView()
                }

                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}

#Preview {
    WelcomeView()
}

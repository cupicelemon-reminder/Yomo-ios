//
//  WelcomeView.swift
//  Yomo
//
//  Welcome screen with Google and Email authentication (Screen 1)
//

import SwiftUI

struct WelcomeView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var animateContent = false
    @State private var logoFloat = false
    @State private var showEmailAuth = false

    private var showInternalTools: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-YOMOInternalTools")
        #else
        return false
        #endif
    }

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                Spacer()

                // Logo + Tagline
                VStack(spacing: Spacing.lg) {
                    Image("logo-nobg")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .scaleEffect(animateContent ? 1 : 0.5)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: logoFloat ? -6 : 6)
                        .animation(
                            .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                            value: logoFloat
                        )

                    VStack(spacing: Spacing.sm) {
                        Text("Your moment.")
                            .font(.custom("Noteworthy-Bold", size: 30))
                            .foregroundColor(.textPrimary)

                        Text("Don't miss it.")
                            .font(.custom("Noteworthy-Light", size: 20))
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
                        title: "Continue with Google",
                        action: { viewModel.signInWithGoogle() },
                        icon: { GoogleLogo() }
                    )

                    AuthButton(
                        icon: "envelope.fill",
                        title: "Continue with Email"
                    ) {
                        viewModel.emailAuthMode = .signIn
                        showEmailAuth = true
                    }

                    #if DEBUG
                    if showInternalTools {
                        Button(action: { viewModel.devLogin() }) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "hammer.fill")
                                    .font(.system(size: 14))
                                Text("Dev Login (Skip Auth)")
                                    .font(.bodySmall)
                            }
                            .foregroundColor(.textTertiary)
                            .padding(.vertical, Spacing.xs)
                        }
                    }
                    #endif
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
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthSheet(viewModel: viewModel)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                logoFloat = true
            }
        }
    }
}

#Preview {
    WelcomeView()
}

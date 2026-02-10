//
//  SettingsView.swift
//  Yomo
//
//  Screen 11: Settings with account, subscription, and preferences
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var showPaywall = false
    @State private var showSignOutConfirm = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Account section
                    accountSection

                    // Subscription section
                    subscriptionSection

                    // Preferences section
                    preferencesSection

                    // About section
                    aboutSection

                    // Sign out
                    signOutSection
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .background(Color.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.brandBlue)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        SettingsSection(title: "ACCOUNT") {
            VStack(spacing: 0) {
                if let user = appState.currentUser {
                    SettingsRow(
                        icon: "person.circle.fill",
                        title: user.displayName,
                        detail: user.email
                    )
                } else {
                    SettingsRow(
                        icon: "person.circle.fill",
                        title: "Not signed in",
                        detail: nil
                    )
                }
            }
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        SettingsSection(title: "SUBSCRIPTION") {
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "star.circle.fill",
                    iconColor: .checkGold,
                    title: appState.isPro ? "Yomo Pro" : "Free Plan",
                    detail: appState.isPro ? "Active" : "Upgrade for more features"
                )

                if !appState.isPro {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.checkGold)
                            Text("Upgrade to Pro")
                                .font(.bodyRegular)
                                .foregroundColor(.brandBlue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.textTertiary)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm + 2)
                    }
                }
            }
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        SettingsSection(title: "PREFERENCES") {
            VStack(spacing: 0) {
                Button {
                    Task {
                        _ = await NotificationService.shared.requestPermission()
                    }
                } label: {
                    SettingsRow(
                        icon: "bell.fill",
                        iconColor: .brandBlue,
                        title: "Notifications",
                        detail: "Manage notification settings",
                        showChevron: true
                    )
                }
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        SettingsSection(title: "ABOUT") {
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "info.circle.fill",
                    title: "Version",
                    detail: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                )

                SettingsRow(
                    icon: "heart.fill",
                    iconColor: .dangerRed,
                    title: "Made for Sam Beckman",
                    detail: "RevenueCat Shipyard Contest"
                )
            }
        }
    }

    // MARK: - Sign Out Section

    private var signOutSection: some View {
        VStack(spacing: Spacing.md) {
            Button {
                showSignOutConfirm = true
            } label: {
                Text("Sign Out")
                    .font(.bodyRegular)
                    .foregroundColor(.dangerRed)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(Color.dangerRed.opacity(0.1))
                    )
            }
            .alert("Sign Out?", isPresented: $showSignOutConfirm) {
                Button("Sign Out", role: .destructive) { signOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll need to sign in again to access your reminders.")
            }
        }
    }

    // MARK: - Actions

    private func signOut() {
        do {
            try Auth.auth().signOut()
            appState.updateUser(nil)

            Task {
                await SubscriptionService.shared.logoutUser()
            }

            NotificationService.shared.cancelAllNotifications()
            dismiss()
        } catch {
            // Sign out failed
        }
    }
}

// MARK: - Settings Section

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .tracking(0.5)

            content
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(Color.dividerColor, lineWidth: 1)
                        )
                )
                .glassCardShadow()
        }
    }
}

// MARK: - Settings Row

private struct SettingsRow: View {
    let icon: String
    var iconColor: Color = .brandBlue
    let title: String
    let detail: String?
    var showChevron: Bool = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.bodyRegular)
                    .foregroundColor(.textPrimary)

                if let detail {
                    Text(detail)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm + 2)
    }
}

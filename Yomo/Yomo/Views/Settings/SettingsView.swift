//
//  SettingsView.swift
//  Yomo
//
//  Screen 11: Settings with account, subscription, and preferences
//

import SwiftUI
import FirebaseAuth
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var showPaywall = false
    @State private var showSignIn = false
    @State private var showNotificationsSettingsHint = false
    @State private var showThemePicker = false
    @State private var showSignOutConfirm = false
    @State private var showDeleteConfirm = false

    private var isSignedIn: Bool {
        Auth.auth().currentUser != nil
    }

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

                    #if DEBUG
                    debugSection
                    #endif

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
        .fullScreenCover(isPresented: $showSignIn) {
            SignInSheetView()
        }
        .sheet(isPresented: $showThemePicker) {
            ThemePickerSheetView()
                .environmentObject(appState)
        }
        .alert("Manage Notifications", isPresented: $showNotificationsSettingsHint) {
            Button("Open Settings") { openNotificationSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Notification permissions are managed in iOS Settings.")
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        SettingsSection(title: "ACCOUNT") {
            VStack(spacing: 0) {
                Button {
                    if !isSignedIn {
                        showSignIn = true
                    }
                } label: {
                    if let user = appState.currentUser {
                        SettingsRow(
                            icon: "person.circle.fill",
                            title: user.displayName,
                            detail: user.email,
                            showChevron: !isSignedIn
                        )
                    } else if let firebaseUser = Auth.auth().currentUser {
                        SettingsRow(
                            icon: "person.circle.fill",
                            title: firebaseUser.displayName ?? "Account",
                            detail: firebaseUser.email,
                            showChevron: false
                        )
                    } else {
                        SettingsRow(
                            icon: "person.circle.fill",
                            title: "Not signed in",
                            detail: "Tap to sign in",
                            showChevron: true
                        )
                    }
                }
                .buttonStyle(.plain)
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
                    openOrRequestNotificationPermission()
                } label: {
                    SettingsRow(
                        icon: "bell.fill",
                        iconColor: .brandBlue,
                        title: "Notifications",
                        detail: "Manage notification settings",
                        showChevron: true
                    )
                }

                Button {
                    if appState.isPro {
                        showThemePicker = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    SettingsRow(
                        icon: "paintpalette.fill",
                        iconColor: .brandBlue,
                        title: "Theme",
                        detail: appState.isPro ? appState.theme.displayName : "Pro feature",
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
        Group {
            if isSignedIn || appState.currentUser != nil {
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
        }
    }

    // MARK: - Actions

    private func signOut() {
        do {
            if isSignedIn {
                try AuthService.shared.signOut()
            } else {
                // Dev/local session: clear in-memory profile and local notifications.
                appState.updateUser(nil)
                NotificationService.shared.cancelAllNotifications()
            }
            dismiss()
        } catch {
            // Sign out failed
        }
    }

    #if DEBUG
    private var debugSection: some View {
        SettingsSection(title: "DEBUG") {
            VStack(spacing: 0) {
                Toggle(isOn: Binding(
                    get: { appState.isPro },
                    set: { appState.updateProStatus($0) }
                )) {
                    SettingsRow(
                        icon: "ladybug.fill",
                        iconColor: .checkGold,
                        title: "Force Pro",
                        detail: "Local override (Debug only)"
                    )
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm + 2)

                Button {
                    showPaywall = true
                } label: {
                    SettingsRow(
                        icon: "creditcard.fill",
                        iconColor: .checkGold,
                        title: "Show Paywall",
                        detail: "Open RevenueCat paywall",
                        showChevron: true
                    )
                }
            }
        }
    }
    #endif

    private func openOrRequestNotificationPermission() {
        Task {
            let status = await NotificationService.shared.checkPermissionStatus()
            switch status {
            case .notDetermined:
                _ = await NotificationService.shared.requestPermission()
            case .denied:
                await MainActor.run { showNotificationsSettingsHint = true }
            default:
                await MainActor.run { openNotificationSettings() }
            }
        }
    }

    private func openNotificationSettings() {
        let urlString: String
        if #available(iOS 16.0, *) {
            urlString = UIApplication.openNotificationSettingsURLString
        } else {
            urlString = UIApplication.openSettingsURLString
        }

        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

private struct SignInSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: Spacing.md) {
                    VStack(spacing: Spacing.xs) {
                        Text("Sign in")
                            .font(.titleLarge)
                            .foregroundColor(.textPrimary)
                        Text("Sync reminders across devices")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, Spacing.xl)

                    VStack(spacing: Spacing.md) {
                        AuthButton(
                            title: "Continue with Google",
                            action: { viewModel.signInWithGoogle() },
                            icon: { GoogleLogo() }
                        )

                        AuthButton(
                            icon: "phone.fill",
                            title: "Continue with Phone"
                        ) {
                            viewModel.showPhoneInput = true
                        }

                        #if DEBUG
                        Button(action: { viewModel.devLogin(); dismiss() }) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "hammer.fill")
                                    .font(.system(size: 14))
                                Text("Dev Login (Skip Auth)")
                                    .font(.bodySmall)
                            }
                            .foregroundColor(.textTertiary)
                            .padding(.vertical, Spacing.xs)
                        }
                        #endif
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.lg)

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
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.brandBlue)
                }
            }
        }
        .sheet(isPresented: $viewModel.showPhoneInput) {
            PhoneInputSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showCodeInput) {
            CodeVerificationSheet(viewModel: viewModel)
        }
        .onChange(of: viewModel.isAuthenticated) { isAuthed in
            if isAuthed {
                dismiss()
            }
        }
    }
}

private struct ThemePickerSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    private var selection: Binding<AppTheme> {
        Binding(
            get: { appState.theme },
            set: { appState.updateTheme($0) }
        )
    }

    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.lg) {
                Text("Choose a theme")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                    .padding(.top, Spacing.lg)

                Picker("Theme", selection: selection) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.lg)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    themeHint(
                        title: "Glass",
                        detail: "Always light. Warm glass cards, no black glass."
                    )
                    themeHint(
                        title: "Light",
                        detail: "Clean light UI with solid cards."
                    )
                    themeHint(
                        title: "Dark",
                        detail: "Dark UI with solid cards."
                    )
                }
                .padding(.horizontal, Spacing.lg)

                Spacer()
            }
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.brandBlue)
                }
            }
        }
    }

    private func themeHint(title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .foregroundColor(.brandBlue)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.bodyRegular)
                    .foregroundColor(.textPrimary)

                Text(detail)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.surface)
                if appState.theme.usesGlassMaterial {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(.ultraThinMaterial)
                }
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.cardBorder, lineWidth: 1)
            }
        )
        .glassCardShadow()
    }
}

// MARK: - Settings Section

private struct SettingsSection<Content: View>: View {
    @EnvironmentObject private var appState: AppState
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
                    ZStack {
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(Color.surface)

                        if appState.theme.usesGlassMaterial {
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(.ultraThinMaterial)
                        }

                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.cardBorder, lineWidth: 1)
                    }
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

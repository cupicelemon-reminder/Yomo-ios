//
//  AppState.swift
//  Yomo
//
//  Global application state
//

import Foundation
import Combine

enum AppScreen {
    case welcome
    case onboarding
    case celebration
    case main
}

@MainActor
class AppState: ObservableObject {
    @Published var isPro: Bool = false
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    @Published var currentScreen: AppScreen = .welcome
    @Published var theme: AppTheme = .light

    // Notification snooze navigation
    @Published var pendingSnoozeReminderId: String?
    @Published var pendingSnoozeTitle: String?
    @Published var showPaywall: Bool = false

    var hasPendingSnooze: Bool {
        pendingSnoozeReminderId != nil
    }

    static let shared = AppState()

    private init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        isPro = UserDefaults.standard.bool(forKey: "isPro")
        theme = ThemePreferences.load()

        // Restore auth state
        if let _ = FirebaseAuthStateHelper.currentUser {
            currentScreen = hasCompletedOnboarding ? .main : .onboarding
        } else {
            currentScreen = .welcome
        }
    }

    func updateProStatus(_ isPro: Bool) {
        self.isPro = isPro
        UserDefaults.standard.set(isPro, forKey: "isPro")

        if let userDefaults = UserDefaults(suiteName: Constants.appGroupId) {
            userDefaults.set(isPro, forKey: "isPro")
        }

        // Auto-downgrade to Light if the current theme requires Pro
        if !isPro && theme.requiresPro {
            updateTheme(.light)
        }
    }

    func updateTheme(_ theme: AppTheme) {
        self.theme = theme
        ThemePreferences.save(theme)
    }

    func updateUser(_ user: UserProfile?) {
        self.currentUser = user
        self.isAuthenticated = user != nil

        if let userDefaults = UserDefaults(suiteName: Constants.appGroupId),
           let userId = user?.id {
            userDefaults.set(userId, forKey: "userId")
        }

        if user != nil {
            if hasCompletedOnboarding {
                currentScreen = .main
            } else {
                currentScreen = .onboarding
            }
        } else {
            currentScreen = .welcome
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        currentScreen = .celebration
    }

    func finishCelebration() {
        currentScreen = .main
    }

    func skipOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        currentScreen = .main
    }

    func clearPendingSnooze() {
        pendingSnoozeReminderId = nil
        pendingSnoozeTitle = nil
    }
}

// Helper to check Firebase auth state without importing FirebaseAuth everywhere
import FirebaseAuth

private enum FirebaseAuthStateHelper {
    static var currentUser: User? {
        Auth.auth().currentUser
    }
}

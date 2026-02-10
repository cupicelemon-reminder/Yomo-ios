//
//  YomoApp.swift
//  Yomo
//
//  Main app entry point
//

import SwiftUI
import FirebaseCore

@main
struct YomoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appState: AppState
    @StateObject private var authService: AuthService

    init() {
        // Ensure Firebase is configured before any singletons read Auth state.
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        _appState = StateObject(wrappedValue: AppState.shared)
        _authService = StateObject(wrappedValue: AuthService.shared)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(authService)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Group {
                switch appState.currentScreen {
                case .welcome:
                    WelcomeView()
                        .transition(.opacity)

                case .onboarding:
                    OnboardingView(
                        onComplete: {
                            appState.completeOnboarding()
                        },
                        onSkip: {
                            appState.skipOnboarding()
                        }
                    )
                    .transition(.move(edge: .trailing))

                case .celebration:
                    CelebrationView {
                        appState.finishCelebration()
                    }
                    .transition(.opacity)

                case .main:
                    ReminderListView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: appState.currentScreen)

            // Snooze overlay (when user taps notification)
            if appState.hasPendingSnooze,
               let reminderId = appState.pendingSnoozeReminderId,
               let title = appState.pendingSnoozeTitle {
                SnoozeView(
                    reminderId: reminderId,
                    reminderTitle: title,
                    onDismiss: {
                        appState.clearPendingSnooze()
                    }
                )
                .transition(.move(edge: .bottom))
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: appState.hasPendingSnooze)
                .environmentObject(appState)
            }
        }
        .preferredColorScheme(appState.theme.preferredColorScheme)
        .animation(.easeInOut(duration: 0.25), value: appState.theme)
        .task {
            await SubscriptionService.shared.checkSubscriptionStatus()
            await DeviceSyncService.shared.refreshFCMToken()
        }
    }
}

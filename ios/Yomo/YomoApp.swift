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
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isAuthenticated {
                // TODO: Show ReminderListView when implemented
                Text("Authenticated! Reminder list coming in Day 2")
                    .font(.titleMedium)
            } else {
                WelcomeView()
            }
        }
    }
}

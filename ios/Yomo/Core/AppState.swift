//
//  AppState.swift
//  Yomo
//
//  Global application state
//

import Foundation
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var isPro: Bool = false
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated: Bool = false

    static let shared = AppState()

    private init() {}

    func updateProStatus(_ isPro: Bool) {
        self.isPro = isPro

        // Share with notification extension via UserDefaults
        if let userDefaults = UserDefaults(suiteName: Constants.appGroupId) {
            userDefaults.set(isPro, forKey: "isPro")
        }
    }

    func updateUser(_ user: UserProfile?) {
        self.currentUser = user
        self.isAuthenticated = user != nil

        // Share userId with notification extension
        if let userDefaults = UserDefaults(suiteName: Constants.appGroupId),
           let userId = user?.id {
            userDefaults.set(userId, forKey: "userId")
        }
    }
}

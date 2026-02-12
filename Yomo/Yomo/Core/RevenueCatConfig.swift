//
//  RevenueCatConfig.swift
//  Yomo
//
//  Centralized RevenueCat key resolution and release safety checks.
//

import Foundation

enum RevenueCatConfig {
    private static let keyInfoPlistKey = "REVENUECAT_API_KEY"
    private static let modeInfoPlistKey = "REVENUECAT_STORE_MODE"

    private(set) static var isConfigured: Bool = false

    static func markConfigured() {
        isConfigured = true
    }

    static var apiKey: String {
        if let bundled = Bundle.main.object(forInfoDictionaryKey: keyInfoPlistKey) as? String,
           !bundled.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return bundled
        }
        return Constants.revenueCatAPIKey
    }

    static var storeMode: String {
        (Bundle.main.object(forInfoDictionaryKey: modeInfoPlistKey) as? String) ?? "UNSPECIFIED"
    }

    static var hasAPIKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static var looksLikeTestStoreKey: Bool {
        let lower = apiKey.lowercased()
        return lower.hasPrefix("test_") ||
            lower.contains("test_store") ||
            lower.contains("teststore") ||
            lower.contains("sandbox") ||
            lower.hasPrefix("rc_test_")
    }

    static var isReleaseConfigurationValid: Bool {
        #if DEBUG
        return true
        #else
        return storeMode == "APP_STORE" && !looksLikeTestStoreKey
        #endif
    }
}

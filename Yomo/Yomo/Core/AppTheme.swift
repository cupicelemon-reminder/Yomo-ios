//
//  AppTheme.swift
//  Yomo
//
//  App-wide theme selection (Pro feature)
//

import SwiftUI
import Foundation

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case glass
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .glass: return "Glass"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    /// App-level color scheme override.
    /// Glass is intentionally always light (no "black glass").
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .glass, .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var usesGlassMaterial: Bool {
        self == .glass
    }
}

enum ThemePreferences {
    private static let key = "appTheme"

    static func load() -> AppTheme {
        if let raw = UserDefaults.standard.string(forKey: key),
           let t = AppTheme(rawValue: raw) {
            return t
        }

        if let raw = UserDefaults(suiteName: Constants.appGroupId)?.string(forKey: key),
           let t = AppTheme(rawValue: raw) {
            return t
        }

        return .glass
    }

    static func save(_ theme: AppTheme) {
        UserDefaults.standard.set(theme.rawValue, forKey: key)
        UserDefaults(suiteName: Constants.appGroupId)?.set(theme.rawValue, forKey: key)
    }
}

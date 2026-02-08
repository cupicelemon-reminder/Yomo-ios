//
//  DesignTokens.swift
//  Yomo
//
//  Design system tokens from Yomo_Final_Design_Spec.md
//

import SwiftUI

// MARK: - Colors
extension Color {
    // Brand Colors
    static let brandBlue = Color(hex: "#4A90D9")
    static let brandBlueLight = Color(hex: "#7AB8F5")
    static let brandBlueBg = Color(hex: "#EBF3FC")
    static let checkGold = Color(hex: "#F5A623")

    // Backgrounds
    static let background = Color(hex: "#F8F9FB")
    static let cardGlass = Color.white.opacity(0.72)

    // Text
    static let textPrimary = Color(hex: "#1A1A2E")
    static let textSecondary = Color(hex: "#8E8E93")

    // Status Colors
    static let dangerRed = Color(hex: "#FF3B30")
    static let successGreen = Color(hex: "#34C759")
    static let overdueRed = Color(hex: "#FF3B30")

    // Helper for hex colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
extension Font {
    // Titles
    static let titleLarge = Font.system(size: 28, weight: .bold, design: .default)
    static let titleMedium = Font.system(size: 22, weight: .semibold)
    static let titleSmall = Font.system(size: 17, weight: .semibold)

    // Body
    static let body = Font.system(size: 15, weight: .regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)

    // Utility
    static let caption = Font.system(size: 11, weight: .medium)
    static let button = Font.system(size: 17, weight: .semibold)
    static let snoozeDisplay = Font.system(size: 32, weight: .bold, design: .default)
}

// MARK: - Spacing (8pt grid)
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
}

// MARK: - Shadows
extension View {
    func glassCardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

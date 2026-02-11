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
    static var brandBlueBg: Color {
        switch ThemePreferences.load() {
        case .dark:
            return Color(hex: "#162432")
        case .glass, .light:
            return Color(hex: "#EBF3FC")
        }
    }
    static let checkGold = Color(hex: "#F5A623")
    static var goldBg: Color {
        switch ThemePreferences.load() {
        case .dark:
            return Color(hex: "#2B2416")
        case .glass, .light:
            return Color(hex: "#FFF5E0")
        }
    }

    // Backgrounds
    static var background: Color {
        switch ThemePreferences.load() {
        case .dark:
            return Color(hex: "#0E1116")
        case .glass, .light:
            return Color(hex: "#F8F9FB")
        }
    }

    /// Primary surface fill for cards/sections/sheets.
    static var surface: Color {
        switch ThemePreferences.load() {
        case .dark:
            return Color(hex: "#171B22")
        case .glass:
            return Color.white.opacity(0.72)
        case .light:
            return Color.white
        }
    }

    /// Translucent surface used by the glass theme.
    static var cardGlass: Color {
        switch ThemePreferences.load() {
        case .glass:
            return Color.white.opacity(0.72)
        case .dark:
            return Color(hex: "#171B22")
        case .light:
            return Color.white
        }
    }

    static var cardBorder: Color {
        switch ThemePreferences.load() {
        case .glass:
            return Color.white.opacity(0.3)
        case .dark:
            return Color.white.opacity(0.12)
        case .light:
            return Color.black.opacity(0.06)
        }
    }

    // Text
    static var textPrimary: Color {
        switch ThemePreferences.load() {
        case .dark:
            return Color(hex: "#F4F6FA")
        case .glass, .light:
            return Color(hex: "#1A1A2E")
        }
    }
    static var textSecondary: Color {
        switch ThemePreferences.load() {
        case .dark:
            return Color(hex: "#A9AEBA")
        case .glass, .light:
            return Color(hex: "#8E8E93")
        }
    }
    static var textTertiary: Color {
        switch ThemePreferences.load() {
        case .dark:
            return Color(hex: "#8D93A0")
        case .glass, .light:
            return Color(hex: "#AEAEB2")
        }
    }

    // Status Colors
    static let dangerRed = Color(hex: "#FF3B30")
    static let successGreen = Color(hex: "#34C759")

    // Divider
    static var dividerColor: Color {
        switch ThemePreferences.load() {
        case .dark:
            return Color.white.opacity(0.14)
        case .glass, .light:
            return Color.black.opacity(0.06)
        }
    }

    static var shadowColor: Color {
        switch ThemePreferences.load() {
        case .dark:
            return Color.black.opacity(0.35)
        case .glass, .light:
            return Color.black.opacity(0.06)
        }
    }

    static var shadowElevatedColor: Color {
        switch ThemePreferences.load() {
        case .dark:
            return Color.black.opacity(0.50)
        case .glass, .light:
            return Color.black.opacity(0.10)
        }
    }

    // Helper for hex colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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
    static let titleLarge = Font.system(size: 28, weight: .bold)
    static let titleMedium = Font.system(size: 22, weight: .semibold)
    static let titleSmall = Font.system(size: 17, weight: .semibold)

    static let bodyRegular = Font.system(size: 15, weight: .regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)

    static let caption = Font.system(size: 11, weight: .medium)
    static let button = Font.system(size: 17, weight: .semibold)
    static let pillLabel = Font.system(size: 13, weight: .semibold)
    static let sectionHeader = Font.system(size: 11, weight: .bold)
    static let snoozeDisplay = Font.system(size: 32, weight: .bold)
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
        self.shadow(color: Color.shadowColor, radius: 6, x: 0, y: 2)
    }

    func elevatedShadow() -> some View {
        self.shadow(color: Color.shadowElevatedColor, radius: 12, x: 0, y: 4)
    }
}

// MARK: - Liquid Glass Modifier

/// Reusable glass background treatment applied to all glass-themed surfaces.
/// On iOS 26+ uses native `.glassEffect()`; on older versions falls back to
/// `.ultraThinMaterial` with specular highlight overlays.
struct LiquidGlassBackground: ViewModifier {
    let cornerRadius: CGFloat
    let isGlass: Bool

    func body(content: Content) -> some View {
        content.background(
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.surface)

                if isGlass {
                    glassLayer
                }

                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.cardBorder, lineWidth: 1)
            }
        )
        .glassCardShadow()
    }

    // When Xcode 26+ SDK ships, add an `if #available(iOS 26.0, *)` branch here
    // with `.glassEffect(.regular.interactive, in: RoundedRectangle(...))`.
    private var glassLayer: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
            .overlay(liquidGlassHighlights)
            .overlay(liquidGlassEdge)
    }

    private var liquidGlassHighlights: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.55),
                    Color.white.opacity(0.12),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.screen)

            RadialGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.40), Color.clear]),
                center: .topLeading,
                startRadius: 12,
                endRadius: 220
            )
            .blendMode(.screen)

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.multiply)
        }
        .compositingGroup()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var liquidGlassEdge: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.55),
                        Color.white.opacity(0.08),
                        Color.black.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
            .blendMode(.overlay)
            .opacity(0.75)
            .compositingGroup()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    /// Apply the standard glass card background treatment.
    func liquidGlassBackground(
        cornerRadius: CGFloat = CornerRadius.md,
        isGlass: Bool
    ) -> some View {
        modifier(LiquidGlassBackground(cornerRadius: cornerRadius, isGlass: isGlass))
    }
}

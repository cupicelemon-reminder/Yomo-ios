//
//  AuthButton.swift
//  Yomo
//
//  White outlined auth button with icon (Google, Phone)
//

import SwiftUI

struct AuthButton<Icon: View>: View {
    @EnvironmentObject private var appState: AppState
    let title: String
    let action: () -> Void
    let iconView: Icon

    init(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) where Icon == Image {
        self.title = title
        self.action = action
        self.iconView = Image(systemName: icon)
    }

    init(
        title: String,
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) {
        self.title = title
        self.action = action
        self.iconView = icon()
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                iconView
                    .font(.system(size: 20))
                    .foregroundColor(.textSecondary)
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(.bodyRegular)
                    .foregroundColor(.textPrimary)

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .liquidGlassBackground(isGlass: appState.theme.usesGlassMaterial)
        }
    }
}

// MARK: - Google Logo (Official brand colors via vector path)
struct GoogleLogo: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outerR = min(size.width, size.height) * 0.48
            let innerR = outerR * 0.58
            let barHalf = outerR * 0.18

            let blue = Color(red: 66/255, green: 133/255, blue: 244/255)
            let red = Color(red: 234/255, green: 67/255, blue: 53/255)
            let yellow = Color(red: 251/255, green: 188/255, blue: 5/255)
            let green = Color(red: 52/255, green: 168/255, blue: 83/255)

            // Arc helper (startAngle/endAngle in degrees, 0=right, clockwise)
            func arcPath(start: Double, end: Double) -> Path {
                var p = Path()
                p.addArc(center: center, radius: outerR,
                         startAngle: .degrees(start), endAngle: .degrees(end),
                         clockwise: false)
                p.addArc(center: center, radius: innerR,
                         startAngle: .degrees(end), endAngle: .degrees(start),
                         clockwise: true)
                p.closeSubpath()
                return p
            }

            // Google G arcs (clockwise from top-right gap)
            // Blue: right side ~305 to 45 deg (bottom-right wrapping to top-right)
            context.fill(arcPath(start: -50, end: 50), with: .color(blue))
            // Red: top ~305 to 210 (top-right to top-left)
            context.fill(arcPath(start: -50, end: -140), with: .color(red))
            // Yellow: left ~210 to 145
            context.fill(arcPath(start: -140, end: -225), with: .color(yellow))
            // Green: bottom ~145 to 50
            context.fill(arcPath(start: -225, end: -310), with: .color(green))

            // Blue horizontal bar
            let barRect = CGRect(
                x: center.x - 1,
                y: center.y - barHalf,
                width: outerR + 1,
                height: barHalf * 2
            )
            context.fill(Path(barRect), with: .color(blue))
        }
        .frame(width: 20, height: 20)
    }
}

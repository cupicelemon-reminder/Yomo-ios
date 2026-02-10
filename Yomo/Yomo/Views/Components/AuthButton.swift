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

// MARK: - Google Logo
struct GoogleLogo: View {
    var body: some View {
        Text("G")
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.26, green: 0.52, blue: 0.96), // Blue
                        Color(red: 0.86, green: 0.27, blue: 0.22), // Red
                        Color(red: 0.96, green: 0.73, blue: 0.18), // Yellow
                        Color(red: 0.20, green: 0.66, blue: 0.33)  // Green
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

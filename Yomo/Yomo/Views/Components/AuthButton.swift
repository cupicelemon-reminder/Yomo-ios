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

// MARK: - Google Logo
struct GoogleLogo: View {
    var body: some View {
        Image("google-icon")
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
    }
}

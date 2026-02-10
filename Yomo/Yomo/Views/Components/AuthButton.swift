//
//  AuthButton.swift
//  Yomo
//
//  White outlined auth button with icon (Google, Phone)
//

import SwiftUI

struct AuthButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    var isSystemIcon: Bool = true

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                if isSystemIcon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.textSecondary)
                        .frame(width: 24, height: 24)
                }

                Text(title)
                    .font(.bodyRegular)
                    .foregroundColor(.textPrimary)

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.dividerColor, lineWidth: 1)
                    )
            )
            .glassCardShadow()
        }
    }
}

//
//  GlassCard.swift
//  Yomo
//
//  Reusable glass effect card component
//

import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.cardGlass)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(.ultraThinMaterial)
                    )
            )
            .glassCardShadow()
    }
}

#Preview {
    ZStack {
        Color.background
            .ignoresSafeArea()

        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Sample Card")
                    .font(.titleSmall)
                    .foregroundColor(.textPrimary)

                Text("This is a glass effect card")
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
    }
}

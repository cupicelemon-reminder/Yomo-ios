//
//  GlassCard.swift
//  Yomo
//
//  Reusable glass effect card component
//

import SwiftUI

struct GlassCard<Content: View>: View {
    @EnvironmentObject private var appState: AppState
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Spacing.md)
            .liquidGlassBackground(isGlass: appState.theme.usesGlassMaterial)
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
        .environmentObject(AppState.shared)
    }
}

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
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color.surface)

                    if appState.theme.usesGlassMaterial {
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(.ultraThinMaterial)
                            .overlay(liquidGlassHighlights)
                            .overlay(liquidGlassEdge)
                    }

                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color.cardBorder, lineWidth: 1)
                }
            )
            .glassCardShadow()
    }

    // MARK: - Liquid Glass (approximation)

    /// iOS "Liquid Glass" style uses a combination of blur + specular highlights.
    /// We approximate it here using gradients and blend modes so it compiles on current SDKs.
    private var liquidGlassHighlights: some View {
        ZStack {
            // Soft sheen across the surface.
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

            // Specular hotspot in the top-left.
            RadialGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.40), Color.clear]),
                center: .topLeading,
                startRadius: 12,
                endRadius: 220
            )
            .blendMode(.screen)

            // Slight bottom shadow tint to give thickness.
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.multiply)
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    private var liquidGlassEdge: some View {
        RoundedRectangle(cornerRadius: CornerRadius.md)
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
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
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

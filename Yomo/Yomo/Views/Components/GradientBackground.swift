//
//  GradientBackground.swift
//  Yomo
//
//  Warm Glass background with decorative radial gradients
//

import SwiftUI

struct GradientBackground: View {
    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            // Blue radial glow - top right
            RadialGradient(
                colors: [
                    Color.brandBlue.opacity(0.12),
                    Color.brandBlue.opacity(0.0)
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 300
            )
            .ignoresSafeArea()

            // Gold radial glow - bottom left
            RadialGradient(
                colors: [
                    Color.checkGold.opacity(0.10),
                    Color.checkGold.opacity(0.0)
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 250
            )
            .ignoresSafeArea()
        }
    }
}

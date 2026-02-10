//
//  EmptyStateView.swift
//  Yomo
//
//  Empty reminder list with cute animated mascot
//

import SwiftUI

struct EmptyStateView: View {
    @State private var copyIndex = 0
    @State private var bounce = false
    @State private var waveAngle: Double = 0
    var onCreateTapped: () -> Void

    private let wittyCopies = [
        ("Nothing here yet!", "Tap + to set your first reminder"),
        ("All clear!", "Yomo is patiently waiting for tasks"),
        ("So peaceful...", "Let's add something to remember!"),
        ("Freedom!", "No reminders... but for how long?")
    ]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            // Cute animated logo
            Image("logo-nobg")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(waveAngle))
                .offset(y: bounce ? -8 : 8)
                .animation(
                    .easeInOut(duration: 2).repeatForever(autoreverses: true),
                    value: bounce
                )
                .animation(
                    .easeInOut(duration: 3).repeatForever(autoreverses: true),
                    value: waveAngle
                )

            VStack(spacing: Spacing.sm) {
                Text(wittyCopies[copyIndex].0)
                    .font(.custom("Noteworthy-Bold", size: 20))
                    .foregroundColor(.textPrimary)

                Text(wittyCopies[copyIndex].1)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.xxl)

            Button {
                HapticManager.light()
                onCreateTapped()
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Create a reminder")
                        .font(.bodyRegular)
                }
                .foregroundColor(.brandBlue)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(
                    Capsule()
                        .fill(Color.brandBlue.opacity(0.1))
                )
            }
            .padding(.top, Spacing.sm)

            Spacer()
        }
        .onAppear {
            copyIndex = Int.random(in: 0..<wittyCopies.count)
            bounce = true
            waveAngle = 5
        }
    }
}

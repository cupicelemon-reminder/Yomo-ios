//
//  CelebrationView.swift
//  Yomo
//
//  Screen 3: "You're all set" confirmation with auto-advance
//

import SwiftUI

struct CelebrationView: View {
    @State private var animateCheck = false
    @State private var animateText = false
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: Spacing.lg) {
                Spacer()

                // Gold checkmark circle
                ZStack {
                    Circle()
                        .fill(Color.checkGold)
                        .frame(width: 64, height: 64)

                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(animateCheck ? 1 : 0.3)
                .opacity(animateCheck ? 1 : 0)

                VStack(spacing: Spacing.sm) {
                    Text("You're all set.")
                        .font(.titleLarge)
                        .foregroundColor(.textPrimary)

                    Text("Yomo will remember so you don't have to.")
                        .font(.bodyRegular)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xxl)
                }
                .opacity(animateText ? 1 : 0)
                .offset(y: animateText ? 0 : 16)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateCheck = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                animateText = true
            }
            // Auto-advance after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onContinue()
            }
        }
        .onTapGesture {
            onContinue()
        }
    }
}

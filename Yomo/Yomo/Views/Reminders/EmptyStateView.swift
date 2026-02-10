//
//  EmptyStateView.swift
//  Yomo
//
//  Screen 5: Empty reminder list with witty copy
//

import SwiftUI

struct EmptyStateView: View {
    @State private var copyIndex = 0
    var onCreateTapped: () -> Void

    private let wittyCopies = [
        ("Nothing to remind you about.", "Enjoy the silence... while it lasts."),
        ("Blissfully forgetful.", "Or just really organized. We'll go with that."),
        ("Zero reminders.", "Either you're on top of everything, or..."),
        ("Your slate is clean.", "Time to fill it up with things you'll forget.")
    ]

    var body: some View {
        VStack(spacing: Spacing.md) {
            Spacer()

            VStack(spacing: Spacing.sm) {
                Text(wittyCopies[copyIndex].0)
                    .font(.bodyRegular)
                    .foregroundColor(.textPrimary)

                Text(wittyCopies[copyIndex].1)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.xxl)

            Button {
                onCreateTapped()
            } label: {
                Text("Tap + to create a reminder")
                    .font(.bodyRegular)
                    .foregroundColor(.brandBlue)
            }
            .padding(.top, Spacing.sm)

            Spacer()
        }
        .onAppear {
            copyIndex = Int.random(in: 0..<wittyCopies.count)
        }
    }
}

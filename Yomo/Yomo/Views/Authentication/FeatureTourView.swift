//
//  FeatureTourView.swift
//  Yomo
//
//  Multi-step feature tour shown once to all users
//

import SwiftUI

struct FeatureTourView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPage = 0

    private let steps: [TourStep] = [
        TourStep(
            icon: "mic.fill",
            title: "Create Reminders",
            description: "Type naturally or hold to speak. Yomo's AI understands things like 'Coffee meeting tomorrow 10am'. Tap Parse to let Yomo handle the rest."
        ),
        TourStep(
            icon: "clock",
            title: "Stay on Track",
            description: "Your reminders are organized by time: Today, Tomorrow, This Week, and Later. Overdue items appear at the top in red."
        ),
        TourStep(
            icon: "hand.draw",
            title: "Quick Actions",
            description: "Swipe right to complete a reminder. Swipe left to delete. It's that simple."
        ),
        TourStep(
            icon: "arrow.triangle.2.circlepath",
            title: "Repeat & Recur",
            description: "Set reminders to repeat daily, weekly, or on custom schedules. Never forget recurring tasks."
        ),
        TourStep(
            icon: "sparkles",
            title: "Go Pro",
            description: "Unlock dark & glass themes, custom snooze from notifications, advanced recurrence rules, and cross-device sync."
        )
    ]

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button {
                        completeTour()
                    } label: {
                        Text("Skip")
                            .font(.bodyRegular)
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)

                Spacer()

                // Content
                TabView(selection: $currentPage) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        tourPage(step: step)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                Spacer()

                // Page dots
                HStack(spacing: Spacing.sm) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.brandBlue : Color.textTertiary.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, Spacing.lg)

                // Action button
                PrimaryButton(
                    isLastPage ? "Get Started" : "Next",
                    icon: isLastPage ? "arrow.right" : nil
                ) {
                    if isLastPage {
                        completeTour()
                    } else {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
        }
    }

    private var isLastPage: Bool {
        currentPage == steps.count - 1
    }

    private func tourPage(step: TourStep) -> some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.brandBlueBg)
                    .frame(width: 96, height: 96)

                Image(systemName: step.icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.brandBlue)
            }

            Text(step.title)
                .font(.titleLarge)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            Text(step.description)
                .font(.bodyRegular)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Spacing.xl)
        }
        .padding(.horizontal, Spacing.lg)
    }

    private func completeTour() {
        UserDefaults.standard.set(true, forKey: "hasCompletedFeatureTour")
        dismiss()
    }
}

private struct TourStep {
    let icon: String
    let title: String
    let description: String
}

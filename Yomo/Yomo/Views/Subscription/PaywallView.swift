//
//  PaywallView.swift
//  Yomo
//
//  Screen 10: Subscription paywall with plan selection
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var selectedPlan: PlanType = .annual
    @State private var isRestoring = false

    enum PlanType {
        case monthly
        case annual
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    headerSection

                    // Feature list
                    featureList

                    // Plan cards
                    planCards

                    // CTA Button
                    ctaButton

                    // Fine print
                    finePrint

                    // Restore
                    restoreButton
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .background(Color.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textTertiary)
                            .font(.system(size: 24))
                    }
                }
            }
        }
        .presentationDetents([.large])
        .task {
            await subscriptionService.fetchOfferings()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            Image("logo-nobg")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            Text("Unlock Yomo Pro")
                .font(.titleLarge)
                .foregroundColor(.textPrimary)

            Text("Power features for power users")
                .font(.bodyRegular)
                .foregroundColor(.textSecondary)
        }
        .padding(.top, Spacing.lg)
    }

    // MARK: - Feature List

    private var featureList: some View {
        VStack(spacing: Spacing.md) {
            FeatureRow(
                icon: "clock.arrow.circlepath",
                title: "Custom Snooze",
                description: "Snooze for any minutes from notification"
            )
            FeatureRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Advanced Recurrence",
                description: "Custom intervals, hourly, monthly rules"
            )
            FeatureRow(
                icon: "arrow.triangle.swap",
                title: "Cross-Device Sync",
                description: "Dismiss once, gone everywhere"
            )
            FeatureRow(
                icon: "paintpalette",
                title: "Themes",
                description: "Dark, Light, and Glass themes"
            )
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.cardGlass)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .glassCardShadow()
    }

    // MARK: - Plan Cards

    private var planCards: some View {
        HStack(spacing: Spacing.md) {
            // Monthly
            PlanCard(
                title: "Monthly",
                price: monthlyPrice,
                period: "/month",
                isSelected: selectedPlan == .monthly,
                badge: nil
            ) {
                selectedPlan = .monthly
            }

            // Annual
            PlanCard(
                title: "Annual",
                price: annualPrice,
                period: "/year",
                isSelected: selectedPlan == .annual,
                badge: "SAVE 44%"
            ) {
                selectedPlan = .annual
            }
        }
    }

    // MARK: - CTA

    private var ctaButton: some View {
        PrimaryButton(
            "Start 3-Day Free Trial",
            icon: "sparkles",
            isLoading: subscriptionService.isLoading
        ) {
            purchaseSelectedPlan()
        }
    }

    // MARK: - Fine Print

    private var finePrint: some View {
        VStack(spacing: Spacing.xs) {
            Text("Cancel anytime. You won't be charged during the trial.")
                .font(.caption)
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)

            if let error = subscriptionService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.dangerRed)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button {
            restorePurchases()
        } label: {
            Text("Restore Purchases")
                .font(.bodySmall)
                .foregroundColor(.brandBlue)
        }
        .disabled(isRestoring)
    }

    // MARK: - Prices

    private var monthlyPrice: String {
        if let offering = subscriptionService.currentOffering,
           let monthly = offering.monthly {
            return monthly.localizedPriceString
        }
        return "$2.99"
    }

    private var annualPrice: String {
        if let offering = subscriptionService.currentOffering,
           let annual = offering.annual {
            return annual.localizedPriceString
        }
        return "$19.99"
    }

    // MARK: - Actions

    private func purchaseSelectedPlan() {
        guard let offering = subscriptionService.currentOffering else { return }

        let package: Package?
        switch selectedPlan {
        case .monthly:
            package = offering.monthly
        case .annual:
            package = offering.annual
        }

        guard let pkg = package else { return }

        Task {
            let success = await subscriptionService.purchase(package: pkg)
            if success {
                HapticManager.success()
                dismiss()
            }
        }
    }

    private func restorePurchases() {
        isRestoring = true
        Task {
            let success = await subscriptionService.restorePurchases()
            isRestoring = false
            if success {
                HapticManager.success()
                dismiss()
            }
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.brandBlue)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.titleSmall)
                    .foregroundColor(.textPrimary)

                Text(description)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.checkGold)
                .font(.system(size: 18))
        }
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let title: String
    let price: String
    let period: String
    let isSelected: Bool
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                if let badge {
                    Text(badge)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.checkGold)
                        )
                } else {
                    Spacer().frame(height: 18)
                }

                Text(title)
                    .font(.bodyRegular)
                    .foregroundColor(isSelected ? .brandBlue : .textSecondary)

                Text(price)
                    .font(.titleMedium)
                    .foregroundColor(isSelected ? .textPrimary : .textSecondary)

                Text(period)
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(
                                isSelected ? Color.brandBlue : Color.dividerColor,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
    }
}

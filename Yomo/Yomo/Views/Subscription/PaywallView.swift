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
    @State private var appeared = false

    private let monthlyFallbackPrice = "US$4.99"
    private let annualFallbackPrice = "US$39.99"
    private let annualBadgeText = "Best Value"

    enum PlanType {
        case monthly
        case annual
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    headerSection
                    featureList
                    planCards
                    ctaSection
                    finePrint
                    restoreButton
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .background(GradientBackground())
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                // Gold glow halo
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.checkGold.opacity(0.25),
                                Color.checkGold.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                Image("logo-nobg")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
            }

            Text("Unlock Yomo Pro")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.textPrimary)

            Text("Your reminders, supercharged")
                .font(.bodyRegular)
                .foregroundColor(.textSecondary)
        }
        .padding(.top, Spacing.md)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    // MARK: - Feature List

    private var featureList: some View {
        VStack(spacing: 0) {
            PaywallFeatureRow(
                icon: "clock.arrow.circlepath",
                title: "Custom Snooze",
                description: "Snooze for any duration right from notifications",
                delay: 0.05
            )

            Divider().padding(.leading, 52)

            PaywallFeatureRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Advanced Recurrence",
                description: "Custom intervals, hourly, monthly rules",
                delay: 0.1
            )

            Divider().padding(.leading, 52)

            PaywallFeatureRow(
                icon: "arrow.triangle.swap",
                title: "Cross-Device Sync",
                description: "Dismiss once, gone everywhere",
                delay: 0.15
            )

            Divider().padding(.leading, 52)

            PaywallFeatureRow(
                icon: "paintpalette",
                title: "Themes",
                description: "Dark, Light, and Glass themes",
                delay: 0.2
            )
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.cardGlass)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.cardBorder, lineWidth: 1)
                )
        )
        .glassCardShadow()
    }

    // MARK: - Plan Cards

    private var planCards: some View {
        HStack(spacing: Spacing.md) {
            PaywallPlanCard(
                title: "Monthly",
                price: monthlyPrice,
                period: "/month",
                isSelected: selectedPlan == .monthly,
                badge: nil
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedPlan = .monthly
                }
            }

            PaywallPlanCard(
                title: "Annual",
                price: annualPrice,
                period: "/year",
                isSelected: selectedPlan == .annual,
                badge: annualBadgeText
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedPlan = .annual
                }
            }
        }
        .padding(.top, Spacing.sm)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
        .animation(.easeOut(duration: 0.5).delay(0.25), value: appeared)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: Spacing.xs) {
            PrimaryButton(
                "Start 3-Day Free Trial",
                icon: "sparkles",
                isLoading: subscriptionService.isLoading,
                isDisabled: isPurchaseDisabled
            ) {
                purchaseSelectedPlan()
            }

            Text("Then \(selectedPlanPrice)\(selectedPlanPeriod)")
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .padding(.top, Spacing.sm)
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

            if subscriptionService.currentOffering == nil,
               !subscriptionService.isLoading {
                Button {
                    retryOfferings()
                } label: {
                    Text("Retry loading options")
                        .font(.caption)
                        .foregroundColor(.brandBlue)
                }
            }
        }
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button {
            restorePurchases()
        } label: {
            Text("Restore Purchases")
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .disabled(isRestoring)
        .padding(.top, Spacing.sm)
    }

    // MARK: - Prices

    private var monthlyPrice: String {
        if let offering = subscriptionService.currentOffering,
           let monthly = offering.monthly {
            return monthly.localizedPriceString
        }
        return monthlyFallbackPrice
    }

    private var annualPrice: String {
        if let offering = subscriptionService.currentOffering,
           let annual = offering.annual {
            return annual.localizedPriceString
        }
        return annualFallbackPrice
    }

    private var selectedPlanPrice: String {
        selectedPlan == .annual ? annualPrice : monthlyPrice
    }

    private var selectedPlanPeriod: String {
        selectedPlan == .annual ? "/year" : "/month"
    }

    private var selectedPackage: Package? {
        guard let offering = subscriptionService.currentOffering else { return nil }

        switch selectedPlan {
        case .monthly:
            return offering.monthly
        case .annual:
            return offering.annual
        }
    }

    private var isPurchaseDisabled: Bool {
        selectedPackage == nil
    }

    // MARK: - Actions

    private func purchaseSelectedPlan() {
        guard let pkg = selectedPackage else { return }

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

    private func retryOfferings() {
        Task {
            await subscriptionService.retryFetchOfferings()
        }
    }
}

// MARK: - Feature Row

private struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    @State private var visible = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.brandBlueBg)
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.brandBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.titleSmall)
                    .foregroundColor(.textPrimary)

                Text(description)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, Spacing.sm)
        .opacity(visible ? 1 : 0)
        .offset(x: visible ? 0 : -8)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                visible = true
            }
        }
    }
}

// MARK: - Plan Card

private struct PaywallPlanCard: View {
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
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.checkGold, Color(hex: "#E8941E")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                } else {
                    Spacer().frame(height: 20)
                }

                Text(title)
                    .font(.bodySmall)
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
                    .fill(Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(
                                isSelected ? Color.brandBlue : Color.dividerColor,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? Color.brandBlue.opacity(0.15) : .clear,
                radius: 8, x: 0, y: 2
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

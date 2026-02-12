//
//  SubscriptionService.swift
//  Yomo
//
//  RevenueCat subscription management
//

import Foundation
import RevenueCat

@MainActor
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published var isPro: Bool = false
    @Published var currentOffering: Offering?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private init() {
        isPro = AppState.shared.isPro
    }

    // MARK: - Check Entitlements

    func checkSubscriptionStatus() async {
        guard RevenueCatConfig.hasAPIKey else { return }

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            #if DEBUG
            let activeEntitlements = customerInfo.entitlements.active.keys.sorted().joined(separator: ", ")
            print("[SubscriptionService] Active entitlements: \(activeEntitlements)")
            #endif
            let hasProAccess = customerInfo.entitlements["pro"]?.isActive == true
            updateProStatus(hasProAccess)
        } catch {
            // Fall back to cached status
        }
    }

    // MARK: - Fetch Offerings

    func fetchOfferings() async {
        guard RevenueCatConfig.hasAPIKey else { return }

        isLoading = true
        errorMessage = nil

        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
            if offerings.current == nil {
                errorMessage = "No subscription offerings configured. Please check RevenueCat dashboard."
            }
            isLoading = false
        } catch {
            #if DEBUG
            print("[SubscriptionService] fetchOfferings error: \(error)")
            #endif
            errorMessage = "Failed to load subscription options"
            isLoading = false
        }
    }

    // MARK: - Purchase

    func purchase(package: Package) async -> Bool {
        guard RevenueCatConfig.hasAPIKey else { return false }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await Purchases.shared.purchase(package: package)
            #if DEBUG
            let activeEntitlements = result.customerInfo.entitlements.active.keys.sorted().joined(separator: ", ")
            print("[SubscriptionService] Purchase active entitlements: \(activeEntitlements)")
            #endif
            let hasProAccess = result.customerInfo.entitlements["pro"]?.isActive == true
            if !hasProAccess {
                errorMessage = "Purchase finished, but 'pro' entitlement is not active. Check RevenueCat entitlement/product mapping."
            }
            updateProStatus(hasProAccess)
            isLoading = false
            return hasProAccess
        } catch {
            if let rcError = error as? RevenueCat.ErrorCode, rcError == .purchaseCancelledError {
                // User cancelled — not an error
            } else {
                errorMessage = "Purchase failed. Please try again."
            }
            isLoading = false
            return false
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async -> Bool {
        guard RevenueCatConfig.hasAPIKey else { return false }

        isLoading = true
        errorMessage = nil

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            #if DEBUG
            let activeEntitlements = customerInfo.entitlements.active.keys.sorted().joined(separator: ", ")
            print("[SubscriptionService] Restore active entitlements: \(activeEntitlements)")
            #endif
            let hasProAccess = customerInfo.entitlements["pro"]?.isActive == true
            if !hasProAccess {
                errorMessage = "Restore finished, but 'pro' entitlement is not active."
            }
            updateProStatus(hasProAccess)
            isLoading = false
            return hasProAccess
        } catch {
            errorMessage = "Failed to restore purchases"
            isLoading = false
            return false
        }
    }

    // MARK: - Login with RevenueCat

    func loginUser(userId: String) async {
        guard RevenueCatConfig.hasAPIKey else { return }

        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(userId)
            let hasProAccess = customerInfo.entitlements["pro"]?.isActive == true
            updateProStatus(hasProAccess)
        } catch {
            // Login to RevenueCat failed
        }
    }

    func logoutUser() async {
        guard RevenueCatConfig.hasAPIKey else { return }

        do {
            let customerInfo = try await Purchases.shared.logOut()
            let hasProAccess = customerInfo.entitlements["pro"]?.isActive == true
            updateProStatus(hasProAccess)
        } catch {
            // Logout from RevenueCat failed
        }
    }

    // MARK: - Private

    private func updateProStatus(_ isPro: Bool) {
        self.isPro = isPro
        AppState.shared.updateProStatus(isPro)
    }
}

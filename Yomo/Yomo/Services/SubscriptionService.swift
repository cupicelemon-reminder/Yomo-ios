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
        guard !Constants.revenueCatAPIKey.isEmpty else { return }

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            let hasProAccess = customerInfo.entitlements["pro"]?.isActive == true
            updateProStatus(hasProAccess)
        } catch {
            // Fall back to cached status
        }
    }

    // MARK: - Fetch Offerings

    func fetchOfferings() async {
        guard !Constants.revenueCatAPIKey.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
            isLoading = false
        } catch {
            errorMessage = "Failed to load subscription options"
            isLoading = false
        }
    }

    // MARK: - Purchase

    func purchase(package: Package) async -> Bool {
        guard !Constants.revenueCatAPIKey.isEmpty else { return false }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await Purchases.shared.purchase(package: package)
            let hasProAccess = result.customerInfo.entitlements["pro"]?.isActive == true
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
        guard !Constants.revenueCatAPIKey.isEmpty else { return false }

        isLoading = true
        errorMessage = nil

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            let hasProAccess = customerInfo.entitlements["pro"]?.isActive == true
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
        guard !Constants.revenueCatAPIKey.isEmpty else { return }

        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(userId)
            let hasProAccess = customerInfo.entitlements["pro"]?.isActive == true
            updateProStatus(hasProAccess)
        } catch {
            // Login to RevenueCat failed
        }
    }

    func logoutUser() async {
        guard !Constants.revenueCatAPIKey.isEmpty else { return }

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

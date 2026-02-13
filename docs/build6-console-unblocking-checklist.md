# Build6 Console Unblocking Checklist

Use this checklist before validating TestFlight purchase flow on `1.0 (6)`.

## 1) App Store Connect: Agreements

1. Open App Store Connect > Agreements, Tax, and Banking.
2. Confirm all required agreements are `Active`.
3. Confirm no pending tax or banking tasks.

## 2) App Store Connect: Subscription Metadata

1. Open `yomo_pro_monthly` and `yomo_pro_annual`.
2. Fill all required metadata fields until status leaves `Missing Metadata`.
3. Ensure each product reaches `Ready to Submit` or later.

## 3) App Store Connect: First Subscription Submission Requirement

1. Open app version page `1.0`.
2. In `In-App Purchases and Subscriptions`, explicitly attach:
   - `yomo_pro_monthly`
   - `yomo_pro_annual`
3. Submit app version with these subscriptions attached.

## 4) RevenueCat Mapping Verification

1. Open RevenueCat > Entitlements > `pro`.
2. Confirm products include:
   - `yomo_pro_monthly`
   - `yomo_pro_annual`
3. Open RevenueCat > Offerings > `default`.
4. Confirm iOS monthly and annual packages map to those two Apple product IDs.
5. Confirm app bundle ID is `com.binye.Yomo`.

## 5) Propagation + TestFlight Verification

1. Wait 5–30 minutes (up to 24h in worst case) after metadata/submission updates.
2. Install latest internal TestFlight build.
3. Verify:
   - offerings load successfully
   - purchase succeeds
   - restore purchases succeeds


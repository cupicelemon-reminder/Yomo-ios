# Billing Testing Checklist

This project uses a dual-track billing test strategy:

- Debug/local builds: RevenueCat Test Store
- TestFlight builds: Apple Sandbox (via iOS App Store key)

## Build Configuration Rules

1. `Debug` must use `REVENUECAT_TEST_STORE_API_KEY`.
2. `Release` must use `REVENUECAT_IOS_API_KEY`.
3. Non-Debug builds must keep `REVENUECAT_STORE_MODE=APP_STORE`.
4. External TestFlight / App Store builds must not contain Test Store keys.

The Xcode target includes a `RevenueCat Release Gate` build phase that enforces these checks.

## Test Suite A: RevenueCat Test Store (Debug)

1. Purchase success
- Open paywall and buy monthly/annual package
- Confirm entitlement `pro` becomes active
- Confirm app unlocks Pro features immediately

2. Purchase failure
- Simulate failed purchase in Test Store modal
- Confirm UI returns to normal state and entitlement remains unchanged

3. Purchase cancelled
- Simulate user cancellation
- Confirm no entitlement changes and no persistent error state

4. Restore purchases
- Run restore flow
- Confirm previously granted Test Store entitlement is restored

## Test Suite B: Apple Sandbox (TestFlight)

1. First purchase
- Install TestFlight build using iOS key
- Buy monthly/annual with sandbox test account
- Confirm entitlement activation and UI unlock

2. Restore flow
- Reinstall app or sign in on second device
- Run restore purchases
- Confirm entitlement reactivation

3. Renewal and expiration
- Observe sandbox renewal cycles
- Confirm entitlement remains active during renewals
- Confirm entitlement becomes inactive after expiration/cancellation

## Test Suite C: Mixed Device Scenarios

1. Account switch
- Log out and sign in with another account
- Confirm old entitlement state is not leaked to new user

2. Reinstall consistency
- Delete/reinstall app and sign in again
- Confirm `CustomerInfo` state is recovered correctly

3. Cross-device consistency
- Sign in same user on two devices
- Purchase on device A
- Confirm device B reflects entitlement state after refresh

## Release Cadence Guidance

1. Internal TestFlight: up to 2-4 builds/day for fast iteration.
2. External TestFlight: at most 1 stable build/day.
3. Every new upload must increment `CURRENT_PROJECT_VERSION`.

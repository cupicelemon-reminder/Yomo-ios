# TestFlight Rollout Plan

## Timeline

### 2026-02-11
1. Upload Internal TestFlight build `1.0 (2)` using iOS App Store key.
2. Run Debug billing validation with Test Store for rapid iteration.

### 2026-02-12
1. Run two-device E2E checks:
- Reminder sync (complete/snooze/delete)
- Billing state sync (purchase/restore)
2. If all gates pass, upload External TestFlight build `1.0 (3)`.

### 2026-02-13 and later
1. External TestFlight: maximum 1 stable build/day.
2. Internal TestFlight: up to 2-4 hotfix builds/day.

## Release Gates

1. Build succeeds for `Release`.
2. `RevenueCat Release Gate` passes (no Test Store key in non-Debug).
3. Billing checks in `docs/billing-testing-checklist.md` are green.
4. Core reminder flow checks are green on at least two real devices.

## Working Assumptions

1. iOS is the primary contest submission platform.
2. External builds must use iOS App Store key only.
3. Priority is stable demo quality over adding new features.

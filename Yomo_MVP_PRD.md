# Yomo — MVP Product Requirements Document

**Tagline:** Your moment. Don't miss it.

**Version:** 1.0 MVP
**Date:** February 5, 2026
**Target Competition:** RevenueCat Shipyard Creator Contest (Deadline: Feb 12, 2026)
**Target Creator Brief:** Sam Beckman — Cross-platform Power Reminders

---

## 1. Product Overview

### 1.1 One-Liner

Yomo is a cross-platform reminder app that lets power users create, snooze, and sync reminders across all their devices — beautifully and instantly.

### 1.2 Problem Statement

Sam Beckman is a phone reviewer who constantly switches between iOS and Android. His current reminder app only exists on Android, forcing him to rebuild his entire reminder system every time he switches platforms. Existing cross-platform alternatives fail to deliver all four of his critical requirements simultaneously: custom snoozing from notifications, powerful recurring rules, true cross-device sync, and a polished visual experience.

### 1.3 Solution

Yomo delivers a focused, high-quality reminder experience built around Sam's four pillars:

1. **Smart Creation** — AI-powered natural language input that pre-fills reminder forms from a single sentence
2. **Custom Snooze** — Snooze reminders for any number of minutes (1–60) directly from the iOS notification, without ever opening the app
3. **Advanced Recurrence** — Flexible recurring rules from simple weekly repeats to complex custom intervals
4. **Instant Sync** — Real-time state synchronization across all devices; dismiss once, it disappears everywhere

### 1.4 Target User

Tech-savvy power users aged 18–34 who use multiple devices, value productivity, and care about app design quality. Specifically: Sam Beckman's audience of 600K+ YouTube subscribers — Android/iOS enthusiasts who personalize their devices and seek efficient, well-designed tools.

---

## 2. Platform & Technical Stack

| Component | Technology | Notes |
|---|---|---|
| iOS App (Primary) | Swift / SwiftUI | Full MVP with all features, deep notification integration |
| Android App (Secondary) | Kotlin / Jetpack Compose | Native Android app demonstrating cross-device sync (reminder list + complete) |
| Backend / Database | Firebase Firestore | Real-time listeners for instant sync |
| Push Notifications | Firebase Cloud Messaging (FCM) | Silent pushes to clear notifications cross-device |
| Authentication | Firebase Auth | Google Sign-In + Phone Number (SMS OTP) |
| AI Pre-fill | Lightweight LLM API (Claude Haiku or GPT-4o-mini) | Extracts structured data from natural language input |
| Monetization SDK | RevenueCat | Manages subscriptions and paywall |
| Submission | iOS TestFlight | Single platform submission |

### 2.1 Assumptions

- User is always online (no offline mode in MVP)
- English only (no localization)
- No undo/rollback for completed reminders

---

## 3. Authentication

### 3.1 Supported Methods

- **Google Sign-In** — Primary method, works on both iOS and Android, enables cross-platform account continuity
- **Phone Number (SMS OTP)** — Alternative for users who prefer not to use Google; powered by Firebase Auth phone verification

### 3.2 Flow

1. App launches → Welcome screen with Yomo branding + tagline
2. Two sign-in buttons: "Continue with Google" / "Continue with Phone Number"
3. On successful auth → Create user document in Firestore (if new) → Navigate to main reminders list
4. No email registration, no Apple Sign-In in MVP

---

## 4. Core Features

### 4.1 Smart Reminder Creation (AI Pre-fill)

**Tier:** Free

**Purpose:** Reduce friction when creating reminders. Instead of filling out multiple form fields manually, the user types a natural sentence and the app pre-fills the form.

**Flow:**

1. User taps "+" button → Creation screen appears
2. At the top: a single text input field with placeholder: *"e.g. Water plants every Tuesday at 3pm"*
3. User types a sentence and taps "Parse" (or hits return)
4. App sends the input to a lightweight LLM API with a structured prompt
5. API returns JSON: `{ title, date, time, recurrence_type, recurrence_rule }`
6. App pre-fills the editable form below with the extracted data
7. User reviews, adjusts if needed, and taps "Save"

**Fallback:** If the API call fails or returns unexpected data, the form remains empty and the user fills it manually. No error toast needed — the form is always accessible.

**LLM Prompt Design (simplified):**

```
Extract reminder details from the user input. Return JSON only:
{
  "title": "string",
  "date": "YYYY-MM-DD or null",
  "time": "HH:mm or null",
  "recurrence_type": "none" | "daily" | "weekly" | "custom",
  "recurrence_rule": {
    "interval": number,
    "unit": "hour" | "day" | "week" | "month",
    "days_of_week": ["mon","tue",...] or null,
    "time_range_start": "HH:mm" or null,
    "time_range_end": "HH:mm" or null,
    "based_on_completion": boolean
  } or null
}
Input: "{user_input}"
```

### 4.2 Reminder Form (Editable)

**Tier:** Free (basic fields), Pro (advanced recurrence)

The form is the final confirmation step after AI pre-fill, or the direct entry point for manual creation.

**Fields:**

| Field | Type | Required | Notes |
|---|---|---|---|
| Title | Text input | Yes | The reminder content |
| Date | Date picker | Yes | Defaults to today |
| Time | Time picker (scroll wheel) | Yes | Defaults to next hour |
| Notes | Text input (multi-line) | No | Optional details |
| Recurrence | Selector (see §4.4) | No | Defaults to "None" |

**Interaction Design:**

- The form appears as a half-sheet card sliding up from the bottom
- Keyboard auto-opens focused on the Title field
- Date and Time pickers are inline scroll wheels (iOS native style), not separate screens
- Tapping "Save" dismisses the card and schedules the local notification + writes to Firestore

### 4.3 Reminder List (Main Screen)

**Tier:** Free

The home screen shows all active reminders, sorted by next trigger time (nearest first).

**Each reminder card displays:**

- Title (primary text, bold)
- Next trigger date & time (secondary text)
- Recurrence indicator icon (if recurring)
- Swipe actions:
  - **Swipe right → Complete** (mark as done, remove from list, cancel notification)
  - **Swipe left → Delete** (permanently remove)
- **Tap → Open edit form** (same form as creation, pre-filled with current values)

**Empty State:** A centered message: *"No reminders yet. Tap + to create one."*

**Completed Reminders:** Not shown on the main list in MVP. Completed reminders are marked as `status: completed` in Firestore for potential future history view.

### 4.4 Recurrence Rules

#### 4.4.1 Basic Recurrence (Free)

Displayed as a row of pill buttons:

```
[ None ] [ Daily ] [ Weekly ]
```

- **None** — One-time reminder
- **Daily** — Repeats every day at the same time
- **Weekly** — Reveals a row of day-of-week toggle buttons (Mon–Sun), multi-select allowed

#### 4.4.2 Advanced Recurrence (Pro)

When user selects "Custom" (4th pill button with a ⭐ Pro badge):

**If user is not Pro → Trigger paywall (see §5)**

**If user is Pro → Expand the custom recurrence editor:**

**Row 1 — Frequency:**
```
Every [ 3 ] [ days ▾ ]
```
- Number input: integer ≥ 1
- Unit dropdown: `hour` / `day` / `week` / `month`

**Conditional Row 2 (based on unit selected):**

| Unit | Additional UI |
|---|---|
| Hour | Time range picker: "From [09:00] to [18:00]" — two time wheels |
| Day | (no additional UI) |
| Week | Day-of-week toggles (Mon–Sun) |
| Month | "On the [ 2nd ▾ ] [ Tuesday ▾ ]" — two dropdowns |

**Row 3 — Completion-based toggle:**
```
[ ○ ] Repeat from completion date
```
When ON: the next occurrence is calculated as N units after the task is marked complete, not from the original schedule. Label below the toggle: *"Next reminder will be scheduled X [units] after you complete this one."*

### 4.5 Custom Snooze from Notification

**Tier:** Pro

This is the flagship differentiator. Users can snooze a reminder for a precise number of minutes without opening the app.

#### 4.5.1 iOS Notification Content Extension

**Implementation:** A custom Notification Content Extension that renders when the user long-presses (or pulls down) a Yomo notification.

**UI inside the expanded notification:**

```
┌─────────────────────────────────────┐
│  🔔 Water the plants               │
│                                     │
│  Snooze for:                        │
│                                     │
│  ◄━━━━━━━━━━●━━━━━━━━━━━━━━━━━━━━► │
│           22 min                    │
│                                     │
│  [ Snooze ]           [ Complete ]  │
└─────────────────────────────────────┘
```

- **Slider (UISlider):** Range 1–60 minutes, integer steps. The current value is displayed as a large, clear label (e.g., "22 min") that updates in real-time as the user drags.
- **Default slider position:** 15 minutes (a reasonable middle ground)
- **"Snooze" button:** Reschedules the notification for `now + selected minutes`. Updates Firestore with new trigger time. Syncs to all devices.
- **"Complete" button:** Marks the reminder as done. Removes from all devices. Syncs via Firestore.

**Critical behaviors:**

- Tapping the notification (not long-pressing) opens the app and navigates to the reminder detail with snooze options as a fallback
- After snoozing or completing, the notification dismisses itself
- The snooze action triggers a Firestore write, which triggers FCM silent pushes to all other devices to clear/update their notifications

#### 4.5.2 In-App Snooze (Fallback)

If the user accidentally taps into the app from a notification:

- App opens directly to that reminder
- Shows a snooze input field (text field, numeric keyboard, 1–60 range)
- "Snooze" and "Complete" buttons

This is a minimal fallback — not the primary snooze experience in MVP.

### 4.6 Cross-Device Real-Time Sync

**Tier:** Pro

#### 4.6.1 Data Sync (Firestore Real-Time Listeners)

- Every reminder is a document in Firestore under `users/{userId}/reminders/{reminderId}`
- All connected devices run a real-time snapshot listener on this collection
- Any create / edit / complete / delete operation writes to Firestore first, then updates local UI
- All other devices receive the change within milliseconds via the listener and update their UI immediately

**Reminder Document Schema:**

```json
{
  "id": "auto-generated",
  "title": "Water the plants",
  "notes": "",
  "triggerDate": "2026-02-06T15:00:00Z",
  "recurrence": {
    "type": "custom",
    "interval": 3,
    "unit": "day",
    "daysOfWeek": null,
    "monthOrdinal": null,
    "monthDay": null,
    "timeRangeStart": null,
    "timeRangeEnd": null,
    "basedOnCompletion": false
  },
  "status": "active",
  "snoozedUntil": null,
  "createdAt": "2026-02-05T10:00:00Z",
  "updatedAt": "2026-02-05T10:00:00Z",
  "completedAt": null
}
```

#### 4.6.2 Notification State Sync (FCM Silent Push)

**The "60 phones on a desk" scenario:** When the user acts on a reminder on Device A, all other devices must instantly reflect that change — including clearing or updating system notifications.

**Flow — User completes a reminder on Device A:**

1. Device A writes `status: "completed"` to Firestore
2. Cloud Function triggers on Firestore write
3. Cloud Function sends FCM silent push to all other registered devices of that user
4. Each receiving device:
   - Receives silent push with `{ reminderId, action: "completed" }`
   - Uses `UNUserNotificationCenter.removePendingNotificationRequests` (iOS) or `NotificationManager.cancel()` (Android) to clear the local notification for that reminder
   - Firestore listener also updates the in-app UI

**Flow — User snoozes a reminder on Device A:**

1. Device A writes new `triggerDate` and `snoozedUntil` to Firestore
2. Cloud Function sends FCM silent push with `{ reminderId, action: "snoozed", newTriggerDate }`
3. Each receiving device:
   - Cancels the old local notification
   - Schedules a new local notification at the updated trigger time
   - Updates in-app UI via Firestore listener

**Device Registration:**

- On app launch (after auth), register the device's FCM token in Firestore under `users/{userId}/devices/{deviceId}`
- Include: `fcmToken`, `platform` (ios/android), `lastActiveAt`
- Update `lastActiveAt` on each app launch

---

## 5. Monetization

### 5.1 Tier Structure

| Feature | Free | Pro |
|---|---|---|
| Create / edit / delete reminders | ✅ | ✅ |
| AI natural language pre-fill | ✅ | ✅ |
| Basic recurrence (Daily, Weekly) | ✅ | ✅ |
| Single-device notifications | ✅ | ✅ |
| Custom snooze from notification (Slider) | ❌ | ✅ |
| Advanced recurrence (Custom intervals) | ❌ | ✅ |
| Cross-device real-time sync | ❌ | ✅ |
| Theme switching (Dark / Light / Glass) | ❌ | ✅ |

### 5.2 Pricing

- **Monthly:** $2.99/month
- **Annual:** $19.99/year (save 44%)
- **Free Trial:** 3-day free trial on both plans

### 5.3 Paywall Trigger Points

The paywall is **not** shown at launch or during onboarding. Users experience the free tier fully before encountering it.

**Trigger moments:**

1. **Tapping "Custom" recurrence pill** → Paywall appears
2. **Long-pressing a notification and tapping "Snooze"** → If not Pro, the snooze slider is replaced with a paywall prompt: *"Upgrade to Pro to snooze from notifications"* with a CTA button
3. **Signing in on a second device** → After auth, if reminders exist but sync is not enabled, show: *"Your reminders are waiting. Upgrade to Pro to sync across devices."*
4. **Tapping theme options** → Paywall appears

### 5.4 Paywall UI

A half-sheet modal with:

- Yomo logo + "Unlock Yomo Pro"
- Feature list with icons (Custom Snooze, Advanced Recurrence, Cross-Device Sync, Themes)
- Two plan cards: Monthly / Annual (annual highlighted as "Best Value")
- "Start 3-Day Free Trial" CTA button
- Fine print: "Cancel anytime. You won't be charged during the trial."
- "Restore Purchases" link at the bottom

### 5.5 RevenueCat Integration

- RevenueCat SDK handles all subscription logic, receipt validation, and entitlement management
- On app launch: check RevenueCat entitlements → set local `isPro` flag
- Paywall offerings configured in RevenueCat dashboard
- TestFlight builds use Sandbox environment (no real charges during review)

---

## 6. Information Architecture

```
App Launch
├── Not authenticated → Welcome Screen
│   ├── Continue with Google
│   └── Continue with Phone Number
│
└── Authenticated → Reminder List (Home)
    ├── [+] → Create Reminder
    │   ├── AI Input Field → Parse → Pre-filled Form
    │   └── Manual Form Entry
    │       ├── Title
    │       ├── Date Picker
    │       ├── Time Picker
    │       ├── Notes (optional)
    │       └── Recurrence Selector
    │           ├── None / Daily / Weekly (Free)
    │           └── Custom (Pro → Paywall if needed)
    │
    ├── Tap Reminder → Edit Form (same as create)
    ├── Swipe Right → Complete
    ├── Swipe Left → Delete
    │
    ├── Settings (gear icon)
    │   ├── Account (email/phone, sign out)
    │   ├── Subscription (manage / upgrade)
    │   ├── Theme (Light / Dark / Glass ⭐Pro)
    │   └── About
    │
    └── [Notification interaction - outside app]
        └── Long-press notification → Snooze Slider + Complete (Pro)
```

---

## 7. Visual Design Direction

### 7.1 MVP Phase: Clean Flat

For initial development, use a clean flat design system to ship features fast:

- White/off-white background, dark text
- System font (SF Pro on iOS)
- Rounded-corner cards with light shadows
- Accent color: soft blue (adjustable later)
- Dark mode support via iOS system toggle

### 7.2 Polish Phase: Glassmorphism (Post-Feature-Complete)

After all features work, layer on visual polish inspired by Sam Beckman's aesthetic:

- Frosted glass card backgrounds (UIVisualEffectView with blur)
- Subtle translucency and depth
- Muted pastel accent palette
- Refined micro-animations (card transitions, swipe feedback, completion celebrations)
- Material You dynamic theming on Android shell

---

## 8. Firestore Data Model

```
firestore-root/
├── users/
│   └── {userId}/
│       ├── profile: { displayName, email, phone, createdAt }
│       ├── subscription: { plan, status, expiresAt } // managed via RevenueCat webhook
│       ├── devices/
│       │   └── {deviceId}: { fcmToken, platform, lastActiveAt }
│       └── reminders/
│           └── {reminderId}: { ...reminder document schema from §4.6.1 }
```

---

## 9. Cloud Functions

| Function | Trigger | Purpose |
|---|---|---|
| `onReminderUpdate` | Firestore `onWrite` on `reminders/{id}` | Sends FCM silent push to all other devices of the user when a reminder's status or triggerDate changes |
| `onDeviceCleanup` | Scheduled (daily) | Removes device tokens with `lastActiveAt` older than 30 days to prevent notification noise on retired devices |

---

## 10. Out of Scope (MVP)

The following are explicitly excluded from MVP development:

- Undo / rollback completed reminders
- Offline mode / conflict resolution
- Widgets (iOS or Android)
- Location-based reminders
- Voice input / read-aloud
- Dynamic Island / Live Activities
- Theme store / community features
- Import/export (from Google Calendar, Apple Reminders, etc.)
- NLP in non-English languages
- Sign in with Apple / Email registration
- Custom notification sounds
- Reminder categories / tags / priority levels
- Search / filter on reminder list
- Multi-language support

---

## 11. Development Priority & Rough Timeline

Given 6–7 remaining days, suggested build order:

| Day | Focus | Deliverable |
|---|---|---|
| Day 1 | Project setup + Firebase config + Auth | App skeleton, Google + Phone login working, Firestore connected |
| Day 2 | Reminder CRUD + Firestore | Create / edit / delete / complete reminders, real-time list updates |
| Day 3 | Local notifications + Notification Content Extension (Snooze Slider) | Notifications fire on time, long-press shows custom snooze UI |
| Day 4 | Recurrence engine + Advanced recurrence UI | All recurrence types working, next-trigger-date calculation correct |
| Day 5 | Cross-device sync (FCM silent push + Cloud Functions) | Complete/snooze on one device clears notifications on others |
| Day 6 | RevenueCat integration + Paywall + AI pre-fill | Subscription flow end-to-end, AI input working |
| Day 7 | Visual polish + Android native app + TestFlight build | Glassmorphism pass, Kotlin/Compose Android sync demo, final submission build |

**Risk buffer:** Days 6–7 are partially flex. If sync or notifications take longer, AI pre-fill and visual polish can be simplified.

---

## 12. Success Metrics (Competition Judging Alignment)

| Judging Criteria (Weight) | How Yomo Addresses It |
|---|---|
| **Audience Fit (30%)** | Built specifically for Sam's 4 stated requirements; targets tech-savvy power users who switch platforms |
| **User Experience (25%)** | AI pre-fill reduces creation friction; notification snooze slider eliminates app-switching; swipe gestures for fast task management |
| **Monetization Potential (20%)** | Clear Free/Pro split; Pro features map directly to Sam's must-haves; RevenueCat-powered subscription with trial |
| **Innovation (15%)** | Custom minute-precise snooze from notification (rare in market); AI-powered reminder creation; instant cross-device notification clearing |
| **Technical Quality (10%)** | Native Swift for iOS performance; Firebase real-time architecture; clean separation of concerns |

---

*End of PRD — Yomo v1.0 MVP*

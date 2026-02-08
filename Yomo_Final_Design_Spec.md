# Yomo — Final Design Specification

**App Name:** Yomo
**Tagline:** Your moment. Don't miss it.
**Platform:** iOS (Swift/SwiftUI) primary, Android (RN+Expo) secondary shell
**Version:** 1.0 MVP — Final
**Date:** February 8, 2026

---

## Table of Contents

1. Design Philosophy
2. Global Design Tokens
3. Screen Specifications (10 screens)
4. Component Library
5. Animation & Haptics Specification
6. Stitch Prompt Reference

---

## 1. Design Philosophy

### Aesthetic Direction: "Warm Glass"

Yomo combines glassmorphism's depth and premium feel with a warm, friendly personality. It is not cold or sterile — it's the kind of app that feels like a reliable friend who happens to be beautifully organized.

**Key principles:**

- **Airy and spacious** — generous whitespace, content breathes, never cramped
- **Glass cards float** — semi-transparent frosted cards hover above a light background, creating subtle depth without heaviness
- **Blue at interaction points only** — the brand blue (#4A90D9) appears only where the user interacts (buttons, selected states, links), keeping the overall palette calm
- **Gold for achievement** — the warm gold (#F5A623) from the logo's checkmark appears only at moments of completion and success
- **Personality through words, not visuals** — the UI is a clean stage; personality comes through copywriting and micro-animations, not visual clutter
- **Logo stays in its lane** — the Yomo mascot character appears only on the Welcome screen and Settings; all other screens are clean of character illustrations

### Reference Mood

"Todoist's warmth meets Apple Weather's glass cards — clean, modern, iOS-native, but with a smile."

---

## 2. Global Design Tokens

### 2.1 Color Palette

| Token | Hex / Value | Role | Where It Appears |
|---|---|---|---|
| `brand-blue` | #4A90D9 | Primary interaction color | FAB, CTA buttons, selected pills, active toggles, links, slider fill |
| `brand-blue-light` | #7AB8F5 | Secondary blue | Recurrence icon, slider track accent, hover states |
| `brand-blue-bg` | #EBF3FC | Input/field background | Text fields, unselected pills, number inputs |
| `check-gold` | #F5A623 | Achievement / reward | Completion checkmark, Pro ⭐ badge, "SAVE 44%" badge, onboarding celebration circle |
| `background` | #F8F9FB | Screen background | All screens (solid, no pattern) |
| `card-glass` | rgba(255, 255, 255, 0.72) | Glass card fill | Reminder cards, bottom sheets, settings sections |
| `card-border` | rgba(255, 255, 255, 0.3) | Glass card edge | 1px border on all glass cards |
| `text-primary` | #1A1A2E | Primary text | Titles, reminder names, main content |
| `text-secondary` | #8E8E93 | Secondary text | Timestamps, subtitles, placeholders, helper text |
| `text-tertiary` | #AEAEB2 | Tertiary text | Disabled states, inactive labels, divider text |
| `danger-red` | #FF3B30 | Destructive actions | Delete swipe, overdue badge/section header, error states |
| `success-green` | #34C759 | Positive actions | Complete swipe background, "Active ✓" badge in settings |
| `divider` | rgba(0, 0, 0, 0.06) | Separators | Lines between settings rows, section dividers |
| `onboarding-gradient-blue` | #EBF3FC → transparent | Background decoration | Radial gradient on onboarding + paywall screens only |
| `onboarding-gradient-gold` | #FFF5E0 → transparent | Background decoration | Radial gradient on onboarding + paywall screens only |

### 2.2 Typography

All fonts: **SF Pro** (iOS system font family).

| Style Name | Font | Weight | Size | Line Height | Usage |
|---|---|---|---|---|---|
| `title-large` | SF Pro Display | Bold | 28pt | 34pt | Screen title "Yomo" on main list |
| `title-medium` | SF Pro Display | Semibold | 22pt | 28pt | Section titles, paywall title, celebration text |
| `title-small` | SF Pro Text | Semibold | 17pt | 22pt | Reminder card title, feature names in paywall |
| `body` | SF Pro Text | Regular | 15pt | 20pt | Body text, form labels, descriptions |
| `body-small` | SF Pro Text | Regular | 13pt | 18pt | Timestamps, helper text, secondary info |
| `caption` | SF Pro Text | Medium | 11pt | 13pt | Badges, section group headers (OVERDUE, TODAY), fine print |
| `button` | SF Pro Text | Semibold | 17pt | 22pt | Primary CTA button text |
| `button-small` | SF Pro Text | Medium | 15pt | 20pt | Secondary buttons, pill labels, Parse button |
| `snooze-display` | SF Pro Display | Bold | 32pt | 38pt | Snooze minute number in notification extension |

### 2.3 Spacing (8pt Grid)

| Token | Value | Usage |
|---|---|---|
| `space-xs` | 4pt | Badge internal padding |
| `space-sm` | 8pt | Between icon and text, between cards in same section, between small elements |
| `space-md` | 16pt | Card internal padding (all sides), between form fields |
| `space-lg` | 24pt | Between section groups, between major UI blocks |
| `space-xl` | 32pt | Screen horizontal margins (left/right edge to content) |
| `space-2xl` | 48pt | Top safe area to first content element |

### 2.4 Corner Radius

| Element | Radius |
|---|---|
| Reminder cards | 12px |
| Primary buttons (Save, CTA) | 12px |
| Bottom sheets (top corners only) | 16px |
| Pill buttons (recurrence, Parse) | 20px (fully rounded) |
| Input fields | 10px |
| FAB button | 50% (circle) |
| Badges (SAVE 44%, Pro, Overdue) | 6px |
| Day-of-week circles | 50% (circle) |

### 2.5 Glass Effect Specification

**Glass Card (reminder cards, bottom sheets, settings sections):**
```
Background:  rgba(255, 255, 255, 0.72)
Backdrop blur: 20px
Border:      1px solid rgba(255, 255, 255, 0.3)
Box shadow:  0 2px 12px rgba(0, 0, 0, 0.06)
```

**Elevated elements (FAB, modals over content):**
```
Box shadow:  0 4px 20px rgba(0, 0, 0, 0.10)
```

**Subtle shadow (settings rows, secondary elements):**
```
Box shadow:  0 1px 4px rgba(0, 0, 0, 0.04)
```

---

## 3. Screen Specifications

---

### Screen 1: Welcome / Login

**Purpose:** First impression. Clean, confident, approachable.

**Background:** `background` (#F8F9FB) with two decorative radial gradients:
- Top-right: `onboarding-gradient-blue`, 300pt diameter, positioned at (screen_width + 40, -60)
- Bottom-left: `onboarding-gradient-gold`, 250pt diameter, positioned at (-80, screen_height - 100)

**Layout (top to bottom, centered):**

| Element | Spec |
|---|---|
| Top spacer | ~40% from top of safe area |
| Yomo Logo | 120 × 120pt, centered |
| Spacer | `space-md` (16pt) |
| Tagline line 1 | "Your moment." — `title-medium`, `text-primary`, centered |
| Tagline line 2 | "Don't miss it." — `body`, `text-secondary`, centered |
| Spacer | `space-2xl` (48pt) |
| Google button | Full width minus 2 × `space-xl`, height 52pt, white bg, 1px `divider` border, 12px radius, Google icon 20pt left-aligned, text "Continue with Google" `body` `text-primary` centered |
| Spacer | `space-sm` (8pt) |
| Phone button | Same style, phone icon, text "Continue with Phone" |
| Spacer | `space-lg` (24pt) |
| Legal text | "By continuing, you agree to our Terms of Service & Privacy Policy" — `caption`, `text-tertiary`, centered, "Terms of Service" and "Privacy Policy" as `brand-blue` links |

**Animations:**
- Logo: opacity 0→1, 0.6s ease-out
- Tagline: opacity 0→1, 0.3s delay, 0.4s ease-out
- Buttons: translateY 20→0 + opacity 0→1, staggered 0.1s, 0.4s ease-out

---

### Screen 2: Set Your First Reminder (Interactive Onboarding)

**Purpose:** User creates their first reminder during onboarding. No feature slides.

**Background:** Same gradient decoration as Welcome screen (continuous visual flow).

**Navigation:** Back arrow (←) top-left, `text-secondary`

**Layout (top to bottom):**

| Element | Spec |
|---|---|
| Top spacer | `space-2xl` |
| Headline | "Let's set your first reminder." — `title-medium`, `text-primary`, left-aligned |
| Subhead | "Just type what to remember." — `body`, `text-secondary`, left-aligned |
| Spacer | `space-lg` |
| AI input card | Glass card style, min height 80pt, internal padding `space-md`, placeholder "e.g. Water plants every Tuesday at 3pm" `text-tertiary` `body` |
| Spacer | `space-md` |
| Parse button | Centered, pill shape (20px radius), `brand-blue` bg, white text "✨ Parse Reminder" `button-small`, height 44pt, horizontal padding 24pt |
| Spacer | flex (pushes Skip to bottom) |
| Skip link | "Skip for now →" — `body-small`, `text-secondary`, centered |
| Bottom spacer | `space-lg` |

**Parse loading state:**
- Parse button text changes to "..." with subtle pulse animation
- Thin progress line (2pt height, `brand-blue`) appears below AI input card, animates left→right, 1.5s linear repeat

**After parse success → Pre-filled confirmation card:**

The AI input collapses to one line (showing user's original text). Below it, a confirmation card slides in:

| Element | Spec |
|---|---|
| Header | "Nice! Here's what I got:" — `title-small`, `text-primary` |
| Card | Glass card containing: |
| — Title row | 📝 icon + parsed title — `title-small`, `text-primary` |
| — Date/Time row | 📅 icon + date, ⏰ icon + time — `body`, `text-secondary` |
| — Repeat row | 🔄 icon + recurrence description — `body`, `brand-blue` |
| — Helper | "Tap any field to adjust." — `caption`, `text-tertiary` |
| Spacer | `space-lg` |
| Save button | Full width, 52pt height, `brand-blue` bg, white text "Save my first reminder" `button`, 12px radius |

**Card entry animation:** spring from below (translateY 40→0, scale 0.97→1.0, 0.5s, damping 0.8)

---

### Screen 3: All Set Celebration

**Purpose:** Emotional reward. Brief, memorable, then auto-advances.

**Background:** Same gradient decoration as previous onboarding screens.

**Layout (vertically and horizontally centered):**

| Element | Spec |
|---|---|
| Checkmark circle | 64pt diameter, `check-gold` fill (#F5A623), white checkmark stroke inside |
| Spacer | `space-lg` |
| Title | "You're all set." — `title-medium`, `text-primary`, centered |
| Subtitle | "Yomo will remember so you don't have to." — `body`, `text-secondary`, centered |

**Nothing else on this screen.** No buttons, no footer, no additional text.

**Animations:**
- Checkmark: stroke path draw animation, 0.4s ease-in-out
- Circle: scale pulse 1.0→1.08→1.0, 0.3s, starts after stroke completes
- Text: opacity 0→1, 0.2s delay after circle pulse
- **Haptic:** `UIImpactFeedbackGenerator(.medium)` when checkmark completes
- Auto-advance: cross-fade to main list after 2 seconds total

---

### Screen 4: My Reminders (Main List / Home)

**Purpose:** The daily driver. Scannable, fast, calm.

**Background:** `background` (#F8F9FB) solid. No decorative elements.

**Navigation elements:**
- Top-left: "Yomo" — `title-large`, `text-primary`
- Top-right: Settings gear icon — SF Symbol `gearshape`, 22pt, `text-secondary`
- Bottom-right: FAB — 56pt circle, `brand-blue` bg, white "+" icon 24pt, elevated shadow
- **No tab bar. No bottom navigation.**

**Content structure:**

Reminders grouped by time, each group has:
- **Section header:** uppercase `caption`, letter-spacing 0.5pt
  - "OVERDUE" — `danger-red`
  - "TODAY" / "TOMORROW" / "THIS WEEK" / "UPCOMING" — `text-secondary`
- **Spacing:** `space-lg` above each section header, `space-sm` below header to first card, `space-sm` between cards

**Reminder card anatomy:**

```
┌──────────────────────────────────────────────────┐
│  (space-md padding all sides)                    │
│                                                  │
│  ●  Reminder title here              3:00 PM    │
│                                            🔄   │
│                                                  │
└──────────────────────────────────────────────────┘
```

| Element | Spec |
|---|---|
| Card | Glass card style, 12px radius, full width minus 2 × `space-xl` horizontal margin |
| Status dot | 8pt diameter circle, left-aligned. Active: `brand-blue`. Overdue: `danger-red` |
| Title | `title-small`, `text-primary`, single line, truncate with ellipsis |
| Time | `body-small`, `text-secondary`, right-aligned |
| Recurrence icon | SF Symbol `arrow.clockwise`, 12pt, `brand-blue-light`, below time (only if recurring) |

**Swipe actions:**

| Direction | Action | Background Color | Icon | Haptic |
|---|---|---|---|---|
| Right swipe | Complete | `success-green` | SF Symbol `checkmark`, white, 22pt | `.light` impact |
| Left swipe | Delete | `danger-red` | SF Symbol `trash`, white, 22pt | `.light` impact |

**Right swipe complete animation sequence:**
1. Card text gets strikethrough (0.2s)
2. Card slides right off screen + height collapses (0.3s)
3. If recurring: new card for next occurrence animates into correct position (translateY 16→0, opacity 0→1, 0.3s spring)

**FAB press animation:** scale 1.0→0.92→1.0, 0.2s spring

---

### Screen 5: No Reminders Yet (Empty State)

**Same frame as Screen 4** (same header, same gear icon, same FAB position). The only difference is the content area.

**Empty state content (vertically centered in content area):**

| Element | Spec |
|---|---|
| Copy line 1 | Rotating message — `body`, `text-secondary`, centered |
| Copy line 2 | Continuation — `body`, `text-tertiary`, centered |
| Spacer | `space-md` |
| CTA | "Tap + to create a reminder" — `caption`, `brand-blue`, centered |

**Rotating copy options (randomly selected per session):**

1. "Nothing to remind you about." / "Enjoy the silence... while it lasts."
2. "All clear. Either you're incredibly productive," / "or incredibly forgetful about adding reminders."
3. "Zero reminders. Sam Beckman would be impressed." / "Or concerned."
4. "You did it. Everything. All of it." / "Until tomorrow."

---

### Screen 6: New Reminder (Create — Bottom Sheet)

**Trigger:** Tap FAB "+" on main list.

**Container:** Bottom sheet sliding up from bottom.
- Top corners: 16px radius
- Glass card style background with backdrop blur
- Drag handle: centered, 36pt wide × 4pt height, `text-tertiary`, 8pt from top
- Height: dynamic (~75% of screen)

**Layout (top to bottom):**

| Order | Element | Spec |
|---|---|---|
| 1 | Drag handle | 36 × 4pt, `text-tertiary`, centered |
| 2 | Sheet title | "New Reminder" — `title-medium`, `text-primary`, centered (optional, can omit for cleaner look) |
| 3 | AI input field | Glass card style, min height 60pt, `space-md` internal padding, placeholder "Type naturally: 'Coffee with Julian at Blue Bottle tomorrow 10am'" `text-tertiary` `body`. Focus state: 1px `brand-blue` border |
| 4 | Parse button | Centered below input, pill shape, `brand-blue` bg, white text "✨ Parse" `button-small`, height 36pt, padding 24pt horizontal |
| 5 | Divider | Thin horizontal line (`divider` color) with centered text "or fill in manually" — `caption`, `text-tertiary` |
| 6 | Title field | Label "TITLE" `caption` `text-secondary` uppercase. Input: `brand-blue-bg` bg, 10px radius, 44pt height, `space-md` horizontal padding |
| 7 | Date + Time | Side by side (each ~48% width). Labels "DATE" / "TIME" `caption` `text-secondary` uppercase. Tappable fields: `brand-blue-bg` bg, 10px radius, 44pt height. Tap reveals inline iOS picker wheel (height animates 0→auto, 0.3s) |
| 8 | Notes field | Label "NOTES" `caption` `text-secondary`. Input: `brand-blue-bg` bg, 10px radius, min 44pt, auto-grow. Placeholder "Add additional details..." `text-tertiary` |
| 9 | Repeat selector | Label "REPEAT" `caption` `text-secondary`. Horizontal pill row below (see Component Library §4.3) |
| 10 | Save button | Full width, 52pt height, `brand-blue` bg, white text "✨ Save Reminder" `button`, 12px radius. Disabled state: `text-tertiary` bg when title is empty |

**After AI Parse succeeds:**
- AI input collapses to single line showing original text
- Each auto-filled field briefly flashes background: `check-gold` at 20% opacity → `brand-blue-bg` (0.4s)
- Haptic: `.light` impact once

---

### Screen 7: Edit Reminder (Bottom Sheet)

**Same layout as Screen 6 with these differences:**

| Change | Detail |
|---|---|
| AI input + Parse button | Hidden (not shown) |
| "or fill in manually" divider | Hidden |
| All form fields | Pre-filled with current reminder values |
| Save button text | "Save Changes" instead of "Save Reminder" |
| Additional element | "Delete Reminder" text button at very bottom — `body-small`, `danger-red`, centered |

---

### Screen 8: Notification Snooze (iOS Notification Content Extension)

**Context:** This UI renders inside the iOS notification expansion when the user long-presses a Yomo notification. It is NOT a full-screen app view.

**Layout within notification extension area:**

| Element | Spec |
|---|---|
| System header | "🔔 Yomo" + timestamp (rendered by iOS, not custom) |
| System body | Reminder title (rendered by iOS, not custom) |
| Extension divider | System-provided |
| Label | "Snooze for" — `body`, `text-secondary`, centered |
| Slider | UISlider, range 1–60, integer steps, default 15 |
| — Track unfilled | `brand-blue-bg` |
| — Track filled | `brand-blue` |
| — Thumb | White circle, 28pt diameter, subtle shadow |
| Min label | "1" — `caption`, `text-tertiary`, left of slider |
| Max label | "60" — `caption`, `text-tertiary`, right of slider |
| Time display | "{value} min" — `snooze-display` (32pt bold), `brand-blue`, centered below slider, updates in real-time |
| Snooze button | ~45% width, 44pt height, `brand-blue` bg, white text "Snooze" `button-small`, 10px radius |
| Complete button | ~45% width, 44pt height, `success-green` bg, white text "✓ Complete" `button-small`, 10px radius |

**Non-Pro user alternative view:**
- Slider and time display replaced with:
  - "Snooze on your terms." — `title-small`, `text-primary`
  - "Upgrade to Pro to snooze from here." — `body-small`, `text-secondary`
  - "Upgrade to Pro" pill button — `brand-blue`
- Complete button remains (full width)

---

### Screen 9: In-App Snooze Fallback (Bottom Sheet)

**Trigger:** User taps (not long-presses) a notification → app opens → this sheet auto-presents.

**Container:** Small bottom sheet (~40% of screen height), glass card style, 16px top radius.

**Layout:**

| Element | Spec |
|---|---|
| Drag handle | Standard |
| Reminder icon + title | "🔔 Water the plants" — `title-small`, `text-primary` |
| Due time | "Due: 3:00 PM today" — `body-small`, `text-secondary` |
| Spacer | `space-lg` |
| Label | "Snooze for" — `body`, `text-secondary` |
| Number input | 64pt wide, centered, `brand-blue-bg` bg, `title-medium` text, `brand-blue` color, 10px radius. Numeric keyboard auto-opens. Range: 1–60 |
| "minutes" label | Right of input — `body`, `text-secondary` |
| Spacer | `space-lg` |
| Snooze button | ~45% width, `brand-blue`, same as notification |
| Complete button | ~45% width, `success-green`, same as notification |

---

### Screen 10: Paywall (Unlock Yomo Pro)

**Trigger:** User taps a Pro feature (Custom recurrence, Snooze, second device, themes).

**Container:** Tall bottom sheet (~88% of screen), glass card style, 16px top radius.

**Background decoration (inside the sheet):** Two soft radial gradients:
- Top-right: `onboarding-gradient-blue`, 200pt diameter
- Bottom-left: `onboarding-gradient-gold`, 180pt diameter

**Layout (top to bottom):**

| Order | Element | Spec |
|---|---|---|
| 1 | Drag handle | Standard |
| 2 | Title | "Yomo Pro" — `title-large`, `text-primary`, centered |
| 3 | Subtitle | "Unlock your full potential." — `body`, `text-secondary`, centered |
| 4 | Spacer | `space-lg` |
| 5 | Feature card 1 | ⏱ Custom Snooze — "Any minute, right from your notification." |
| 6 | Feature card 2 | 🔄 Advanced Repeats — "Hourly, every N days, monthly patterns, completion-based." |
| 7 | Feature card 3 | 🔗 Cloud Sync — "Dismiss once. Gone everywhere." |
| 8 | Feature card 4 | 🎨 Pro Themes — "Dark, light, glass." |
| 9 | Spacer | `space-lg` |
| 10 | Plan cards | Two cards side by side (see below) |
| 11 | Spacer | `space-md` |
| 12 | CTA button | Full width, 52pt, `brand-blue` bg, white text "Start 3-Day Free Trial" `button`, 12px radius |
| 13 | Fine print | "Cancel anytime. Not charged today." — `caption`, `text-tertiary`, centered |
| 14 | Restore | "Restore Purchases" — `caption`, `brand-blue`, centered |

**Feature cards:**
- Glass card style, `space-md` internal padding
- Icon: 20pt, left side
- Feature name: `title-small`, `text-primary`
- Description: `body-small`, `text-secondary`
- `space-sm` between each feature card

**Plan cards (side by side, each ~47% width):**

| Attribute | Monthly | Annual |
|---|---|---|
| Price | "$2.99" `title-small` | "$19.99" `title-small` |
| Label | "per month" `caption` `text-secondary` | "per year" `caption` `text-secondary` |
| Badge | — | "SAVE 44%" top-right, `check-gold` bg, white text, `caption`, 6px radius |
| Default state | Unselected | Selected (highlighted) |
| Unselected style | `brand-blue-bg` bg, no border | `brand-blue-bg` bg, no border |
| Selected style | `brand-blue-bg` bg, 2px `brand-blue` border | `brand-blue-bg` bg, 2px `brand-blue` border |

Card height: 72pt, corner radius: 12px.

---

### Screen 11: Settings

**Trigger:** Tap ⚙️ gear icon on main list.

**Navigation:**
- Top-left: "← Settings" (back arrow + `title-medium`)
- **No "Done" button. No tab bar.**

**Background:** `background` (#F8F9FB) solid. No decoration.

**Sections (each is a glass card with internal rows separated by `divider` lines):**

**ACCOUNT**
| Row | Left | Right |
|---|---|---|
| User info | Name + email/phone (`body`, `text-primary`) | — |
| Sign Out | "Sign Out" (`body-small`, `danger-red`) | — |

**SUBSCRIPTION**
| Row | Left | Right |
|---|---|---|
| Plan | "Yomo Pro" (`body`, `text-primary`) + Pro badge | "Active ✓" (`caption`, `success-green`) or "Manage →" (`body-small`, `brand-blue`) |
| Renewal | "Renews Mar 7, 2026" (`body-small`, `text-secondary`) | — |
| (If Free) | "Upgrade to Pro →" (`body`, `brand-blue`) | — |

**SYNCED DEVICES**
| Row | Left | Right |
|---|---|---|
| Device | 📱 + device name (`body`, `text-primary`) | "Active now" / "2 min ago" / "3 days ago" (`body-small`, `text-secondary`) |

**APPEARANCE**
| Row | Left | Right |
|---|---|---|
| Theme | "Theme" (`body`, `text-primary`) | Segmented control or dropdown: Light / Dark / System. Pro-only option: Glass ⭐ |

**ABOUT**
| Row | Left | Right |
|---|---|---|
| Version | "Version" | "1.0.0" (`body-small`, `text-secondary`) |
| Privacy | "Privacy Policy" | chevron → |
| Terms | "Terms of Service" | chevron → |

**Section headers:** "ACCOUNT", "SUBSCRIPTION", etc. — `caption`, `text-secondary`, uppercase, letter-spacing 0.5pt

**Row dimensions:** 48pt height per row, `space-md` horizontal padding. Chevrons: SF Symbol `chevron.right`, 12pt, `text-tertiary`.

---

## 4. Component Library

### 4.1 Primary Button

| Property | Value |
|---|---|
| Height | 52pt |
| Width | Full container width minus padding |
| Background | `brand-blue` |
| Text | White, `button` style (SF Pro Semibold 17pt) |
| Corner radius | 12px |
| Disabled | Background `text-tertiary`, not tappable |
| Press state | opacity 0.85, 0.1s |

### 4.2 Glass Card

| Property | Value |
|---|---|
| Background | rgba(255, 255, 255, 0.72) |
| Backdrop blur | 20px |
| Border | 1px solid rgba(255, 255, 255, 0.3) |
| Shadow | 0 2px 12px rgba(0, 0, 0, 0.06) |
| Corner radius | 12px |
| Internal padding | `space-md` (16pt) all sides |

### 4.3 Pill Button (Recurrence Selector)

| Property | Unselected | Selected |
|---|---|---|
| Height | 36pt | 36pt |
| Corner radius | 20px | 20px |
| Background | `brand-blue-bg` | `brand-blue` |
| Text | `text-primary`, `button-small` | White, `button-small` |
| Horizontal padding | 16pt | 16pt |
| Transition | bgColor 0.2s ease | — |

Options in row: `[ None ] [ Daily ] [ Weekly ] [ ⭐ Custom ]`

### 4.4 Form Input Field

| Property | Value |
|---|---|
| Height | 44pt (single line), auto-grow (multi-line) |
| Background | `brand-blue-bg` (#EBF3FC) |
| Corner radius | 10px |
| Padding | 12pt horizontal, 10pt vertical |
| Text | `body`, `text-primary` |
| Placeholder | `body`, `text-tertiary` |
| Focus border | 1px `brand-blue` |
| Label above | `caption`, `text-secondary`, uppercase |

### 4.5 Day-of-Week Selector (Weekly Recurrence)

7 circles in a horizontal row, evenly spaced.

| Property | Unselected | Selected |
|---|---|---|
| Size | 36pt diameter | 36pt diameter |
| Shape | Circle | Circle |
| Background | `brand-blue-bg` | `brand-blue` |
| Text | Single letter (M/T/W/T/F/S/S), `button-small`, `text-primary` | White |
| Multi-select | Yes | — |

Appears with slide-down animation (height 0→auto, opacity 0→1, 0.3s ease-out) when "Weekly" pill is selected.

### 4.6 FAB (Floating Action Button)

| Property | Value |
|---|---|
| Size | 56pt diameter |
| Shape | Circle |
| Background | `brand-blue` |
| Icon | SF Symbol `plus`, white, 24pt |
| Shadow | 0 4px 20px rgba(0, 0, 0, 0.10) |
| Position | 24pt from right edge, 24pt from bottom safe area |
| Press animation | scale 1.0→0.92→1.0, 0.2s spring |
| Haptic on press | `.light` impact |

### 4.7 Section Group Header

| Property | Value |
|---|---|
| Text style | `caption`, uppercase, letter-spacing 0.5pt |
| Color | `text-secondary` (default), `danger-red` (OVERDUE only) |
| Alignment | Left, aligned with card content (`space-xl` from screen edge) |
| Spacing | `space-lg` above, `space-sm` below |

### 4.8 Bottom Sheet

| Property | Value |
|---|---|
| Background | Glass card style (blur + semi-transparent) |
| Top corners | 16px radius |
| Drag handle | 36 × 4pt, `text-tertiary`, centered, 8pt from top |
| Open animation | translateY 100%→0, 0.4s spring (damping 0.85) |
| Close animation | translateY 0→100%, 0.3s ease-in |
| Backdrop | Dimmed overlay rgba(0, 0, 0, 0.3) behind sheet |

---

## 5. Animation & Haptics Specification

### 5.1 Animation Table

| Element | Animation | Duration | Easing | Delay |
|---|---|---|---|---|
| Welcome logo | opacity 0→1 | 0.6s | ease-out | 0 |
| Welcome tagline | opacity 0→1 | 0.4s | ease-out | 0.3s |
| Welcome buttons | translateY 20→0, opacity 0→1 | 0.4s | ease-out | staggered 0.1s |
| Parse loading line | width 0→100%, repeat | 1.5s | linear | 0 |
| Pre-fill card enter | translateY 40→0, scale 0.97→1.0 | 0.5s | spring (damping 0.8) | 0 |
| Pre-fill field highlight | bgColor gold 20%→blue-bg | 0.4s | ease-out | 0 |
| Celebration checkmark stroke | path draw | 0.4s | ease-in-out | 0 |
| Celebration circle pulse | scale 1.0→1.08→1.0 | 0.3s | ease-in-out | 0.4s |
| Celebration text | opacity 0→1 | 0.4s | ease-out | 0.6s |
| Celebration→main list | cross-fade | 0.5s | ease-in-out | 2.0s auto |
| Bottom sheet open | translateY 100%→0 | 0.4s | spring (0.85) | 0 |
| Bottom sheet close | translateY 0→100% | 0.3s | ease-in | 0 |
| Card swipe complete/delete | translateX→off screen + height collapse | 0.3s | ease-out | 0 |
| Recurring card re-enter | translateY 16→0, opacity 0→1 | 0.3s | spring | 0 |
| New card appear in list | translateY 16→0, opacity 0→1 | 0.3s | spring | 0 |
| Pill selection | bgColor transition | 0.2s | ease-in-out | 0 |
| Weekly days expand | height 0→auto, opacity 0→1 | 0.3s | ease-out | 0 |
| FAB press | scale 1.0→0.92→1.0 | 0.2s | spring | 0 |
| Sync: card disappear (remote) | opacity 1→0 + height collapse | 0.3s | ease-out | 0 |

### 5.2 Haptic Feedback Table

| Moment | Haptic Type | iOS API | Intensity |
|---|---|---|---|
| Onboarding celebration checkmark | Impact | `UIImpactFeedbackGenerator(.medium)` | Medium |
| Right swipe complete | Impact | `UIImpactFeedbackGenerator(.light)` | Light |
| Left swipe delete | Impact | `UIImpactFeedbackGenerator(.light)` | Light |
| AI Parse fields populated | Impact | `UIImpactFeedbackGenerator(.light)` | Light |
| Save reminder | Impact | `UIImpactFeedbackGenerator(.light)` | Light |
| FAB press | Impact | `UIImpactFeedbackGenerator(.light)` | Light |
| In-app snooze slider drag (each integer) | Selection | `UISelectionFeedbackGenerator()` | Default |
| In-app snooze confirmed | Impact | `UIImpactFeedbackGenerator(.medium)` | Medium |
| In-app complete from fallback | Notification | `UINotificationFeedbackGenerator(.success)` | Success |
| Notification extension snooze/complete | None (MVP) | — | — |

---

## 6. Stitch Prompt Reference

Use the following description when generating screens in Stitch. Copy this as a global context prompt:

---

**Yomo is a cross-platform reminder app for iOS. The design aesthetic is "Warm Glass" — clean, modern glassmorphism on a light background with a friendly, approachable personality.**

**Visual identity:**
- Light cool-gray background (#F8F9FB) — not pure white
- All cards use frosted glass effect: semi-transparent white at 72% opacity, 20px backdrop blur, subtle 1px white border, gentle shadow. Cards float above the background with depth
- Primary color: blue (#4A90D9) — used ONLY at interaction points (buttons, selected states, links). The app is NOT blue-heavy overall
- Achievement color: warm gold (#F5A623) — used ONLY for completion moments (checkmarks, Pro badges, celebration)
- Typography: SF Pro system font throughout. Clean hierarchy with bold titles and regular body text
- Corner radius: 12px for cards and buttons, 20px for pill buttons, 10px for input fields
- Generous spacing: 32pt side margins, 24pt between sections. Content always breathes

**Personality:**
- The app feels warm and friendly but never childish
- The cute mascot logo (blue alarm clock character) appears ONLY on the welcome screen and settings — never inside the main app experience
- Personality is expressed through clever copy and smooth micro-animations, not visual clutter
- Background gradient decorations (soft blue and warm gold radial gradients) appear ONLY on onboarding screens and paywall — all other screens have clean solid backgrounds

**Reference mood: "Todoist's warmth meets Apple Weather's glass cards."**

---

*End of Final Design Specification — Yomo v1.0 MVP*

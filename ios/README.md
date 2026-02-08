# Yomo iOS App

Cross-platform reminder app built for the RevenueCat Shipyard Creator Contest.

## Setup Instructions

### Prerequisites
- macOS with Xcode 15+
- iOS 15+ target device or simulator
- CocoaPods or Swift Package Manager
- Firebase project configured (already done ✅)

### Step 1: Open in Xcode

Since we're using Swift Package Manager, you have two options:

**Option A: Create Xcode Project via Xcode GUI**
1. Open Xcode
2. File → New → Project
3. Select "iOS" → "App"
4. Product Name: `Yomo`
5. Bundle Identifier: `com.yomo.Yomo` (or `com.yomo.app` - see BUNDLE_ID_FIX.md)
6. Interface: SwiftUI
7. Language: Swift
8. Save to: `/Users/mystery/Desktop/YOMO/ios/`

Then:
- Delete the default generated files
- Drag all files from `Yomo/` folder into the Xcode project
- Add `GoogleService-Info.plist` to the project (already in Resources/)
- Add Firebase SDK via Swift Package Manager (File → Add Packages)

**Option B: Use Existing Structure (Recommended)**
```bash
cd /Users/mystery/Desktop/YOMO/ios
open Yomo.xcodeproj  # After creating it
```

### Step 2: Add Firebase Dependencies

In Xcode:
1. File → Add Packages
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Version: 10.20.0+
4. Add packages:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseMessaging

5. Add Google Sign-In:
   - URL: `https://github.com/google/GoogleSignIn-iOS`
   - Version: 7.0.0+

6. Add RevenueCat (for Day 6):
   - URL: `https://github.com/RevenueCat/purchases-ios`
   - Version: 4.37.0+

### Step 3: Configure Capabilities

In Xcode project settings → Signing & Capabilities:

1. **Enable App Groups**
   - Add capability: App Groups
   - Add group: `group.com.yomo.app`

2. **Enable Push Notifications**
   - Add capability: Push Notifications

3. **Enable Background Modes**
   - Check: Remote notifications

### Step 4: Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select project: `yomo-5fba1`
3. Enable Authentication:
   - Sign-in method → Google (Enable)
   - Sign-in method → Phone (Enable)
4. Enable Firestore:
   - Create database in production mode
   - Start collection: `users`
5. Enable Cloud Messaging (FCM)
   - iOS app settings → Upload APNs certificate (later)

### Step 5: Run the App

1. Select a target device/simulator (iOS 15+)
2. Press ⌘R to build and run
3. You should see the Welcome screen with Google/Phone sign-in

## Project Structure

```
Yomo/
├── YomoApp.swift              # App entry point
├── Core/
│   ├── AppDelegate.swift      # Firebase initialization
│   ├── AppState.swift         # Global state
│   └── Constants.swift        # API keys, config
├── Models/
│   ├── Reminder.swift         # Core data model
│   └── User.swift             # User profile
├── Services/
│   └── AuthService.swift      # Authentication logic
├── ViewModels/
│   └── AuthViewModel.swift    # Auth UI state
├── Views/
│   ├── Authentication/
│   │   └── WelcomeView.swift  # Welcome screen
│   └── Components/
│       └── GlassCard.swift    # Reusable glass card
├── Utilities/
│   ├── DesignTokens.swift     # Colors, fonts, spacing
│   └── HapticManager.swift    # Haptic feedback
└── Resources/
    └── GoogleService-Info.plist
```

## Day 1 Status: ✅ Foundation Complete

### Implemented
- ✅ Project structure created
- ✅ Firebase SDK integration ready
- ✅ Google Sign-In configured
- ✅ Phone authentication configured
- ✅ User profile creation in Firestore
- ✅ Device registration framework
- ✅ Welcome screen with design spec compliance
- ✅ Design tokens (colors, typography, spacing)
- ✅ Global app state management

### Testing Day 1
1. Run app → See Welcome screen
2. Tap "Continue with Google" → Google OAuth flow
3. Sign in → Profile created in Firestore
4. Check Firestore console → See `users/{uid}/profile` document

## Next Steps: Day 2

Tomorrow we'll implement:
- Firestore service layer for CRUD operations
- Reminder list view with sectioned layout
- Real-time sync with Firestore listeners
- Swipe to complete/delete
- Basic reminder creation form

## Troubleshooting

### Build Errors
- Ensure all Firebase packages are added
- Check bundle ID matches: `com.yomo.app`
- Verify `GoogleService-Info.plist` is in target

### Google Sign-In Fails
- Check `CFBundleURLSchemes` in Info.plist
- Verify OAuth client ID in Firebase Console
- Ensure Google Sign-In is enabled in Firebase Auth

### Firebase Not Initialized
- Confirm `FirebaseApp.configure()` is called in AppDelegate
- Check `GoogleService-Info.plist` is correctly placed

## API Keys Required (Add to Constants.swift)

```swift
// Day 6: Add these
static let revenueCatAPIKey = "YOUR_REVENUECAT_KEY"
static let claudeAPIKey = "YOUR_ANTHROPIC_KEY"  // For AI parsing
static let openaiAPIKey = "YOUR_OPENAI_KEY"     // For Whisper (voice input)
```

## Voice Input Strategy

For voice-based reminder creation:
1. **Whisper API** (OpenAI) - Convert speech to text (~$0.006/minute)
2. **Claude Haiku API** - Parse text into structured reminder (~$0.25/1M tokens)

Total cost: ~$0.01 per voice reminder creation.

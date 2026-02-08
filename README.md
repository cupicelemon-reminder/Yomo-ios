# Yomo - Never Forget What Matters

Cross-platform reminder app built for the RevenueCat Shipyard Creator Contest.

## 🎯 Project Vision

A powerful reminder app designed for power users with:
- ⏰ Custom notification snooze (1-60 minutes from notification)
- 🔁 Advanced recurrence patterns (hourly, daily, weekly, monthly, completion-based)
- 📱 Real-time cross-device sync ("60 phones on a desk" demo)
- ✨ AI-powered natural language input + voice support
- 🎨 Polished glassmorphic design

## 📅 Implementation Status

**Deadline**: February 12, 2026
**Current Day**: Day 1 - Foundation & Authentication

### Day 1: Foundation & Authentication ✅
- [x] Project structure created
- [x] Firebase SDK integration
- [x] Google Sign-In configured
- [x] Phone authentication ready
- [x] User profile creation in Firestore
- [x] Device registration framework
- [x] Welcome screen with design spec
- [x] Design tokens (colors, typography, spacing)
- [x] Global app state management

### Day 2-7: Upcoming
- [ ] Day 2: Reminder CRUD + Real-Time Sync
- [ ] Day 3: Local Notifications + Custom Snooze Extension
- [ ] Day 4: Recurrence Engine + Advanced UI
- [ ] Day 5: Cross-Device Sync (FCM + Cloud Functions)
- [ ] Day 6: RevenueCat + Paywall + AI Pre-fill
- [ ] Day 7: Polish + Android Shell + TestFlight

## 🏗️ Technical Stack

**iOS (Primary - Full MVP)**
- Swift/SwiftUI with MVVM architecture
- Firebase (Firestore, Auth, FCM)
- RevenueCat for subscriptions
- Local notifications with custom Notification Content Extension
- AI parsing via Claude Haiku or GPT-4o-mini

**Android (Secondary - Visual Shell)**
- React Native + Expo
- Firebase Firestore listener (read-only)
- Demonstrates cross-platform sync capability

**Backend**
- Firebase Firestore for real-time data sync
- Firebase Cloud Functions for cross-device notification clearing
- RevenueCat webhook for subscription management

## 📂 Project Structure

```
ios/Yomo/
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
    └── Assets.xcassets/       # App icons, colors
```

## 🚀 Getting Started

### Prerequisites
- macOS with Xcode 15+
- iOS 15+ target device or simulator
- Firebase project configured

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/cupicelemon-reminder/Yomo-ios.git
   cd Yomo-ios
   ```

2. **Configure Firebase**
   - Create a Firebase project at https://console.firebase.google.com
   - Download `GoogleService-Info.plist`
   - Place it in `ios/Yomo/Resources/`
   - Update Bundle ID in Firebase to match `com.yomo.Yomo`

3. **Add API Keys**
   - Copy `ios/Yomo/Core/Constants.swift.example` to `Constants.swift`
   - Add your API keys:
     - RevenueCat API key
     - Claude/OpenAI API key (for AI parsing)

4. **Open in Xcode**
   ```bash
   cd ios
   open Yomo.xcodeproj
   ```

5. **Add Dependencies**
   - File → Add Package Dependencies
   - Add:
     - `https://github.com/firebase/firebase-ios-sdk` (10.20.0+)
     - `https://github.com/google/GoogleSignIn-iOS` (7.0.0+)
     - `https://github.com/RevenueCat/purchases-ios` (4.37.0+)

6. **Configure Capabilities**
   - Signing & Capabilities → Add:
     - App Groups: `group.com.yomo.Yomo`
     - Push Notifications
     - Background Modes: Remote notifications

7. **Run**
   ```bash
   ⌘R
   ```

## 🔑 Configuration

### Bundle Identifier
- iOS: `com.yomo.Yomo`
- App Group: `group.com.yomo.Yomo`

**Important**: Ensure your Firebase `GoogleService-Info.plist` BUNDLE_ID matches your Xcode Bundle Identifier. See `ios/BUNDLE_ID_FIX.md` for details.

### API Keys Required

Create `ios/Yomo/Core/Constants.swift` from example:

```swift
enum Constants {
    static let bundleId = "com.yomo.Yomo"
    static let appGroupId = "group.com.yomo.Yomo"
    static let notificationCategoryId = "YOMO_REMINDER"

    static let revenueCatAPIKey = "YOUR_REVENUECAT_KEY"
    static let claudeAPIKey = "YOUR_ANTHROPIC_KEY"
    static let openaiAPIKey = "YOUR_OPENAI_KEY"
}
```

## 📖 Documentation

- [Implementation Plan](docs/Implementation_Plan.md) - Complete 7-day roadmap
- [Design Specification](docs/Yomo_Final_Design_Spec.md) - UI/UX design system
- [Bundle ID Configuration](ios/BUNDLE_ID_FIX.md) - Firebase setup guide
- [Xcode Project Setup](ios/CREATE_XCODE_PROJECT.md) - Detailed setup steps

## 🎨 Design System

Based on modern iOS design principles with glassmorphic UI:

- **Colors**: Brand Blue (#4A90D9), Gold Accent (#F5A623)
- **Typography**: SF Pro Display, 8pt grid system
- **Glass Effect**: 72% opacity, 20px backdrop blur
- **Animations**: Spring physics, haptic feedback

## 🧪 Testing

### Day 1 Test Checklist
- [ ] App launches without crashes
- [ ] Welcome screen displays correctly
- [ ] Google Sign-In flow completes
- [ ] User profile created in Firestore
- [ ] Firebase connection verified

## 📝 License

MIT License - Built for RevenueCat Shipyard Creator Contest 2026

## 👤 Author

Built with ❤️ for the RevenueCat Shipyard Creator Contest

## 🔗 Links

- [Firebase Console](https://console.firebase.google.com/project/yomo-5fba1)
- [RevenueCat Dashboard](https://app.revenuecat.com)
- [Contest Details](https://www.revenuecat.com/shipyard)

---

**Status**: Day 1 Complete - Foundation & Authentication ✅
**Next**: Day 2 - Reminder CRUD + Real-Time Sync

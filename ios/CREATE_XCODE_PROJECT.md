# How to Create the Xcode Project

Since Xcode projects can't be created via command line easily with proper configuration, follow these steps:

## Quick Setup (5 minutes)

### Step 1: Create New Xcode Project
1. Open **Xcode**
2. File → New → Project (⇧⌘N)
3. Choose template: **iOS** → **App**
4. Click **Next**

### Step 2: Configure Project
Fill in these exact values:
- **Product Name**: `Yomo`
- **Team**: Select your Apple Developer team
- **Organization Identifier**: `com.yomo`
- **Bundle Identifier**: `com.yomo.Yomo` (IMPORTANT: Must match Firebase - see BUNDLE_ID_FIX.md)
- **Interface**: **SwiftUI**
- **Language**: **Swift**
- **Storage**: None (uncheck Core Data and CloudKit)
- **Tests**: Check "Include Tests"

Click **Next** → Save to: `/Users/mystery/Desktop/YOMO/ios/`

### Step 3: Replace Generated Files
Xcode will create some default files. Delete these:
- `YomoApp.swift` (we'll use ours)
- `ContentView.swift` (we have our own)
- `Assets.xcassets` (keep this folder, just empty it)

### Step 4: Add Our Files to Xcode
1. In Finder, open `/Users/mystery/Desktop/YOMO/ios/Yomo/`
2. Drag these folders into Xcode's left sidebar (Project Navigator):
   - Core/
   - Models/
   - Services/
   - ViewModels/
   - Views/
   - Utilities/
   - Resources/ (including GoogleService-Info.plist)
   - YomoApp.swift (root level)

3. When prompted, choose:
   - ✅ "Copy items if needed"
   - ✅ "Create groups"
   - ✅ Add to target: Yomo

### Step 5: Add Firebase SDK
1. File → Add Package Dependencies
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Dependency Rule: "Up to Next Major Version" - `10.20.0`
4. Click **Add Package**
5. Select these products (⌘+Click to multi-select):
   - ✅ FirebaseAuth
   - ✅ FirebaseFirestore
   - ✅ FirebaseMessaging
6. Click **Add Package**

### Step 6: Add Google Sign-In SDK
1. File → Add Package Dependencies
2. Enter URL: `https://github.com/google/GoogleSignIn-iOS`
3. Version: `7.0.0`
4. Select: **GoogleSignIn**
5. Click **Add Package**

### Step 7: Add RevenueCat SDK
1. File → Add Package Dependencies
2. Enter URL: `https://github.com/RevenueCat/purchases-ios`
3. Version: `4.37.0`
4. Select: **RevenueCat**
5. Click **Add Package**

### Step 8: Replace Info.plist
1. Delete the default `Info.plist` in Xcode
2. Drag our `Info.plist` from `/Users/mystery/Desktop/YOMO/ios/Yomo/Info.plist`
3. Or copy the contents from our Info.plist into the existing one

### Step 9: Configure Capabilities
In Xcode, select the **Yomo** project → **Signing & Capabilities** tab:

1. Click **+ Capability**
2. Add **App Groups**
   - Click "+" under App Groups
   - Enter: `group.com.yomo.app`
   - Click OK

3. Click **+ Capability**
4. Add **Push Notifications**

5. Click **+ Capability**
6. Add **Background Modes**
   - Check: ✅ Remote notifications

### Step 10: Build and Run
1. Select target device: iPhone 15 Pro (or any iOS 15+ simulator)
2. Press **⌘R** to build and run
3. Wait for build to complete (~1-2 minutes first time)

## Expected Result ✅

You should see:
- **Welcome Screen** with Yomo logo
- "Never forget what matters" tagline
- Two buttons: "Continue with Google" and "Continue with Phone"
- Gradient blue background

## If Build Fails

### Error: "No such module 'FirebaseAuth'"
→ Go to File → Packages → Resolve Package Versions

### Error: "Missing GoogleService-Info.plist"
→ Make sure you dragged the Resources/ folder with the plist file

### Error: "Bundle identifier mismatch"
→ Check Project Settings → General → Bundle Identifier = `com.yomo.app`

### Error: Google Sign-In redirect URI
→ Check Info.plist has correct `CFBundleURLSchemes` (already configured in our Info.plist)

## Quick Test

Once app launches:
1. Tap "Continue with Google"
2. Sign in with your Google account
3. App should show: "Authenticated! Reminder list coming in Day 2"
4. Check Firebase Console → Firestore → `users` collection → Your user document should exist

---

**Time estimate**: 5-10 minutes for first-time setup

**Next**: Once Xcode project is created and running, we'll implement Day 2 (Reminder CRUD + Sync)

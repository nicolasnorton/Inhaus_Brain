# Inhaus Brain - iOS & macOS Readiness Walkthrough

This guide details the steps to prepare the Inhaus Brain application for testing and deployment on macOS and iOS.

## Prerequisites

1.  **Xcode**: Ensure you have the latest version of Xcode installed from the Mac App Store.
2.  **CocoaPods**: Ensure CocoaPods is installed.
    ```bash
    sudo gem install cocoapods
    ```
3.  **Flutter SDK**: Ensure you are on the stable channel and up to date.

## 1. Configuration & Permissions

### iOS (`ios/Runner/Info.plist`)
We need to add the following keys to `ios/Runner/Info.plist` to access hardware features:

*   **NSMicrophoneUsageDescription**: "This app needs access to the microphone for audio recording and voice commands."
*   **NSCameraUsageDescription**: "This app needs access to the camera to capture images for analysis."
*   **NSSpeechRecognitionUsageDescription**: "This app uses speech recognition to convert your voice to text."
*   **NSPhotoLibraryUsageDescription**: "This app needs access to your photo library to select images."

### macOS (`macos/Runner/Info.plist` & Entitlements)

**Info.plist**:
Similar to iOS, macOS apps must declare their intent to use hardware in `Info.plist`.

**Entitlements (`macos/Runner/*.entitlements`)**:
Since macOS apps run in a sandbox, we must explicitly request capabilities:
*   `com.apple.security.network.client`: Allow outgoing network connections (Internet).
*   `com.apple.security.device.audio-input`: Allow microphone access.
*   `com.apple.security.device.camera`: Allow camera access.
*   `com.apple.security.files.user-selected.read-write`: Allow reading/writing user-selected files.

## 2. Dependency Setup

Navigate to the platform-specific directories and install the native dependencies.

**iOS**:
1.  Open `ios/Podfile` and ensure the platform is set to at least 14.0:
    ```ruby
    platform :ios, '14.0'
    ```
2.  Run the install commands:
    ```bash
    cd ios
    rm -rf Pods
    rm Podfile.lock
    pod install --repo-update
    cd ..
    ```

**macOS**:
```bash
cd macos
rm -rf Pods
rm Podfile.lock
pod install --repo-update
cd ..
```

## 3. Signing & Capabilities

1.  Open `ios/Runner.xcworkspace` in Xcode.
2.  Select the **Runner** project in the navigator.
3.  Select the **Runner** target.
4.  Go to the **Signing & Capabilities** tab.
5.  Select your **Team**.
6.  Ensure a unique **Bundle Identifier** is set (e.g., `com.yourcompany.inhausbrain`).
7.  Repeat the same process for `macos/Runner.xcworkspace`.

## 4. Running the App

**Run on macOS**:
```bash
flutter run -d macos
```

**Run on iOS Simulator**:
```bash
open -a Simulator
flutter run -d iphone
```

**Run on Physical iOS Device**:
1.  Connect your iPhone via USB.
2.  Unlock the device and trust the computer.
3.  Run:
    ```bash
    flutter run -d <device_id>
    ```

## 5. Troubleshooting (Common Issues)

*   **Pod Version Mismatch**: If you see errors about `versions` not matching, run `pod update` inside the ios/macos folder.
*   **Signing Errors**: Ensure your Apple ID is added to Xcode (Settings > Accounts) and selected in the Signing tab.
*   **Sandbox Issues**: If network calls fail on macOS, verify `com.apple.security.network.client` is in the entitlements file.

---
**Status Checklist**:
- [ ] iOS Info.plist updated
- [ ] macOS Info.plist updated
- [ ] macOS Entitlements updated
- [ ] Pods installed (iOS)
- [ ] Pods installed (macOS)

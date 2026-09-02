# iOS Release Preparation Walkthrough

I have prepared the Cat Poe project for an iOS release. Below is a summary of the changes made and instructions for the final build.

## Changes Made

### Configuration Updates
- **Info.plist**: Added mandatory usage descriptions for `image_picker` (Camera, Microphone, Photo Library) and the `SKAdNetworkItems` list for `google_mobile_ads`.
- **pubspec.yaml**: Added `remove_alpha_ios: true` to the `flutter_launcher_icons` configuration to ensure compliance with Apple App Store requirements.

### Asset Generation
- Successfully generated iOS app icons from `assets/images/catcoin_logo.png` without an alpha channel.

## Final Build Instructions (User Action Required)

Since you are on Windows, you must perform the following steps on a **Mac with Xcode** to generate the final release build (`.ipa`).

### Method 1: Local Mac Build
1.  **Clone/Pull** the latest changes to your Mac.
2.  Open a terminal in the `cat_poe` directory.
3.  Run the following commands:
    ```bash
    flutter pub get
    cd ios
    pod install
    cd ..
    flutter build ipa --release
    ```
4.  The generated `.ipa` file will be located in `build/ios/ipa/`.
5.  Upload the `.ipa` to **App Store Connect** using the **Transporter** app or directly from **Xcode** via `Product > Archive`.

### Method 2: CI/CD (Codemagic)
1.  Connect your repository to [Codemagic](https://codemagic.io/).
2.  Configure a build for **iOS**.
3.  Set the build trigger to "Manual" or "On Push".
4.  Download the generated build artifacts.

## Verification
- [x] `Info.plist` contains all required keys.
- [x] `pubspec.yaml` settings are optimized for iOS.
- [x] App icons are generated and compliant.

> [!IMPORTANT]
> Ensure you have an active Apple Developer Program membership to sign and upload the app to the App Store.

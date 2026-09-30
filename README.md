# LETS ELEVATOR NEO - Elevator Simulator

<div align="center">
  <img src="assets/icon/icon.png" alt="Let's Elevator NEO Icon" width="120" height="120">
  <br>
  <strong>Enjoy your favorite elevator anytime, anywhere</strong>
  <br>
  <strong>Hyper-real elevator sim you can fill with your own photos</strong>
</div>

## 📱 Application Overview

LETS ELEVATOR NEO is a Flutter app for Android and iOS that lets you experience and operate an elevator.
Buttons, floors and room images are customizable, and the floor images can be replaced with pictures from your own gallery.

### 🎯 Key Features

- **Realistic Elevator Operation**: Authentic elevator-like operation experience
- **Cross-platform Support**: Android and iOS
- **Leaderboard**: Game Center and Google Play Games through `games_services`
- **Multi-language Support**: Japanese, English, Korean, Chinese, Spanish, French
- **Google Mobile Ads**: Banner ads and rewarded ads that unlock customization
- **In-app Purchase**: One-time premium unlock via RevenueCat
- **Firebase Integration**: Analytics
- **Audio & Vibration Feedback**: Sounds, spoken announcements and haptics
- **Customizable Settings**: Floors, floor numbers, button shapes and styles
- **Top Floor Display**: The top floor always displays as R, whatever floor number it is set to
- **Top Floor Announcement**: Arriving at the top floor speaks only the room name, not a floor number, for the same reason

## 🚀 Technology Stack

### Frameworks & Libraries
- **Flutter**: 3.47.0+
- **Dart**: 3.13.0+
- **Firebase**: firebase_core, firebase_analytics
- **Google Mobile Ads**: google_mobile_ads
- **RevenueCat**: purchases_flutter
- **Game Services**: games_services, connectivity_plus

### Core Features
- **Audio**: just_audio
- **Text-to-Speech**: flutter_tts, vendored under `packages/flutter_tts`
- **Vibration**: vibration
- **State Management**: hooks_riverpod, flutter_hooks
- **Localization**: flutter_localizations, intl
- **Environment Variables**: flutter_dotenv
- **Storage**: shared_preferences
- **Images**: image_picker, image_cropper, path_provider
- **Permissions**: permission_handler
- **Links**: url_launcher
- **Store Review**: in_app_review

`flutter_tts` is a path dependency, not the pub.dev package.
The fork adds Swift Package Manager manifests and an Android Gradle Plugin 9 build, and `pubspec.yaml` records exactly what differs from the published 4.2.5.

## 📋 Prerequisites

- Flutter 3.47.0+ (required by Android Gradle Plugin 9: earlier versions force the Kotlin Gradle Plugin onto modules that AGP 9 compiles itself)
- Dart 3.13.0+
- Android Studio / Xcode
- A Firebase project (Analytics), since `main.dart` calls `Firebase.initializeApp` at startup
- A RevenueCat account for the premium purchase
- `firebase-tools` (`npm i -g firebase-tools`) and `flutterfire_cli` (`dart pub global activate flutterfire_cli`), then `firebase login`

## 🛠️ Setup

### 1. Clone the Repository
```bash
git clone https://github.com/fcb1899v/elevatorneo_flutter.git
cd elevatorneo_flutter
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configuration Files Setup

**Environment variables.** Copy `assets/.env_example` to `assets/.env` and fill in the values.
The template lists every key with what it is for, and is the one place that list is maintained.
`pubspec.yaml` declares `assets/.env`, so the file has to exist or the build fails.
Debug builds use Google's demo ad units and need no real ids, and the demo unit for an inline adaptive request is not the same id as the fixed-size one.

**Android signing, release only.** Copy `android/key.properties.example` to `android/key.properties` and fill it in.
Nothing in it ships inside the app, and the two passwords are real secrets: together with the keystore they let anyone publish an update Play accepts as coming from you.
Keep the keystore outside the repository and back both up.
A release built without this file falls back to the debug signing config, which produces an artifact Play rejects.

### 4. Firebase Configuration

1. Create a Firebase project.
2. Run `flutterfire configure`.
   It writes the Android and iOS Firebase config files and `lib/firebase_options.dart`.
3. None of those files are in git.
   The Android build fails without the generated json, so a fresh clone has to run `flutterfire configure` before building.

### 5. Run the Application
```bash
# Android
flutter run -d <android-device-id>

# iOS (Swift Package Manager: there is no Podfile to install)
flutter run -d <ios-device-id>
```

## 🎮 Application Structure

```
lib/
├── main.dart                    # Application entry point
├── homepage.dart                # Main page
├── menu.dart                    # Menu page
├── settings.dart                # Settings page
├── premium_page.dart            # Premium purchase page
├── purchase_manager.dart        # RevenueCat purchase and entitlement handling
├── plan_provider.dart           # Premium state provider
├── games_manager.dart           # Game services, sign-in and score submission
├── audio_manager.dart           # Audio management
├── tts_manager.dart             # Text-to-speech management
├── image_manager.dart           # Image list and settings persistence
├── photo_manager.dart           # Gallery selection, cropping and permissions
├── analytics_manager.dart       # Firebase Analytics events
├── review_manager.dart          # Store review request
├── admob_banner.dart            # Banner advertisement management
├── admob_interstitial.dart      # Interstitial advertisements (not in use)
├── common_widget.dart           # Common widgets
├── constant.dart                # Constant definitions
├── extension.dart               # Extension functions
├── l10n_extension.dart          # Localization helpers, part of extension.dart
├── size_extension.dart          # Responsive sizing helpers, part of extension.dart
└── l10n/                        # Localization
    ├── app_en.arb
    ├── app_es.arb
    ├── app_fr.arb
    ├── app_ja.arb
    ├── app_ko.arb
    ├── app_zh.arb
    └── app_localizations*.dart   # Generated by flutter gen-l10n

assets/
├── images/                      # Image resources
│   ├── menu/                   # Menu images
│   ├── button/                 # Button images
│   ├── elevator/               # Elevator images
│   ├── room/                   # Room background images
│   └── settings/               # Settings screen images
├── audios/                     # Audio files
├── fonts/                      # Font files
└── icon/                       # App icons
```

```
packages/
└── flutter_tts/          # Fork of the published flutter_tts, used through a path dependency
```

Rewarded ad loading and display live in `menu.dart`, not in a separate ad file.
`lib/firebase_options.dart` is generated by `flutterfire configure` and is not in git.

## 💳 Premium

A single non-consumable purchase, sold through RevenueCat.
The app checks the entitlement `elevatorneo_premium` (`premiumEntitlementID` in `lib/constant.dart`), which must match the RevenueCat dashboard.

- Removes the banner ad and opens every lock at once
- Reached from the fourth menu tile, and from any padlock in settings
- The tile is dropped once premium is owned, or while no store price is known
- Restoring is offered on the same page, as the store guidelines require

## 📱 Supported Platforms

- **Android**: API 24+ (`flutter.minSdkVersion`), compiled and targeted at API 37
- **iOS**: iOS 15.0+ (`IPHONEOS_DEPLOYMENT_TARGET`)

## 🔧 Development

### Code Analysis
```bash
flutter analyze   # expected: No issues found!
```

### Run Tests
```bash
flutter test      # expected: All tests passed!
```

### Build
```bash
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS
flutter build ios
```

## 📄 License

This project is not open source.
The source is published so that it can be read, and all rights are reserved.
See [LICENSE](LICENSE) for what that permits.
Third-party components keep their own licenses, listed below.

## 🤝 Contributing

Issue reports are welcome.
Pull requests are not accepted, because the code is not licensed for redistribution.

## 📞 Support

If you have any problems or questions, please create an issue on GitHub.

## Licenses & Credits

This app uses the following third-party components:

- Flutter (BSD 3-Clause License)
- Gradle Wrapper (Apache License 2.0), the `android/gradle/wrapper/gradle-wrapper.jar` committed here
- firebase_core, firebase_analytics (BSD 3-Clause License)
- google_mobile_ads (Apache License 2.0)
- Google Mobile Ads Android SDK (Android Software Development Kit License): `play-services-ads`, pulled in by google_mobile_ads
- Google Mobile Ads iOS SDK (proprietary Google binary; its CocoaPods spec declares only a Google copyright notice, with no open-source license): `Google-Mobile-Ads-SDK`, pulled in by google_mobile_ads
- User Messaging Platform, the consent SDK (Android Software Development Kit License): `com.google.android.ump:user-messaging-platform`, pulled in by google_mobile_ads
- User Messaging Platform on iOS (proprietary Google binary, declared the same way as the iOS ads SDK): `GoogleUserMessagingPlatform`, pulled in by `Google-Mobile-Ads-SDK`
- purchases_flutter (MIT License)
- shared_preferences (BSD 3-Clause License)
- flutter_dotenv (MIT License)
- flutter_tts (MIT License)
- just_audio (MIT License), which bundles ExoPlayer on Android: `androidx.media3:media3-exoplayer` (Apache License 2.0)
- vibration (BSD 2-Clause License)
- games_services (MIT License)
- connectivity_plus (BSD 3-Clause License)
- in_app_review (MIT License)
- hooks_riverpod, flutter_hooks (MIT License)
- url_launcher (BSD 3-Clause License)
- webview_flutter (BSD 3-Clause License), pulled in by google_mobile_ads
- cupertino_icons (MIT License)
- flutter_launcher_icons (MIT License)
- flutter_native_splash (MIT License)
- image_picker (BSD 3-Clause License)
- image_cropper (BSD 3-Clause License)
- permission_handler (MIT License)
- path, path_provider (BSD 3-Clause License)
- intl (BSD 3-Clause License)
- flutter_localizations (BSD 3-Clause License)

For details of each license, please refer to [pub.dev](https://pub.dev/) or the LICENSE file in each repository.

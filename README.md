# Elevator Simulator NEO

## Overview
LETS ELEVATOR NEO is a Flutter-based simulation app for Android & iOS that lets you experience and operate elevators.
It provides a practical and enjoyable experience through Game Center and Google Play Games integration, ads, sound, and multi-language support.

## Main Features
- Elevator operation and simulation
- Cross-platform support (Android & iOS)
- Game Center and Google Play Games integration (leaderboards & achievements)
- Multi-language support (Japanese, English, Korean, Chinese)
- Google Mobile Ads (banner ads & rewarded ads)
- Firebase integration (Analytics, Crashlytics, App Check)
- Sound and BGM playback
- Various settings screens

## Development Environment
- Flutter 3.x or later
- Dart 2.17 or later
- Android Studio / Xcode
- Firebase (App Check, Analytics, Crashlytics, etc.)

## Setup Instructions

1. Place required files  
   - `android/app/google-services.json` (download from your Firebase project)
   - `ios/Runner/GoogleService-Info.plist` (download from your Firebase project)
   - `assets/.env` (if needed)

2. Install dependencies  
   ```
   flutter pub get
   ```

3. Build and run the app  
   - Android:
     ```
     flutter run
     ```
   - iOS:
     ```
     cd ios
     pod install
     cd ..
     flutter run
     ```

## Notes
- Please configure Firebase, Game Center and Google Play Games for your own project.
- Sensitive files (keystore, .env, google-services.json, etc.) are not tracked by Git.

## Directory Structure
- `lib/` ... Main Dart code
- `assets/` ... Images, audio, fonts, and other resources
- `android/` ... Android native code
- `ios/` ... iOS native code

## License
This project is licensed under the MIT License.

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
- **Floor Buttons**: A floor button registers its floor the moment a finger touches it (screen readers use their tap action), and a long press or a double tap cancels it, except the moving car's next stop when no selected floor lies beyond it
- **Top Floor Display**: The top floor always displays as R, whatever floor number it is set to
- **Top Floor Announcement**: Arriving at the top floor speaks only the room name, not a floor number, for the same reason

## 🚀 Technology Stack

### Frameworks & Libraries
- **Flutter**: 3.47.0+
- **Dart**: 3.13.0+
- **Firebase**: firebase_core, firebase_analytics, firebase_remote_config
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
- **Floor images**: the moving floor column keeps the height of every floor but places panels only for the few floors around the car (`lib/floor_window.dart`)
- **Floor image store**: the pictures those panels show are held app-wide (`lib/floor_image_store.dart`), and the loading spinner stays until they are read, at launch and on returning from settings
- **Floor photos**: a photo is saved at most 1512 × 2688 (`lib/photo_manager.dart`), and only photos are decoded at the size they are drawn: the room's width at the largest zoom (`floorImageMaxScale`) on the floor column, and the thumbnail's width in settings
- **Saved photo paths**: a photo is copied into the app's Documents folder and stored by file name only, while bundled images keep their asset path; on reading, the file name is joined to the current Documents path, and a missing file falls back to that slot's initial bundled image (`lib/image_manager.dart`)
- **Links**: url_launcher
- **Store Review**: in_app_review
- **Splash**: flutter_native_splash
- **Launch splash**: held for at least 3 seconds from launch (`lib/splash_hold.dart`); when initialization takes longer, it goes as soon as that finishes
- **Launch splash drawing**: iOS keeps the native splash; Android draws the same splash in Flutter (`SplashOverlay`), which blocks touches until it is removed
- **Ads and consent**: the banner's consent request and ad request start after the launch splash is removed

`flutter_tts` is a path dependency, not the pub.dev package.
The fork adds Swift Package Manager manifests and an Android Gradle Plugin 9 build, and `pubspec.yaml` records exactly what differs from the published 4.2.5.

## 📋 Prerequisites

- Flutter 3.47.0+ (required by Android Gradle Plugin 9: earlier versions force the Kotlin Gradle Plugin onto modules that AGP 9 compiles itself)
- Dart 3.13.0+
- Android Studio / Xcode
- A Firebase project (Analytics, and Remote Config for coupon codes and the cross-promo notice), since `main.dart` calls `Firebase.initializeApp` at startup
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
Release builds read the production AdMob banner and rewarded ad unit ids from this file, and stop with a reason if one for their platform is missing, is not an ad unit id, or is one of Google's demo units (publisher `ca-app-pub-3940256099942544`).
They also stop if `assets/.env` holds a key starting with `APPCHECK_`, or if one is passed with `--dart-define` or `--dart-define-from-file`.
Gradle runs these checks for Android, and the Xcode build phase `Verify release config` runs them for iOS.
Debug and profile builds use Google's demo ad units, and the demo unit for an inline adaptive request is not the same id as the fixed-size one.

**Android signing, release only.** The signing file lives outside the repository, at `~/key/keystore/key.properties` or at the path in the `ANDROID_KEY_PROPERTIES` environment variable.
Use `android/key.properties.example` as the template.
Nothing in it ships inside the app, and the two passwords are real secrets: together with the keystore they let anyone publish an update Play accepts as coming from you.
Keep the keystore outside the repository and back both up.
Only release builds read this file, so debug, profile, `flutter test` and `flutter analyze` do not need it.
Build the release with `flutter build appbundle`.
If you run Gradle yourself, give the full task name `assembleRelease` or `bundleRelease`, because an abbreviation such as `bR` stops the build.
A release build stops with a reason if the file cannot be read, a value is missing, or `storeFile` is not an absolute path.

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
├── floor_window.dart            # Which floors around the car get a panel, and the photo decode width
├── floor_image_store.dart       # Floor images held app-wide
├── photo_manager.dart           # Gallery selection and cropping
├── analytics_manager.dart       # Firebase Analytics events
├── coupon_manager.dart          # Coupon code check against Remote Config
├── remote_config_setup.dart     # Remote Config settings and defaults, applied once
├── promo/                       # Cross-promo notice for LETS ELEVATOR ADVENTURE
│   ├── promo_banner.dart        # Notice card under the menu grid, with its close button
│   ├── promo_layout.dart        # Card sizes from the screen size
│   ├── promo_card_text.dart     # Heading and body fitting, and whether the card fits
│   ├── promo_video.dart         # Muted animated WebP playback and still image
│   ├── promo_links.dart         # Store links and platform switches
│   ├── promo_store.dart         # Native store sheet and installed check calls
│   ├── promo_config.dart        # Remote Config values for the notice
│   ├── promo_session.dart       # Launch steps and installed check
│   ├── promo_prefs.dart         # Stored counters and close records
│   └── promo_buckets.dart       # Analytics event buckets
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
│   ├── promo/                  # Cross-promo notice videos, stills and the ADVENTURE logo
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
A premium launch re-checks the entitlement with RevenueCat after the splash and removes the unlock when it is gone (a refund); an unreachable RevenueCat keeps it.
A free device that opens settings asks RevenueCat once per visit and unlocks premium when the store already holds the purchase (a new device needs no Restore tap); an unreachable RevenueCat leaves the app free.

- Removes the banner ad and opens every lock at once
- Reached from the fourth menu tile, and from any padlock in settings
- The tile is dropped once premium is owned, or while no store price is known
- Restoring is offered on the same page, as the store guidelines require
- The page stays open until the purchase or restore leaves the user premium, so a cancelled or failed purchase can be retried at once
- While the store answers, a loading cover takes every tap, and the close button and the back gesture do nothing

Once the SDK is configured, every RevenueCat customer info update that carries the premium entitlement unlocks premium on the home screen.

### Coupon codes

A coupon sells the same entitlement at a discounted price.

- **iOS**: an App Store Connect offer code for `elevatorneo_premium_unlock`, redeemed in the App Store (`https://apps.apple.com/redeem?ctx=offercodes&id=6479341144&code=CODE`)
- **Android**: `CouponManager.check` (`lib/coupon_manager.dart`) matches a typed code, and `PurchaseManager.buyPremium(couponId:)` sells the package of the RevenueCat offering `coupon` (`couponOfferingId` in `lib/purchase_manager.dart`)

RevenueCat setup for Android: the product `elevatorneo_premium_unlock_coupon` is attached to the entitlement `elevatorneo_premium` and placed in an offering with the identifier `coupon`, which must not be the current offering.
Before the coupon purchase starts, the app sets the subscriber attribute `coupon_id` to the matched code's `id`.

The codes live in the Firebase Remote Config parameter `coupon_codes`, a JSON string:

```json
{"codes": [{"id": "coupon_001", "sha256": "<lowercase hex SHA-256 of the code>", "expires": "2026-12-31"}]}
```

- A code is 12 characters from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`, so 0, O, 1 and I never appear
- Typed codes are normalized before hashing: full-width ASCII characters (U+FF01 to U+FF5E) become half-width, every space is dropped, and letters are upper-cased
- The hash of a code is `printf %s CODE | shasum -a 256`
- A code is valid through its `expires` date, read on the device's calendar
- An empty parameter rejects every code; a failed fetch with no value already on the device makes the check return `unavailable`
- Remote Config is fetched when a code is checked, with the settings of `lib/remote_config_setup.dart` (10 s timeout, at most once an hour)

Analytics events (`lib/analytics_manager.dart`): `couponEntryOpened` logs `coupon_entry_opened` with no parameters, and every `CouponManager.check` logs `coupon_code_checked` with `result` set to `valid`, `invalid` or `unavailable`.
Register `result` as a custom dimension in GA4 to report it.

## 📣 Cross-Promo Notice

The menu shows a notice card under the tile grid that promotes LETS ELEVATOR ADVENTURE.
On the left is a silent video at 3:4, shown whole inside its box (`BoxFit.contain`).
On the right, from top to bottom, are a heading, the ADVENTURE name logo, a short description and a button.
A round close button sits at the top right of the card.
The card is one button: tapping anywhere on it except the close button opens the store page of ADVENTURE.
On Android it opens the Google Play inline install sheet, and when that cannot be opened it opens the Play store page by URL outside the app.
On iOS it opens the App Store sheet inside the app, and when that cannot be opened it opens the App Store URL outside the app.

Files: `lib/promo/` holds the card (`promo_banner.dart`), its sizes (`promo_layout.dart`), its text fitting (`promo_card_text.dart`), the video (`promo_video.dart`), the store links and the native calls (`promo_links.dart`, `promo_store.dart`), the Remote Config values (`promo_config.dart`), the launch steps and the installed check (`promo_session.dart`), the stored counters and close records (`promo_prefs.dart`) and the event buckets (`promo_buckets.dart`).
The menu wiring is in `lib/menu.dart`.

### When the notice is shown

The notice is shown only when all of these hold:

- The platform switch is on.
  Android uses `promoAndroidEnabled` in `lib/promo/promo_links.dart`.
  iOS uses `promoIosEnabled`, and also needs a non-empty `promoAdventureIosAppId` and `promoAdventureIosPt`, so it stays off until both are filled in.
- Remote Config `promo_menu_enabled` is true.
- The installed check below has ended and found that ADVENTURE is not installed on the device.
  The check runs after the Remote Config fetch at launch, and no card is built before it ends (`PromoSession.installedChecked` in `lib/promo/promo_session.dart`).
- The card has not been closed today, and has been closed fewer than three times on this device (see "Close button" below).
- The card fits on the screen (see "Card size and text" below).

With the card, the tile grid sits at the top of the space and the card under it.
Without the card, the grid is centred in the space with wider gaps between its rows.

The installed check uses the platform:

- Android asks the native side whether the package `nakajimamasao.appstudio.elevator3d` exists.
  That package must stay in the `<queries>` block of `android/app/src/main/AndroidManifest.xml`, or Android hides it.
- iOS calls `canLaunchUrl` on `nakajimamasao.appstudio.elevator3d://`.
  The same string must stay in `LSApplicationQueriesSchemes` in `ios/Runner/Info.plist`.
  `promoAdventureIosUrlName` in `promo_links.dart` holds that name, but the link builders do not use it.

The check runs at launch and again each time the app is resumed.
Once ADVENTURE is found, the notice is removed from the menu.

For development, `flutter run --dart-define=PROMO_FORCE_IOS=true` turns on the iOS notice in a debug build.
The define has no effect in profile or release builds.
Until the iOS app ID and provider token are filled in, a tap on the iOS notice does not open a store page.

### Card size and text

Every size of the card comes from `PromoLayout` (`lib/promo/promo_layout.dart`), which works only from the screen width and height, so the card keeps its proportions on every device.
The card is centred and as wide as the screen allows, up to a cap.
The video is as tall as both the room under the grid and a minimum width for the text column allow, and the text column takes the rest of the card's width.

`planPromoCard` (`lib/promo/promo_card_text.dart`) measures the text with the app's font and decides what the column shows:

- The heading (`promoHeading`) stays on one line and shrinks to fit in Japanese and Chinese, and takes up to two lines in the other languages.
  A heading that needs more than two lines leaves the card out.
- The body is the full text (`promoBody`) when it fits, then the short text (`promoBodyShort`), and otherwise no body.
  A body fits when the space left between the rows of the column stays above a fixed minimum.
- When even the heading, the logo and the button do not fit with that spacing, the card is not shown.
- Japanese breaks lines only between the phrases in `jaBodyPhrases` and `jaBodyShortPhrases`, which must join to exactly the texts in `app_ja.arb`; otherwise the body is measured as one line.
  The other languages break where Flutter's text layout breaks.
- The card ignores the system font size setting, so the drawn text matches the measured text.

The card's texts are the `promoHeading`, `promoBody`, `promoBodyShort`, `promoButton`, `promoAdventureName` and `promoClose` keys in `lib/l10n/app_*.arb`.
The name logo shows the app name, so `promoAdventureName` is read only by screen readers, as part of the card's label.
`promoClose` is the screen reader label of the close button.

### Close button

Tapping the close button removes the card at once and never opens the store.
The card stays away for the rest of that day by the device's local date, and comes back the next time the menu opens on a later day.
After the third close, the card is not shown on that device again.
The close count and the date of the last close are stored under `adventureDismissCountKey` and `adventureDismissedDateKey` (`lib/promo/promo_prefs.dart`), and the app never resets the count.

### Remote Config

The app reads three keys, with the defaults given in `PromoConfig` (`lib/promo/promo_config.dart`).
The app uses these defaults until a fetch succeeds.

- `promo_menu_enabled` (boolean, default `true`): turns the notice on or off.
- `promo_video_patterns` (string, default `p1,p2,p3`): the video patterns to play, separated by commas, in play order.
  Unknown names and repeated names are dropped, and when nothing valid is left all patterns play.
- `promo_video_enabled` (boolean, default `true`): when false, the notice shows only the still image.

The fetch runs at launch, after the first frame, and only when the platform switch is on.
The fetch waits at most 10 seconds (`fetchTimeout`).
The app asks the server only when the last fetch is more than 1 hour old (`minimumFetchInterval`), so a change reaches a device on the first launch after that.
When the fetch fails or times out, the values stay at their defaults for that launch.
The menu reads the values when it builds, so a value that arrives later applies on the next build.

`firebase_remote_config` is pinned to `7.0.1` in `pubspec.yaml`, next to the other pinned Firebase packages.
The pins match the Firebase iOS SDK that `firebase_core` 5.1.0 uses.
When one Firebase version changes, change `firebase_core`, `firebase_analytics` and `firebase_remote_config` together.

The settings (fetch timeout and interval) and the defaults for all keys, including `coupon_codes`, are set once in `lib/remote_config_setup.dart` (`ensureRemoteConfigReady()`).
Add a new Remote Config key there, and do not call `setDefaults` from anywhere else, because a second call replaces the first one's defaults.

### Video

The notice plays three patterns, `p1`, `p2` and `p3`, from `assets/images/promo/`.
Each pattern is an animated WebP at 864x1152 (3:4) with no sound, and each has a `_still` image of its first frame at the same size (`p1_still.webp` and so on).
Frames are 67 ms apart (about 15 fps), and where the same picture repeats, `img2webp` merges it into one longer frame.
The list of known pattern names is `PromoConfig.allPatterns`, so a new pattern needs a new file and a new name in that list.
The name logo is `assets/images/promo/adventure_logo.png`, a 708x200 PNG; the card sizes it for that aspect ratio, so a replacement has to keep it.

- The frames are decoded one at a time with `dart:ui` `Codec`.
  No video plugin or audio session is used, so the sound of other apps keeps playing.
- The animation stops when the app is not in front or when the ticker is off, and it resumes where it stopped.
- The still image is shown instead of the animation when the device asks for reduced motion or when `promo_video_enabled` is false.
- Each time a pattern starts, the next pattern is saved, so the next menu opening starts from there.

To make new files, extract the frames at 864x1152 and encode them with the commands below.
Replace the placeholders with your own source file, start time, frame count and crop.
Crop to 3:4 before scaling.

```bash
# Extract frames as PNG at 15 fps, cropped to 3:4 and scaled to 864x1152
ffmpeg -ss <start-seconds> -i <source-file> -frames:v <frame-count> \
  -vf "fps=15,crop=<w>:<h>:<x>:<y>,scale=864:1152:flags=lanczos" f%03d.png

# Animated WebP: 67 ms per frame (about 15 fps), loops forever, lossy quality 75, every frame a keyframe
img2webp -loop 0 -kmax 1 -lossy -q 75 -d 67 f*.png -o p1.webp

# Still image: the first frame
cwebp -q 80 f001.png -o p1_still.webp
```

Do not use `-min_size`: it writes partial frames that the Flutter engine cannot decode, and the animation stops.
`test/promo_assets_test.dart` decodes every frame of the bundled files and checks that each is 864x1152, so run it after re-encoding.

Check each animated file with `webpmux -info`: every frame duration should be a multiple of 67 ms and the loop count 0.

### Analytics events

The events go through `AnalyticsManager` (the Cross-Promo Events section of `lib/analytics_manager.dart`) to Firebase Analytics.
Counts are sent as bucket names from `lib/promo/promo_buckets.dart` (for example launch count `1`, `2`, `3_5`, `6_20` or `21_plus`), and booleans are sent as `0` or `1`.

- `cross_promo_shown`: sent each time the notice appears on the menu, with the launch, ride, day and shown-count buckets, the language, the first pattern, `video_mode` (`video` or `still`) and `body_form`.
  `body_form` is the body the card shows: `full`, `short` or `none`.
- `cross_promo_video_played`: sent once per pattern run, with `completed` set to `1` after the last frame or `0` when the notice leaves before it.
  Pausing does not end a run.
- `cross_promo_tapped`: sent after each tap, once the store open has been tried, with the values of `cross_promo_shown`, the pattern and position of the video, the patterns seen, the visible time, `target_area` (`video`, `text` or `button`), `open_method` set to `sheet`, `market`, `url` or `none`, and `opened`.
- `cross_promo_dismissed`: sent when the close button removes the card, with the values of `cross_promo_shown`, `method` set to `close_x`, `dismiss_count` (this device's close count including this close), and the pattern and position of the video, the patterns seen and the visible time at that moment.
- `cross_promo_store_returned`: sent once after a tap, when the user comes back from the store.
  On iOS the sheet reports `storeClosed`; the other methods count the app resuming.
- `cross_promo_view_ended`: sent when the notice leaves the menu, with the visible time bucket, the patterns seen, whether it was tapped, and `dismissed` set to `1` when the close button removed it.
- `cross_promo_target_found`: sent once per device, the first time ADVENTURE is seen installed.

### Native channel

The Dart side and the native side talk over the method channel `nakajimamasao.appstudio/store_promo`.

- Android (`MainActivity.kt`): `isInstalled` with no arguments returns a boolean.
  `openPlay` with a `url` argument opens the Play inline install and returns `false` when no activity can take the intent.
  The intent targets the package `com.android.vending`.
- iOS (`AppDelegate.swift`): `openAppStore` with `appId`, `ct` and `pt` shows the store sheet and returns whether the product loaded.
  The native side sends `storeClosed` to Dart when the user closes the sheet.

The store links are built in `promo_links.dart`:

- Android inline install: `https://play.google.com/d?id=nakajimamasao.appstudio.elevator3d&referrer=...`, where the referrer carries `utm_source` (the app name), `utm_medium=in_app` and `utm_campaign` (the placement, `menu`).
- Android store page: the same package and referrer on `https://play.google.com/store/apps/details`.
- iOS store page: `https://apps.apple.com/app/id<appId>?pt=<pt>&ct=promo_menu&mt=8`.


## 📱 Supported Platforms

- **Android**: API 29+ (Android 10, `minSdkVersion 29` in `android/app/build.gradle`), compiled and targeted at API 37
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
- firebase_core, firebase_analytics, firebase_remote_config (BSD 3-Clause License)
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
- crypto (BSD 3-Clause License)
- webview_flutter (BSD 3-Clause License), pulled in by google_mobile_ads
- cupertino_icons (MIT License)
- flutter_svg (MIT License), draws the star padlock in settings
- flutter_launcher_icons (MIT License)
- flutter_native_splash (MIT License)
- image_picker (BSD 3-Clause License)
- image_cropper (BSD 3-Clause License)
- path, path_provider (BSD 3-Clause License)
- intl (BSD 3-Clause License)
- flutter_localizations (BSD 3-Clause License)

For details of each license, please refer to [pub.dev](https://pub.dev/) or the LICENSE file in each repository.

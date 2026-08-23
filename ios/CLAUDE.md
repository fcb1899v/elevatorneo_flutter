# ios/CLAUDE.md

Guidance for iOS / SPM / Game Center.

## Rules

- **Swift Package Manager only**. Do not restore `Podfile` / `Pods/` / CocoaPods
- Do not run `pod install`
- Do not paste `GoogleService-Info.plist` contents into chat
- Do not remove entitlements (Game Center, etc.) without a clear reason

## SPM

- `pubspec.yaml` has `enable-swift-package-manager: true`
- Plugins come through `Flutter/ephemeral/Packages/` (do not hand-edit generated files)
- `flutter_tts` is a git dependency for SPM. Switching to pub.dev-only can bring CocoaPods back

## Permissions

- Manage photo access etc. via UsageDescription keys in `Runner/Info.plist`
- Do not restore the old Podfile `PERMISSION_PHOTOS=1` approach (permission_handler resolves from Info.plist under SPM)

## Verification

```bash
flutter build ios --simulator --no-codesign
# Confirm Podfile / Pods were not regenerated
ls ios/Podfile ios/Pods 2>&1
```

# CLAUDE.md

Elevator simulator app (Flutter) for iOS and Android.

## Stack

- Flutter + hooks_riverpod + flutter_hooks
- Firebase (Analytics, App Check)
- AdMob / App Tracking Transparency
- games_services (Play Games / Game Center)
- just_audio, flutter_tts, vibration
- iOS dependencies use **Swift Package Manager only** (no CocoaPods)

## Hard rules

- Do not commit or push unless the user explicitly asks
- Do not read or output secrets (`key.properties`, keystores, `.env`, certificates)
- Do not use `git push --force`, `git reset --hard`, or destructive `rm -rf`
- Keep changes minimal; avoid unrelated refactors or extra files
- Explain to the user in Japanese

## Directories

| Path | Contents |
|------|----------|
| `lib/` | App code |
| `lib/l10n/` | Localization (ARB) |
| `android/` | Android / Play Games / Firebase |
| `ios/` | iOS / SPM / Game Center |
| `assets/` | Images, audio, `.env` (public IDs only) |
| `claude/settings.json` | Claude Code permission deny list |

## Verification commands

```bash
flutter analyze
flutter test
flutter build ios --simulator --no-codesign
flutter build appbundle
```

## Project-specific notes

- Play Games: SHA-1 differs for debug / upload / **Play App Signing**. Do not mix them up
- Firebase production: register the Play Console app signing certificate (SHA-256)
- `flutter_tts` uses a **git dependency** for SPM support; do not casually switch back to pub.dev-only
- Do not restore `Podfile` / `Pods/` on iOS
- Leaderboard IDs and ad unit IDs are not secrets, but keep `.env` out of git

## Nested CLAUDE.md files

Also read the CLAUDE.md closest to the files you edit:

- `lib/CLAUDE.md`
- `lib/l10n/CLAUDE.md`
- `android/CLAUDE.md`
- `ios/CLAUDE.md`
- `assets/CLAUDE.md`

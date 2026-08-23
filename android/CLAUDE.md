# android/CLAUDE.md

Guidance for Android / Play / Firebase.

## Rules

- Do not read, print, or commit `key.properties` or keystores
- Do not paste `google-services.json` contents into chat
- Raising `compileSdk` to match plugin requirements is fine (backward compatible)
- applicationId / namespace: `nakajimamasao.appstudio.letselevatorneo`

## Signing and SHA (important)

| Use case | Key to use |
|----------|------------|
| Development (`flutter run`) | `~/.android/debug.keystore` |
| AAB upload | `upload-keystore.jks` (upload key) |
| Play Store installed builds | **Play App Signing key** (Play Console) |

- Play Games OAuth mainly needs **SHA-1**
- Firebase needs **SHA-1 and/or SHA-256**
- After a PC wipe, debug SHA changes. Do not delete existing production SHAs

## games-ids / leaderboards

- Keep `res/values` games / leaderboard IDs aligned with `assets/.env`
- Keep Play Console app ID and OAuth client package name in sync

## Verification

```bash
flutter build appbundle
# SHA example (paths vary by machine)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

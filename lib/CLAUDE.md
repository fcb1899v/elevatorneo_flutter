# lib/CLAUDE.md

Guidance for Dart / UI / business logic.

## File map

| File | Role |
|------|------|
| `main.dart` | Startup, Firebase, Provider setup |
| `homepage.dart` | Main elevator screen |
| `menu.dart` / `settings.dart` | Menu and settings |
| `games_manager.dart` | Play Games / Game Center |
| `audio_manager.dart` / `tts_manager.dart` | Sound effects and TTS |
| `photo_manager.dart` / `image_manager.dart` | Photos and images |
| `admob_*.dart` | Ads |
| `constant.dart` / `extension.dart` / `l10n_extension.dart` / `common_widget.dart` | Constants, extensions, l10n, shared UI |

## Rules

- Follow existing naming and hooks_riverpod / flutter_hooks style
- Keep constants in `constant.dart`
- Split extensions: `extension.dart` (UI/shared) and `l10n_extension.dart` (strings)
- Do not hardcode user-facing strings. **Use `context.xxx()` from `l10n_extension.dart` in UI**
- Do not call `AppLocalizations.of(context)!` directly in widgets (use extension methods)
- When adding copy: ARB → `l10n_extension.dart` → call site
- Do not break `games_manager` sign-in state and score persistence
- Do not casually change ad / Analytics initialization order
- Add new files only when necessary; prefer editing existing files

## When touching this code

- Run `flutter analyze`
- If you change game integration, verify score fetch/submit on successful sign-in

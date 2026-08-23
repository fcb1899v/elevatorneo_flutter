# assets/CLAUDE.md

Guidance for static assets.

## Rules

- `.env` is **not tracked in git**. Do not print its contents in chat
- Put only public client IDs in `.env` (ad units, leaderboard IDs, etc.)
- Never store passwords, API secrets, or service accounts here
- When adding images/audio, also update `assets:` in `pubspec.yaml`
- Avoid unnecessary large binary additions or conversions

## `.env` handling

- Values are mostly non-critical public IDs (AdMob / leaderboard)
- Still keep them out of the repo (`claude/settings.json` denies Read)
- If you rename keys, update `flutter_dotenv` usages in `lib/` at the same time

## Audio and images

- Follow existing layout (`audios/`, `images/button|elevator|room|menu|settings/`)
- When renaming files, update references in `lib/` together

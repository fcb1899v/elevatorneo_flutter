# lib/l10n/CLAUDE.md

Guidance for localization resources.

## How this project loads strings

Wrap `AppLocalizations.of(this)!` in **`L10nContextExt` in `lib/l10n_extension.dart`**, and call `context.xxx()` from UI.

```dart
// l10n_extension.dart (definition)
String openDoor() => AppLocalizations.of(this)!.openDoor;
String floor(String number) => AppLocalizations.of(this)!.floor(number);

// homepage.dart etc. (usage) — importing extension.dart is enough
Text(context.openDoor());
Text(context.floor('$n'));
```

- Do not call `AppLocalizations.of(context)!` directly in widgets
- Always add an extension method in `l10n_extension.dart` for new strings
- `l10n_extension.dart` is a `part` of `extension.dart` (`import 'extension.dart'` still works)

## Rules

- **Edit only `app_*.arb` files** (`app_en.arb` is the source of truth)
- `app_localizations*.dart` are generated; do not edit by hand
- Keep key names in existing camelCase style
- Add the same keys to all locales (en / ja / zh / ko / es / fr)
- Keep placeholders / ICU syntax consistent across locales

## Steps (add a string)

1. Add the key to `app_en.arb`
2. Add the same key with translations to other `app_*.arb` files
3. Run `flutter gen-l10n` (or build) to regenerate
4. Add to `lib/l10n_extension.dart`:  
   `String foo() => AppLocalizations.of(this)!.foo;`
5. Call `context.foo()` from UI

## Do not

- Edit generated `app_localizations*.dart`
- Add a key to only one locale
- Update ARB without updating `l10n_extension.dart`
- Write `AppLocalizations.of(context)!` directly in UI code

// The album-select button inside the floor image picker dialog, at a narrow
// dialog width, in the language with the longest label (fr).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/l10n/app_localizations.dart';
import 'package:letselevatorneo/settings.dart';

// Matches the narrowest AlertDialog content width the app renders on an
// iPhone SE (375 logical px, minus AlertDialog's default insetPadding).
const _dialogWidth = 280.0;

void main() {
  testWidgets("the album-select label does not overflow in fr", (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale("fr"),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(builder: (context) {
          capturedContext = context;
          return SizedBox(
            width: _dialogWidth,
            child: SettingsWidget(context,
              point: 0,
              roomImages: const [],
              floorNumbers: const [1],
              floorStops: const [true],
              buttonStyle: 0,
              buttonShape: "normal",
              glassStyle: "normal",
              backgroundStyle: "normal",
              isPremium: true,
              onLockTap: (_, _) {},
            ).floorImageFromMyAlbumButton(onTap: () {}),
          );
        }),
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppLocalizations.of(capturedContext)!.selectPhoto), findsOneWidget);
  });
}

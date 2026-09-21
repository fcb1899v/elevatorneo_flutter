// The purchase page in all six languages with the app's own fonts: the default test font
// draws every glyph a full em wide. premiumUnlockAll breaks first, wrapping into a fourth line.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/l10n/app_localizations.dart';
import 'package:letselevatorneo/premium_page.dart';

Future<void> _loadFonts() async {
  const families = {
    "roboto": "assets/fonts/Roboto-Bold.ttf",
    "notoJP": "assets/fonts/NotoSansJP-Bold.ttf",
    "notoSC": "assets/fonts/NotoSansSC-Bold.ttf",
    "bmDohyeon": "assets/fonts/bm-dohyeon.regular.ttf",
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key)..addFont(rootBundle.load(entry.value));
    await loader.load();
  }
}

// iPhone SE is the shortest screen iOS 17 still runs on
const _size = Size(375, 667);
const _languages = ["en", "es", "fr", "ja", "ko", "zh"];

/// The lines the engine actually laid out, not the \n count in the source.
/// RenderParagraph does not expose its metrics on this Flutter version, so the
/// same span is laid out again at the width the page gave it.
int _lineCount(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: find.byType(PremiumPage), matching: find.text(text)),
  );
  final painter = TextPainter(
    text: paragraph.text,
    textAlign: paragraph.textAlign,
    textDirection: paragraph.textDirection,
  )..layout(maxWidth: paragraph.size.width);
  return painter.computeLineMetrics().length;
}

void main() {
  setUpAll(_loadFonts);

  for (final lang in _languages) {
    testWidgets("the purchase page fits in $lang at 375x667", (tester) async {
      tester.view.physicalSize = _size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(lang),
        home: PremiumPage(
          price: "¥500",
          onBuy: () async {},
          onRestore: () async {},
        ),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull,
        reason: "the purchase page overflows in $lang");

      final l10n = await AppLocalizations.delegate.load(Locale(lang));
      expect(_lineCount(tester, l10n.premiumUnlockAll), lessThanOrEqualTo(3),
        reason: "premiumUnlockAll wraps past three lines in $lang");
    });
  }

  testWidgets("the purchase page fits with no price at 375x667", (tester) async {
    tester.view.physicalSize = _size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // An empty price replaces the buy button with the reason, which is longer
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale("ja"),
      home: PremiumPage(price: "", onBuy: () async {}, onRestore: () async {}),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    final l10n = await AppLocalizations.delegate.load(const Locale("ja"));
    expect(find.text(l10n.premiumUnavailable), findsOneWidget);
    expect(find.text(l10n.premiumBuy), findsNothing);
  });
}

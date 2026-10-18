// The purchase page stays open until the user is premium, and is locked while the store answers.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/l10n/app_localizations.dart';
import 'package:letselevatorneo/premium_page.dart';

const _price = "¥500";

/// A home page whose button opens the purchase page, so a close can be told from a page that never opened
Future<void> _open(WidgetTester tester, PremiumPage page) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale("ja"),
    home: Builder(builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page)),
        child: const Text("home"),
      ),
    )),
  ));
  await tester.tap(find.text("home"));
  await tester.pumpAndSettle();
  expect(find.byType(PremiumPage), findsOneWidget);
}

Finder _buy() => find.textContaining(_price);
Finder _restore(WidgetTester tester) =>
  find.text(AppLocalizations.of(tester.element(find.byType(PremiumPage)))!.premiumRestore);

void main() {
  testWidgets("a purchase that ends free keeps the page, and the next tap buys again", (tester) async {
    var buys = 0;
    await _open(tester, PremiumPage(
      price: _price,
      onBuy: () async => buys++,
      onRestore: () async {},
      isPremium: () => false,
    ));
    await tester.tap(_buy());
    await tester.pump();
    expect(find.byType(PremiumPage), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(_buy());
    await tester.pump();
    expect(buys, 2);
    expect(find.byType(PremiumPage), findsOneWidget);
  });

  testWidgets("a restore that finds nothing keeps the page", (tester) async {
    var restores = 0;
    await _open(tester, PremiumPage(
      price: _price,
      onBuy: () async {},
      onRestore: () async => restores++,
      isPremium: () => false,
    ));
    await tester.tap(_restore(tester));
    await tester.pump();
    expect(restores, 1);
    expect(find.byType(PremiumPage), findsOneWidget);
  });

  for (final isRestore in [false, true]) {
    testWidgets("a ${isRestore ? 'restore' : 'purchase'} that ends premium closes the page", (tester) async {
      var premium = false;
      await _open(tester, PremiumPage(
        price: _price,
        onBuy: () async => premium = true,
        onRestore: () async => premium = true,
        isPremium: () => premium,
      ));
      await tester.tap(isRestore ? _restore(tester) : _buy());
      await tester.pumpAndSettle();
      expect(find.byType(PremiumPage), findsNothing);
      expect(find.text("home"), findsOneWidget);
    });
  }

  testWidgets("a purchase that throws still ends with the page unlocked", (tester) async {
    await _open(tester, PremiumPage(
      price: _price,
      onBuy: () async => throw StateError("store down"),
      onRestore: () async {},
      isPremium: () => false,
    ));
    // The page does not swallow the error, so it surfaces in the zone the tap ran in
    final errors = <Object>[];
    await runZonedGuarded(() async {
      await tester.tap(_buy());
      await tester.pump();
    }, (error, _) => errors.add(error));
    expect(errors.single, isA<StateError>());
    expect(find.byType(PremiumPage), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets("while the store answers, buy, restore, close and back do nothing", (tester) async {
    final pending = Completer<void>();
    var buys = 0, restores = 0;
    await _open(tester, PremiumPage(
      price: _price,
      onBuy: () { buys++; return pending.future; },
      onRestore: () async => restores++,
      isPremium: () => false,
    ));
    await tester.tap(_buy());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // The loading cover takes the taps, so the page below hears nothing
    await tester.tap(_buy(), warnIfMissed: false);
    await tester.tap(_restore(tester), warnIfMissed: false);
    await tester.tap(find.byIcon(Icons.close), warnIfMissed: false);
    await tester.pump();
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    // A pop starts its route transition on the next frame, so two pumps are needed before the page can be gone
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(buys, 1);
    expect(restores, 0);
    expect(find.byType(PremiumPage), findsOneWidget);

    pending.complete();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(PremiumPage), findsOneWidget);
  });

  testWidgets("once the store has answered, the close button works again", (tester) async {
    await _open(tester, PremiumPage(
      price: _price,
      onBuy: () async {},
      onRestore: () async {},
      isPremium: () => false,
    ));
    await tester.tap(_buy());
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(PremiumPage), findsNothing);
  });
}

// The purchase button is drawn only from a real store price, as soon as one arrives.
// No pumpAndSettle: the spinner animates while initState's network checks pend.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:letselevatorneo/constant.dart';
import 'package:letselevatorneo/l10n/app_localizations.dart';
import 'package:letselevatorneo/menu.dart';
import 'package:letselevatorneo/plan_provider.dart';
import 'package:letselevatorneo/purchase_manager.dart';

Future<void> pumpMenu(WidgetTester tester, String price) async {
  tester.view.physicalSize = const Size(768, 1024);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      planProvider.overrideWith(() => PlanNotifier(PlanState(priceString: price))),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const MenuPage(),
    ),
  ));
  // Well past any fetch the menu could start; the answers above do not depend on it
  await tester.pump(const Duration(seconds: 5));
}

final purchaseEntry = find.image(const AssetImage(purchaseButton));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(PurchaseManager.resetPrice);
  tearDown(PurchaseManager.resetPrice);

  testWidgets("no price: no purchase button", (tester) async {
    PurchaseManager.priceSource = () async => null;
    await pumpMenu(tester, "");
    expect(purchaseEntry, findsNothing);
    // Control: the menu itself was drawn
    expect(find.image(const AssetImage(settingsButton)), findsOneWidget);
  });

  testWidgets("price: the purchase button is drawn", (tester) async {
    PurchaseManager.priceSource = () async => "¥600";
    await pumpMenu(tester, "¥600");
    expect(purchaseEntry, findsOneWidget);
  });

  testWidgets("a price arriving while the menu is open brings the button in", (tester) async {
    // The store has not answered yet, and never does during this test
    PurchaseManager.priceSource = () => Completer<String?>().future;
    await pumpMenu(tester, "");
    expect(purchaseEntry, findsNothing);
    // The home screen's prefetch lands, as HomePage delivers it
    ProviderScope.containerOf(tester.element(find.byType(MenuPage)))
      .read(planProvider.notifier).setPrice("¥600");
    await tester.pump(const Duration(seconds: 5));
    expect(purchaseEntry, findsOneWidget);
  });
}

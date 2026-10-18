// The menu's purchase entry end to end: the purchase page closes only when the restore leaves the user premium.
// The store is a fake behind the RevenueCat channel, so the real runPurchase and the real plan state are used.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:letselevatorneo/constant.dart';
import 'package:letselevatorneo/l10n/app_localizations.dart';
import 'package:letselevatorneo/menu.dart';
import 'package:letselevatorneo/plan_provider.dart';
import 'package:letselevatorneo/premium_page.dart';
import 'package:letselevatorneo/purchase_manager.dart';

const _channel = MethodChannel('purchases_flutter');
const _price = "¥500";

/// What the store answers to a restore: [owned] decides whether the premium entitlement is active
Map<String, dynamic> _customer({required bool owned}) {
  final entitlement = {
    'identifier': premiumEntitlementID,
    'isActive': true,
    'willRenew': false,
    'latestPurchaseDate': '2026-10-01T00:00:00Z',
    'originalPurchaseDate': '2026-10-01T00:00:00Z',
    'productIdentifier': 'premium_product',
    'isSandbox': true,
    'ownershipType': 'PURCHASED',
    'store': 'PLAY_STORE',
    'periodType': 'NORMAL',
    'verification': 'NOT_REQUESTED',
  };
  final active = owned ? {premiumEntitlementID: entitlement}: <String, dynamic>{};
  return {
    'entitlements': {'all': active, 'active': active, 'verification': 'NOT_REQUESTED'},
    'allPurchaseDates': <String, dynamic>{},
    'activeSubscriptions': <String>[],
    'allPurchasedProductIdentifiers': <String>[],
    'nonSubscriptionTransactions': <dynamic>[],
    'firstSeen': '2026-10-01T00:00:00Z',
    'originalAppUserId': 'test_user',
    'allExpirationDates': <String, dynamic>{},
    'requestDate': '2026-10-01T00:00:00Z',
  };
}

void storeAnswers({required bool owned}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (call) async {
    if (call.method == 'isConfigured') return true;
    if (call.method == 'restorePurchases') return _customer(owned: owned);
    return null;
  });
}

/// Opens the menu, taps its purchase entry, and waits for the purchase page
Future<void> openPurchasePage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(768, 1024);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      planProvider.overrideWith(() => PlanNotifier(const PlanState(priceString: _price))),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const MenuPage(),
    ),
  ));
  // The menu opens with a real connectivity check, and its cover takes taps until that ends.
  // Fake time cannot end it, so wait in real time, bounded
  for (var i = 0; i < 150 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(find.byType(CircularProgressIndicator), findsNothing);
  await tester.tap(find.image(const AssetImage(purchaseButton)));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  expect(find.byType(PremiumPage), findsOneWidget);
}

Finder _restore(WidgetTester tester) =>
  find.text(AppLocalizations.of(tester.element(find.byType(PremiumPage)))!.premiumRestore);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(envString: "$revenueCatApiKey=test_key");
    PurchaseManager.resetPrice();
    PurchaseManager.resetStore();
    PurchaseManager.priceSource = () async => _price;
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_channel, null);
    PurchaseManager.resetPrice();
  });

  testWidgets("a restore that finds the purchase closes the purchase page and leaves the menu", (tester) async {
    storeAnswers(owned: true);
    await openPurchasePage(tester);
    await tester.tap(_restore(tester));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PremiumPage), findsNothing);
    expect(find.byType(MenuPage), findsOneWidget);
    expect(ProviderScope.containerOf(tester.element(find.byType(MenuPage))).read(planProvider).isPremium, isTrue);
  });

  testWidgets("a restore that finds nothing keeps the purchase page, and the user is not premium", (tester) async {
    storeAnswers(owned: false);
    await openPurchasePage(tester);
    await tester.tap(_restore(tester));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PremiumPage), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(ProviderScope.containerOf(tester.element(find.byType(MenuPage))).read(planProvider).isPremium, isFalse);
  });
}

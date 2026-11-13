// Checks that the menu builds the ADVENTURE notice only after the launch checks are done.
// A user who already has ADVENTURE must never see the notice open, and no shown event is sent for it.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:letselevatorneo/analytics_manager.dart';
import 'package:letselevatorneo/l10n/app_localizations.dart';
import 'package:letselevatorneo/menu.dart';
import 'package:letselevatorneo/plan_provider.dart';
import 'package:letselevatorneo/promo/promo_banner.dart';
import 'package:letselevatorneo/promo/promo_config.dart';
import 'package:letselevatorneo/promo/promo_session.dart';
import 'package:letselevatorneo/promo/promo_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Map<String, Uint8List> _assets = {};
final List<String> _events = [];

Future<Uint8List> _load(String name) async => _assets[name]!;

final _banner = find.byKey(const ValueKey('promoMenuBanner'));

/// Lets the preference reads and the pending calls finish, which need real time.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
}

/// Starts the installed check in real time and returns a wait for it to end.
/// It is the step of `PromoSession.start` that follows the Remote Config fetch, which needs Firebase and is left out here.
Future<Future<void> Function()> _startChecks(WidgetTester tester, {required bool premium}) async {
  late Future<void> start;
  await tester.runAsync(() async {
    start = PromoSession.refreshInstalled();
  });
  return () async {
    await tester.runAsync(() => start);
  };
}

Future<void> _openMenu(WidgetTester tester, {required bool premium}) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 48);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      planProvider.overrideWith(() => PlanNotifier(PlanState(isPremium: premium))),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      // Stacked as the home screen does: the menu body sits under the app bar.
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(toolbarHeight: 915 * 0.07, backgroundColor: Colors.black),
        body: const Stack(children: [MenuPage()]),
      ),
    ),
  ));
}

/// The menu opens with a real connectivity check, and its cover takes presses until that ends.
/// Fake time cannot end it, so wait in real time, bounded, so no timer outlives the test.
Future<void> _waitForCover(WidgetTester tester) async {
  for (var i = 0; i < 150 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final originalNative = PromoStore.invokeNative;
  final originalPlatform = PromoStore.platformSource;
  final originalSend = AnalyticsManager.send;
  late Completer<bool> installedAnswer;

  setUpAll(() async {
    for (final name in ['p1', 'p1_still', 'p2', 'p2_still']) {
      _assets[name] = await File('test/fixtures/$name.webp').readAsBytes();
    }
    _assets['p3'] = _assets['p1']!;
    _assets['p3_still'] = _assets['p1_still']!;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _events.clear();
    installedAnswer = Completer<bool>();
    AnalyticsManager.send = (name, parameters) async => _events.add(name);
    PromoStore.platformSource = () => 'android';
    // The installed check answers only when the test says so
    PromoStore.invokeNative = (method, args) => installedAnswer.future;
    PromoSession.reset();
    PromoSession.platformSource = () => 'android';
    PromoMenuBanner.loadAsset = _load;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('vibration'), (_) async => null);
    // The menu asks the consent SDK whether ads may be requested; the answer here is no.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'plugins.flutter.io/google_mobile_ads/ump', (message) async {
        final method = const StandardMessageCodec().readValue(ReadBuffer(message!));
        return (method == 'ConsentInformation#canRequestAds')
          ? const StandardMethodCodec().encodeSuccessEnvelope(false)
          : const StandardMethodCodec().encodeErrorEnvelope(code: '0', message: 'no UMP in tests');
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('plugins.flutter.io/google_mobile_ads/ump', null);
    PromoSession.reset();
    PromoConfig.reset();
    AnalyticsManager.send = originalSend;
    PromoStore.invokeNative = originalNative;
    PromoStore.platformSource = originalPlatform;
  });

  testWidgets('the installed check answers late with installed: the notice is never built and nothing is sent', (tester) async {
    final start = await _startChecks(tester, premium: true);
    await _openMenu(tester, premium: true);
    await _settle(tester);
    expect(_banner, findsNothing, reason: 'the notice is built while the installed check is pending');
    expect(_events, isNot(contains('cross_promo_shown')));

    installedAnswer.complete(true);
    await start();
    await _settle(tester);

    expect(PromoSession.installedChecked.value, isTrue);
    expect(PromoSession.adventureInstalled.value, isTrue);
    expect(_banner, findsNothing, reason: 'the notice is built for a user who has ADVENTURE');
    expect(_events, isNot(contains('cross_promo_shown')));
    expect(_events, isNot(contains('cross_promo_view_ended')));
    expect(tester.takeException(), isNull);
    await _waitForCover(tester);
  });

  testWidgets('the installed check answers late with not installed: the notice is built once, then', (tester) async {
    final start = await _startChecks(tester, premium: false);
    await _openMenu(tester, premium: false);
    await _settle(tester);
    expect(_banner, findsNothing, reason: 'the notice is built while the installed check is pending');
    expect(_events, isNot(contains('cross_promo_shown')));

    installedAnswer.complete(false);
    await start();
    await _settle(tester);

    expect(_banner, findsOneWidget);
    expect(_events.where((e) => e == 'cross_promo_shown'), hasLength(1));
    await _waitForCover(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a check that never started keeps the notice away', (tester) async {
    await _openMenu(tester, premium: false);
    await _settle(tester);
    expect(PromoSession.installedChecked.value, isFalse);
    expect(_banner, findsNothing);
    expect(_events, isNot(contains('cross_promo_shown')));
    await _waitForCover(tester);
  });
}

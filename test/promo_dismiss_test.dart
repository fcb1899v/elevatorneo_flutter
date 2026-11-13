// The close button of the menu card: the saved count and date, the day rule, and the close event.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/analytics_manager.dart';
import 'package:letselevatorneo/l10n/app_localizations.dart';
import 'package:letselevatorneo/promo/promo_banner.dart';
import 'package:letselevatorneo/promo/promo_card_text.dart';
import 'package:letselevatorneo/promo/promo_layout.dart';
import 'package:letselevatorneo/promo/promo_prefs.dart';
import 'package:letselevatorneo/promo/promo_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

final List<Map<String, Object?>> _events = [];

List<Map<String, Object?>> _named(String name) =>
    _events.where((event) => event['name'] == name).toList();

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

PromoMenuBanner _card({VoidCallback? onDismiss}) {
  final layout = PromoLayout(
    screenWidth: 402,
    screenHeight: 874,
    topInset: 62,
    bottomRowHeight: 874 / 8 - 25,
  );
  final plan = planPromoCard(
    layout: layout,
    lang: 'en',
    fontFamily: 'roboto',
    heading: 'Recommended',
    body: 'Call it, ride it and press the buttons as much as you like on a skyscraper adventure. A realistic 3D elevator simulator.',
    bodyShort: 'A realistic 3D elevator simulator',
  );
  return PromoMenuBanner(
    layout: layout,
    plan: plan,
    isPremium: false,
    patterns: const ['p1', 'p2', 'p3'],
    firstPattern: 'p1',
    stillOnly: true,
    onDismiss: onDismiss ?? () {},
  );
}

void _useSize(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Lets the saved values and the image decoding finish, which need real time.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

/// The saved close count, read straight from the preferences.
Future<int> _savedCount() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(PromoPrefs.adventureDismissCountKey) ?? 0;
}

/// The saved day of the last close, or null when none.
Future<String?> _savedDate() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(PromoPrefs.adventureDismissedDateKey);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _events.clear();
    AnalyticsManager.send = (name, parameters) async =>
        _events.add({'name': name, 'params': parameters});
    PromoMenuBanner.loadAsset = (name) async =>
        File('test/fixtures/p1.webp').readAsBytes();
    PromoStore.invokeNative = (method, args) async => true;
    PromoStore.urlLauncher = (uri) async => true;
    PromoStore.platformSource = () => 'android';
    PromoStore.storeClosedListener = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('vibration'), (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('vibration'), null);
  });

  group('saved close count and date', () {
    test('a close is saved with the local date', () async {
      final count = await PromoPrefs.recordAdventureDismiss(now: DateTime(2026, 11, 13, 22, 30));
      expect(count, 1);
      expect(await _savedCount(), 1);
      expect(await _savedDate(), '2026-11-13');
    });

    test('the date is written with zero padding', () {
      expect(PromoPrefs.dayText(DateTime(2026, 1, 2)), '2026-01-02');
    });

    test('the card is not allowed on the same day as a close, and is allowed the next day', () async {
      await PromoPrefs.recordAdventureDismiss(now: DateTime(2026, 11, 13, 22, 30));
      expect(await PromoPrefs.adventureNoticeAllowed(now: DateTime(2026, 11, 13, 23, 59)), isFalse);
      expect(await PromoPrefs.adventureNoticeAllowed(now: DateTime(2026, 11, 14, 0, 1)), isTrue);
    });

    test('a clock set back to an earlier day still allows the card', () async {
      await PromoPrefs.recordAdventureDismiss(now: DateTime(2026, 11, 13));
      expect(await PromoPrefs.adventureNoticeAllowed(now: DateTime(2026, 11, 12)), isTrue);
    });

    test('the third close stops the card for good', () async {
      await PromoPrefs.recordAdventureDismiss(now: DateTime(2026, 11, 13));
      await PromoPrefs.recordAdventureDismiss(now: DateTime(2026, 11, 14));
      final third = await PromoPrefs.recordAdventureDismiss(now: DateTime(2026, 11, 15));
      expect(third, 3);
      expect(await PromoPrefs.adventureNoticeAllowed(now: DateTime(2026, 11, 16)), isFalse);
      expect(await PromoPrefs.adventureNoticeAllowed(now: DateTime(2027, 6, 1)), isFalse);
    });

    test('a device with no saved close shows the card', () async {
      expect(await _savedCount(), 0);
      expect(await _savedDate(), isNull);
      expect(await PromoPrefs.adventureNoticeAllowed(now: DateTime(2026, 11, 13)), isTrue);
    });
  });

  group('close button of the card', () {
    testWidgets('closing removes the card, counts the close, and reports cross_promo_dismissed', (tester) async {
      _useSize(tester, 402, 874);
      var dismissed = false;
      await tester.pumpWidget(_app(_card(onDismiss: () => dismissed = true)));
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.close));
      await _settle(tester);

      expect(dismissed, isTrue);
      final count = await tester.runAsync(_savedCount);
      expect(count, 1);

      final events = _named('cross_promo_dismissed');
      expect(events, hasLength(1));
      final params = events.single['params'] as Map<String, Object?>;
      expect(params['method'], 'close_x');
      expect(params['dismiss_count'], '1');
      expect(params['target'], 'adventure');
      expect(params['placement'], 'menu');
      expect(params['video_pattern'], 'p1');
      expect(params['body_form'], isIn(['full', 'short', 'none']));
      expect(params['visible'], isNotNull);
      expect(params['patterns_seen'], isNotNull);
      expect(params['video_position'], isNotNull);
      expect(params['lang'], 'en');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a close is reported as dismissed in the view-ended event', (tester) async {
      _useSize(tester, 402, 874);
      await tester.pumpWidget(_app(_card()));
      await _settle(tester);
      await tester.tap(find.byIcon(Icons.close));
      await _settle(tester);

      await tester.pumpWidget(const SizedBox());
      await _settle(tester);
      final ended = _named('cross_promo_view_ended');
      expect(ended, hasLength(1));
      expect(ended.single['params'] as Map, containsPair('dismissed', 1));
    });

    testWidgets('pressing the card does not count as a close', (tester) async {
      _useSize(tester, 402, 874);
      await tester.pumpWidget(_app(_card()));
      await _settle(tester);

      await tester.tap(find.text('Recommended'));
      await _settle(tester);

      final count = await tester.runAsync(_savedCount);
      expect(count, 0);
      expect(_named('cross_promo_dismissed'), isEmpty);
      await tester.pumpWidget(const SizedBox());
    });
  });
}

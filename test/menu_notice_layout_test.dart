// The menu notice card takes its size from PromoLayout; it is shown only when the plan fits and the card is allowed.
// Checks the three cases: shown with room, hidden when the notice is installed, and hidden when the screen is too short.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:letselevatorneo/analytics_manager.dart';
import 'package:letselevatorneo/constant.dart';
import 'package:letselevatorneo/l10n/app_localizations.dart';
import 'package:letselevatorneo/extension.dart';
import 'package:letselevatorneo/menu.dart';
import 'package:letselevatorneo/plan_provider.dart';
import 'package:letselevatorneo/promo/promo_layout.dart';
import 'package:letselevatorneo/promo/promo_prefs.dart';
import 'package:letselevatorneo/promo/promo_session.dart';
import 'package:letselevatorneo/promo/promo_video.dart';
import 'package:letselevatorneo/purchase_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _settings = find.image(const AssetImage(settingsButton));
final _notice = find.byKey(const ValueKey('promoMenuBanner'));
final _card = find.byKey(const ValueKey('promoCard'));
final _close = find.byKey(const ValueKey('promoClose'));

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  required bool installed,
  double topInset = 0,
  String locale = 'en',
  bool checked = true,
  bool premium = false,
  double bottomInset = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = FakeViewPadding(top: topInset, bottom: bottomInset);
  tester.view.viewPadding = FakeViewPadding(top: topInset, bottom: bottomInset);
  addTearDown(tester.view.reset);
  PromoSession.platformOverride = () => true;
  PromoSession.adventureInstalled.value = installed;
  PromoSession.installedChecked.value = checked;
  addTearDown(() {
    PromoSession.installedChecked.value = false;
    PromoSession.platformOverride = null;
    PromoSession.adventureInstalled.value = false;
  });
  PurchaseManager.priceSource = () async => null;
  // The menu is stacked as the home screen does: under its app bar, with the ad row over the bottom.
  await tester.pumpWidget(ProviderScope(
    overrides: [
      planProvider.overrideWith(() => PlanNotifier(PlanState(isPremium: premium))),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(locale),
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          toolbarHeight: size.height * 0.07,
          backgroundColor: Colors.black,
        ),
        body: Stack(children: [
          const MenuPage(),
          if (!premium) Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height < 600 ? 50 : (size.height < 1000 ? size.height / 8 - 25 : 100),
            child: const ColoredBox(key: ValueKey('adRow'), color: Colors.black),
          ),
        ]),
      ),
    ),
  ));
  // The saved close count and date come from the in-memory store, so fake time is enough.
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(seconds: 5));
}

final _gridButtons = [
  find.image(const AssetImage(settingsButton)),
  find.image(const AssetImage(adRewardButton)),
  find.image(const AssetImage(rankingButton)),
  find.image(const AssetImage(purchaseButton)),
];

/// The menu opens with a real connectivity check, and its cover takes presses until that ends.
/// Fake time cannot end it, so wait in real time, bounded.
Future<void> _waitForCover(WidgetTester tester) async {
  for (var i = 0; i < 150 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(find.byType(CircularProgressIndicator), findsNothing);
}

/// The area the grid is centred in when there is no card.
Rect _strip(WidgetTester tester) => tester.getRect(
  find.ancestor(of: _settings, matching: find.byType(Center)).first,
);

PromoLayout _layout(double w, double h, {double top = 0}) => PromoLayout(
  screenWidth: w,
  screenHeight: h,
  topInset: top,
  bottomRowHeight: h < 600 ? 50 : (h < 1000 ? h / 8 - 25 : 100),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
  });

  testWidgets('room to spare: the notice card is shown with the size of PromoLayout', (tester) async {
    await _pump(tester, const Size(402, 874), installed: false);
    expect(_notice, findsOneWidget);
    // The bottom row is the unpurchased AdMob height: 874 / 8 - 25.
    final layout = PromoLayout(
      screenWidth: 402,
      screenHeight: 874,
      topInset: 0,
      bottomRowHeight: 874 / 8 - 25,
    );
    expect(tester.getSize(_card).width, closeTo(layout.cardWidth, 0.5));
    expect(tester.getSize(_card).height, closeTo(layout.videoHeight + 2 * layout.cardInset, 0.5));
  });

  testWidgets('the grid buttons are laid out with the grid gap of PromoLayout', (tester) async {
    await _pump(tester, const Size(402, 874), installed: false);
    final layout = PromoLayout(
      screenWidth: 402,
      screenHeight: 874,
      topInset: 0,
      bottomRowHeight: 874 / 8 - 25,
    );
    // Two rows of buttons: the second row's top sits one button and one gap below the first.
    final first = tester.getTopLeft(_settings).dy;
    final size = tester.getSize(_settings).height;
    expect(size, closeTo(layout.gridButtonSize, 0.5));
    expect(first, greaterThan(0));
  });

  testWidgets('installed: no notice card', (tester) async {
    await _pump(tester, const Size(402, 874), installed: true);
    expect(_notice, findsNothing);
  });

  testWidgets('too short for a card: no notice card', (tester) async {
    await _pump(tester, const Size(402, 874), installed: false, topInset: 300);
    expect(_notice, findsNothing);
  });

  testWidgets('the grid and the card sit at the rows of the spec', (tester) async {
    await _pump(tester, const Size(402, 874), installed: false);
    final layout = _layout(402, 874);
    final gridTop = tester.getTopLeft(_settings).dy;
    // The home app bar is the header band of 0.07 of the height, then one gap g.
    expect(gridTop, closeTo(0.07 * 874 + layout.gap, 1.0));
    final gridBottom = gridTop + 2 * layout.gridButtonSize + layout.gap;
    expect(tester.getTopLeft(_card).dy, closeTo(gridBottom + layout.gap + layout.remainder / 2, 1.0));
    // The card is centred on the screen.
    expect(tester.getCenter(_card).dx, closeTo(402 / 2, 0.5));
  });

  // Screens of the spec table (section 7): width, height, status band.
  for (final screen in [(320.0, 568.0, 20.0), (375.0, 667.0, 20.0), (375.0, 812.0, 50.0), (402.0, 874.0, 62.0), (768.0, 1024.0, 20.0), (360.0, 640.0, 24.0)]) {
    testWidgets('the close square is 0.155u and clear of the grid, card text and video at ${screen.$1.toInt()}x${screen.$2.toInt()}', (tester) async {
      await _pump(tester, Size(screen.$1, screen.$2), installed: false, topInset: screen.$3);
      final layout = _layout(screen.$1, screen.$2, top: screen.$3);
      final square = tester.getRect(_close);
      final card = tester.getRect(_card);
      expect(square.width, closeTo(0.155 * layout.u, 0.01));
      expect(square.height, closeTo(0.155 * layout.u, 0.01));
      final circleCenterX = card.right - layout.cardInset - 0.03 * layout.u;
      expect(square.right, closeTo(math.min(circleCenterX + 0.0775 * layout.u, screen.$1), 0.01));
      expect(square.bottom, closeTo(card.top + layout.cardInset + 0.08 * layout.u, 0.01));
      for (final button in _gridButtons) {
        if (button.evaluate().isEmpty) continue;
        expect(square.deflate(0.05).overlaps(tester.getRect(button)), isFalse, reason: 'grid button');
      }
      expect(square.deflate(0.05).overlaps(tester.getRect(find.byType(PromoVideo))), isFalse, reason: 'video');
      expect(square.deflate(0.05).overlaps(tester.getRect(find.text('Recommended'))), isFalse, reason: 'heading');
      // The card, the grid and the links band do not overlap.
      final lastButton = _gridButtons
          .where((f) => f.evaluate().isNotEmpty)
          .map((f) => tester.getRect(f).bottom)
          .reduce(math.max);
      expect(card.top, greaterThanOrEqualTo(lastButton - 0.5));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a press on the edge of the grid button beside the square goes to the button', (tester) async {
    await _pump(tester, const Size(375, 812), installed: false, topInset: 50);
    await _waitForCover(tester);
    final square = tester.getRect(_close);
    final buttons = _gridButtons.where((f) => f.evaluate().isNotEmpty).toList();
    // The button whose bottom edge is nearest to the square.
    buttons.sort((a, b) => (tester.getRect(a).bottom - square.top)
        .abs()
        .compareTo((tester.getRect(b).bottom - square.top).abs()));
    final target = buttons.first;
    final rect = tester.getRect(target);
    final hit = tester.hitTestOnBinding(Offset(rect.right - 1, rect.bottom - 1));
    final targets = hit.path.map((e) => e.target).toList();
    expect(targets.contains(tester.renderObject(_close)), isFalse, reason: 'the close square must not take it');
    final gesture = find.ancestor(of: target, matching: find.byType(GestureDetector)).first;
    expect(targets.contains(tester.renderObject(gesture)), isTrue, reason: 'the grid button takes it');
  });

  testWidgets('a press above the card closes it and the grid goes to the middle', (tester) async {
    await _pump(tester, const Size(402, 874), installed: false);
    await _waitForCover(tester);
    final layout = _layout(402, 874);
    final square = tester.getRect(_close);
    final card = tester.getRect(_card);
    expect(square.top, lessThan(card.top));
    await tester.tapAt(Offset(square.center.dx, (square.top + card.top) / 2));
    await tester.pump();
    await tester.pump();
    expect(_notice, findsNothing);
    final strip = _strip(tester);
    final rows = 2 * layout.gridButtonSize + 874 * 0.04;
    expect(tester.getTopLeft(_settings).dy - strip.top, closeTo((strip.height - rows) / 2, 1.0));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(PromoPrefs.adventureDismissCountKey), 1);
    expect(prefs.getString(PromoPrefs.adventureDismissedDateKey), PromoPrefs.dayText(DateTime.now()));
  });

  testWidgets('a close today hides the card; the next day shows it', (tester) async {
    final today = DateTime.now();
    SharedPreferences.setMockInitialValues({
      PromoPrefs.adventureDismissCountKey: 1,
      PromoPrefs.adventureDismissedDateKey: PromoPrefs.dayText(today),
    });
    await _pump(tester, const Size(402, 874), installed: false);
    expect(_notice, findsNothing);
    await tester.pumpWidget(const SizedBox());

    SharedPreferences.setMockInitialValues({
      PromoPrefs.adventureDismissCountKey: 2,
      PromoPrefs.adventureDismissedDateKey: PromoPrefs.dayText(today.subtract(const Duration(days: 1))),
    });
    await _pump(tester, const Size(402, 874), installed: false);
    expect(_notice, findsOneWidget);
  });

  testWidgets('after the third close the card never shows', (tester) async {
    SharedPreferences.setMockInitialValues({
      PromoPrefs.adventureDismissCountKey: 3,
      PromoPrefs.adventureDismissedDateKey: '2020-01-01',
    });
    await _pump(tester, const Size(402, 874), installed: false);
    expect(_notice, findsNothing);
  });

  for (final locale in ['ja', 'en', 'fr', 'ko', 'zh', 'es']) {
    testWidgets('the card shows without overflow in $locale', (tester) async {
      await _pump(tester, const Size(375, 667), installed: false, topInset: 20, locale: locale);
      expect(_notice, findsOneWidget);
      expect(tester.takeException(), isNull);
      final layout = _layout(375, 667, top: 20);
      expect(tester.getSize(_card).width, closeTo(layout.cardWidth, 0.5));
    });
  }

  group('the installed check ends after the menu opened', () {
    final shown = <String>[];

    setUp(() {
      shown.clear();
      AnalyticsManager.send = (name, parameters) async => shown.add(name);
    });

    testWidgets('an installed answer that arrives late never builds the card or sends cross_promo_shown', (tester) async {
      await _pump(tester, const Size(402, 874), installed: false, checked: false);
      // The check is still running: no card yet, and nothing was sent.
      expect(_notice, findsNothing);
      expect(shown, isEmpty);
      // The answer arrives: installed.
      PromoSession.adventureInstalled.value = true;
      PromoSession.installedChecked.value = true;
      await tester.pump();
      await tester.pump();
      expect(_notice, findsNothing);
      expect(shown, isEmpty, reason: 'no cross_promo_shown, no cross_promo_view_ended');
    });

    testWidgets('a not-installed answer that arrives late builds the card once', (tester) async {
      await _pump(tester, const Size(402, 874), installed: false, checked: false);
      expect(_notice, findsNothing);
      PromoSession.installedChecked.value = true;
      await tester.pump();
      await tester.pump();
      expect(_notice, findsOneWidget);
      await tester.pump();
      expect(shown.where((n) => n == 'cross_promo_shown'), hasLength(1));
    });
  });

  // Screens of the spec table (section 7): name, size, status band, bottom inset.
  final tableScreens = <(String, Size, double, double)>[
    ('iPhone SE 1st 320x568', const Size(320, 568), 20, 0),
    ('iPhone SE 2nd/3rd 375x667', const Size(375, 667), 20, 0),
    ('iPhone 13 mini 375x812', const Size(375, 812), 50, 34),
    ('iPhone 16e 390x844', const Size(390, 844), 47, 34),
    ('iPhone 17 Pro 402x874', const Size(402, 874), 62, 34),
    ('iPhone 11 414x896', const Size(414, 896), 48, 34),
    ('iPhone 17 Pro Max 440x956', const Size(440, 956), 62, 34),
    ('iPad 768x1024', const Size(768, 1024), 24, 20),
    ('iPad A16 820x1180', const Size(820, 1180), 24, 20),
    ('iPad Pro 12.9 1024x1366', const Size(1024, 1366), 24, 20),
    ('Android 360x640', const Size(360, 640), 24, 48),
    ('Android 360x800', const Size(360, 800), 24, 48),
    ('Android 412x915', const Size(412, 915), 24, 48),
  ];
  for (final screen in tableScreens) {
    for (final premium in [false, true]) {
      testWidgets('stacked as the home screen: ${screen.$1}, ${premium ? 'purchased' : 'unpaid'}', (tester) async {
        final size = screen.$2;
        await _pump(tester, size, installed: false, topInset: screen.$3, bottomInset: screen.$4, premium: premium);
        expect(tester.takeException(), isNull, reason: 'nothing overflows');
        final bottomRow = premium
            ? 0.075 * math.min(size.height, 1000) + screen.$4
            : (size.height < 600 ? 50.0 : (size.height < 1000 ? size.height / 8 - 25 : 100.0));
        final layout = PromoLayout(
          screenWidth: size.width,
          screenHeight: size.height,
          topInset: screen.$3,
          bottomRowHeight: bottomRow,
        );
        // The top of the grid: status band, header band (the app bar), then g.
        expect(
          tester.getTopLeft(_settings).dy,
          closeTo(screen.$3 + 0.07 * size.height + layout.gap, 1.0),
          reason: 'grid top',
        );
        expect(tester.getSize(_settings).height, closeTo(0.255 * layout.u, 0.5));
        // The card: the size and the width of the table.
        final card = tester.getRect(_card);
        expect(card.width, closeTo(layout.cardWidth, 1.0));
        expect(card.height, closeTo(layout.cardHeight, 1.0));
        // The card sits g + remainder / 2 under the grid.
        final gridBottom = screen.$3 + 0.07 * size.height + layout.gap + layout.gridHeight;
        expect(card.top, closeTo(gridBottom + layout.gap + layout.remainder / 2, 1.0), reason: 'card top');
        // The links band, found by its logo, is clear of the card and of the ad row.
        final BuildContext context = tester.element(find.byType(MenuPage));
        final band = tester.getRect(find.ancestor(
          of: find.image(AssetImage(context.linkLogos()[0])),
          matching: find.byType(Container),
        ).first);
        expect(card.bottom, lessThanOrEqualTo(band.top + 0.5), reason: 'card meets the links band');
        expect(card.overlaps(band.deflate(0.01)), isFalse);
        if (!premium) {
          final ad = tester.getRect(find.byKey(const ValueKey('adRow')));
          expect(band.bottom, lessThanOrEqualTo(ad.top + 0.5), reason: 'band meets the ad row');
          expect(card.overlaps(ad.deflate(0.01)), isFalse);
        }
        // The band is the height of the spec: 0.2055u (premium adds the bottom inset).
        expect(band.height, closeTo(0.17 * layout.u + 1.42 * 0.025 * layout.u + (premium ? screen.$4 : 0), 1.0), reason: 'band height');
      });
    }
  }
}

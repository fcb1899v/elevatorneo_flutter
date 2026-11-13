// Checks the menu notice: its layout in six languages, its events, its taps and its reading for screen readers.
// The video comes from the test fixtures, the store and the analytics are replaced by fakes.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/analytics_manager.dart';
import 'package:letselevatorneo/l10n/app_localizations.dart';
import 'package:letselevatorneo/promo/promo_banner.dart';
import 'package:letselevatorneo/promo/promo_card_text.dart';
import 'package:letselevatorneo/promo/promo_layout.dart';
import 'package:letselevatorneo/promo/promo_store.dart';
import 'package:letselevatorneo/promo/promo_video.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Map<String, Uint8List> _assets = {};
final List<Map<String, Object?>> _events = [];
final List<String> _nativeCalls = [];
final List<Uri> _launched = [];
bool _nativeOk = true;
bool _urlOk = true;

/// The heading and the store button of each language, from the arb files.
const Map<String, List<String>> _texts = {
  'ja': ['おすすめ', '詳しく見る'],
  'en': ['Recommended', 'Learn more'],
  'fr': ['Recommandé', 'Découvrir'],
  'ko': ['추천 앱', '더 알아보기'],
  'zh': ['你可能还喜欢', '了解更多'],
  'es': ['Recomendado', 'Ver más'],
};

/// The full body and the short body of each language, from the arb files.
const Map<String, List<String>> _bodies = {
  'ja': [
    '好きなだけ、呼んで、乗って、ボタンを押して、高層ビルを冒険できる超リアルな3Dエレベーターシミュレーター',
    '超リアルな3Dエレベーターシミュレーター',
  ],
  'en': [
    'Call it, ride it and press the buttons as much as you like on a skyscraper adventure. A realistic 3D elevator simulator.',
    'A realistic 3D elevator simulator',
  ],
  'fr': [
    "Appelez l'ascenseur, montez, appuyez sur les boutons à volonté et partez à l'aventure dans un gratte-ciel. Simulateur 3D ultra-réaliste.",
    "Simulateur d'ascenseur 3D ultra-réaliste",
  ],
  'ko': [
    '마음껏 호출하고, 타고, 버튼을 눌러 고층 빌딩에서 모험하는 정말 리얼한 3D 엘리베이터 시뮬레이터',
    '정말 리얼한 3D 엘리베이터 시뮬레이터',
  ],
  'zh': [
    '尽情呼叫、乘坐、按下按钮，在摩天大楼里冒险的超逼真3D电梯模拟器',
    '超逼真3D电梯模拟器',
  ],
  'es': [
    'Llama al ascensor, súbete y toca los botones cuanto quieras en una aventura por un rascacielos. Simulador 3D ultrarrealista.',
    'Simulador de ascensor 3D ultrarrealista',
  ],
};

/// The separator between the read parts for each language.
const Map<String, String> _separators = {'ja': '、', 'zh': '，', 'en': ', '};

/// The names read aloud for each language.
const Map<String, String> _names = {
  'ja': 'レッツ・エレベーター・アドベンチャー',
  'en': 'LETS ELEVATOR ADVENTURE',
  'zh': '操作乐趣电梯冒险',
};

Future<Uint8List> _load(String name) async => _assets[name]!;

/// The font family the app picks for a language.
String _font(String locale) => switch (locale) {
  'ja' => 'notoJP',
  'zh' => 'notoSC',
  'ko' => 'bmDohyeon',
  _ => 'roboto',
};

/// The unpurchased bottom row: the ad height of the screen.
double _adHeight(double height) =>
    height < 600 ? 50 : (height < 1000 ? height / 8 - 25 : 100);

Widget _app(Widget child, {String locale = 'ja'}) {
  return MaterialApp(
    locale: Locale(locale),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

/// The card for a screen of [width] x [height], with the text planned like the menu does.
PromoMenuBanner _banner({
  double width = 402,
  double height = 874,
  String locale = 'ja',
  bool isPremium = false,
  bool stillOnly = false,
  String firstPattern = 'p1',
  double? topInset,
  VoidCallback? onDismiss,
}) {
  final layout = PromoLayout(
    screenWidth: width,
    screenHeight: height,
    topInset: topInset ?? (height > 800 ? 62 : 20),
    bottomRowHeight: isPremium ? 0.075 * height + (height > 800 ? 34 : 0) : _adHeight(height),
  );
  final plan = planPromoCard(
    layout: layout,
    lang: locale,
    fontFamily: _font(locale),
    heading: _texts[locale]![0],
    body: _bodies[locale]![0],
    bodyShort: _bodies[locale]![1],
  );
  return PromoMenuBanner(
    layout: layout,
    plan: plan,
    onDismiss: onDismiss ?? () {},
    isPremium: isPremium,
    patterns: const ['p1', 'p2', 'p3'],
    firstPattern: firstPattern,
    stillOnly: stillOnly,
  );
}

/// The number of lines a paragraph is laid out in, from its height and its line height of 1.2.
int _lines(RenderParagraph paragraph, double fontSize) =>
    (paragraph.size.height / (fontSize * 1.2)).round();

/// Lets the preferences and the image decoding finish, which need real time.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

void _useSize(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

List<Map<String, Object?>> _named(String name) =>
    _events.where((event) => event['name'] == name).toList();

void main() {
  setUpAll(() async {
    for (final name in ['p1', 'p1_still', 'p2', 'p2_still']) {
      _assets[name] = await File('test/fixtures/$name.webp').readAsBytes();
    }
    // The fixtures have two patterns; the third one reuses the first.
    _assets['p3'] = _assets['p1']!;
    _assets['p3_still'] = _assets['p1_still']!;
    for (final entry in {
      'roboto': 'assets/fonts/Roboto-Bold.ttf',
      'notoJP': 'assets/fonts/NotoSansJP-Bold.ttf',
      'notoSC': 'assets/fonts/NotoSansSC-Bold.ttf',
      'bmDohyeon': 'assets/fonts/bm-dohyeon.regular.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _events.clear();
    _nativeCalls.clear();
    _launched.clear();
    _nativeOk = true;
    _urlOk = true;
    AnalyticsManager.send = (name, parameters) async =>
        _events.add({'name': name, 'params': parameters});
    PromoStore.invokeNative = (method, args) async {
      _nativeCalls.add(method);
      return _nativeOk;
    };
    PromoStore.urlLauncher = (uri) async {
      _launched.add(uri);
      return _urlOk;
    };
    PromoStore.platformSource = () => 'android';
    PromoStore.storeClosedListener = null;
    PromoMenuBanner.loadAsset = _load;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('vibration'),
          (_) async => null,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('vibration'), null);
  });

  group('layout', () {
    // Screens of the spec table (section 7): width, height, status band, lines of the Japanese body.
    final sizes = <(double, double, double, int)>[
      (320, 568, 20, 5),
      (375, 667, 20, 5),
      (375, 812, 50, 8),
      (402, 874, 62, 8),
      (768, 1024, 20, 5),
      (360, 640, 24, 5),
    ];
    for (final size in sizes) {
      for (final locale in _texts.keys) {
        testWidgets(
          '${locale.toUpperCase()} fits at ${size.$1.toInt()}x${size.$2.toInt()}',
          (tester) async {
            _useSize(tester, size.$1, size.$2);
            final banner = _banner(
              width: size.$1,
              height: size.$2,
              locale: locale,
              topInset: size.$3,
            );
            final plan = banner.plan;
            final u = banner.layout.u;
            // The card is drawn in every language of the table, with the full body.
            expect(plan.showCard, isTrue, reason: 'card must be shown');
            expect(plan.bodyForm, 'full', reason: 'the full body fits');
            expect(plan.gap, greaterThanOrEqualTo(0.04 * u), reason: 'G >= 0.04u');
            expect(plan.headingLines, 1, reason: 'one heading line');
            if (locale == 'ja') {
              expect(plan.bodyLines, closeTo(size.$4, 1), reason: 'Japanese body lines');
            }
            await tester.pumpWidget(_app(banner, locale: locale));
            await tester.pump();
            // No yellow and black stripes: nothing overflows.
            expect(tester.takeException(), isNull);

            final texts = _texts[locale]!;
            final heading = tester.renderObject<RenderParagraph>(
              find.text(texts[0]),
            );
            expect(
              heading.didExceedMaxLines,
              isFalse,
              reason: 'heading must fit its lines',
            );
            expect(_lines(heading, 0.032 * u), 1, reason: 'heading is one line');

            final button = tester.renderObject<RenderParagraph>(
              find.text(texts[1]),
            );
            expect(
              button.didExceedMaxLines,
              isFalse,
              reason: 'button text must stay on one line',
            );
            expect(_lines(button, 0.032 * u), 1, reason: 'button text is one line');

            // The body is drawn whole, with the lines the plan counted.
            final bodyFinder = find.text(plan.body!);
            expect(bodyFinder, findsOneWidget, reason: 'the whole body is drawn');
            final body = tester.renderObject<RenderParagraph>(bodyFinder);
            expect(body.didExceedMaxLines, isFalse);
            expect(_lines(body, 0.033 * u), plan.bodyLines);

            // The video is 3:4 and has the size of the layout.
            final video = tester.getSize(find.byType(PromoVideo));
            expect(video.width / video.height, closeTo(0.75, 0.005));
            expect(video.height, closeTo(banner.layout.videoHeight, 0.5));
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  });

  group('close square', () {
    // Screens of the spec table (section 7): width, height, status band.
    final sizes = <(double, double, double)>[
      (320, 568, 20),
      (375, 667, 20),
      (375, 812, 50),
      (402, 874, 62),
      (768, 1024, 20),
      (360, 640, 24),
    ];
    for (final size in sizes) {
      for (final locale in ['ja', 'en']) {
        testWidgets(
          'is a 0.155u square at the right edge and heading top, clear of the heading and video at ${size.$1.toInt()}x${size.$2.toInt()} in $locale',
          (tester) async {
            _useSize(tester, size.$1, size.$2);
            final banner = _banner(width: size.$1, height: size.$2, topInset: size.$3, locale: locale);
            final l = banner.layout;
            final u = l.u;
            await tester.pumpWidget(_app(banner, locale: locale));
            await tester.pump();
            final square = tester.getRect(find.byKey(const ValueKey('promoClose')));
            final card = tester.getRect(find.byKey(const ValueKey('promoCard')));
            expect(square.width, closeTo(0.155 * u, 0.01));
            expect(square.height, closeTo(0.155 * u, 0.01));
            // The right edge: the circle's centre plus 0.0775u, but never past the screen.
            final circleCenterX = card.right - l.cardInset - 0.03 * u;
            expect(square.right, closeTo(math.min(circleCenterX + 0.0775 * u, size.$1), 0.01));
            // The bottom edge is the heading's top edge: the card's top plus the inset plus 0.08u.
            expect(square.bottom, closeTo(card.top + l.cardInset + 0.08 * u, 0.01));
            final heading = tester.getRect(find.text(_texts[locale]![0]));
            final video = tester.getRect(find.byType(PromoVideo));
            expect(square.deflate(0.05).overlaps(heading), isFalse, reason: 'heading');
            expect(square.deflate(0.05).overlaps(video), isFalse, reason: 'video');
            expect(square.bottom, lessThanOrEqualTo(heading.top + 0.5));
            // The whole square lies inside the screen.
            expect(square.right, lessThanOrEqualTo(size.$1 + 0.01));
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }

    testWidgets('a press on the round mark closes the card once', (tester) async {
      _useSize(tester, 375, 667);
      var dismissed = 0;
      final banner = _banner(width: 375, height: 667, onDismiss: () => dismissed++);
      final l = banner.layout;
      await tester.pumpWidget(_app(banner));
      await tester.pump();
      final card = tester.getRect(find.byKey(const ValueKey('promoCard')));
      await tester.tapAt(Offset(
        card.left + l.cardWidth - l.cardInset - 0.03 * l.u,
        card.top + l.cardInset + 0.03 * l.u,
      ));
      await tester.pump();
      expect(dismissed, 1);
    });

    testWidgets('a press above the card, inside the square, closes the card', (tester) async {
      _useSize(tester, 375, 667);
      var dismissed = 0;
      await tester.pumpWidget(_app(_banner(width: 375, height: 667, onDismiss: () => dismissed++)));
      await tester.pump();
      final card = tester.getRect(find.byKey(const ValueKey('promoCard')));
      final close = tester.getRect(find.byKey(const ValueKey('promoClose')));
      expect(close.top, lessThan(card.top - 1), reason: 'the square must reach above the card');
      await tester.tapAt(Offset(close.center.dx, (close.top + card.top) / 2));
      await tester.pump();
      expect(dismissed, 1);
    });

    testWidgets('a press beside the card, inside the square, closes the card', (tester) async {
      _useSize(tester, 375, 667);
      var dismissed = 0;
      final banner = _banner(width: 375, height: 667, onDismiss: () => dismissed++);
      await tester.pumpWidget(_app(banner));
      await tester.pump();
      final card = tester.getRect(find.byKey(const ValueKey('promoCard')));
      final close = tester.getRect(find.byKey(const ValueKey('promoClose')));
      expect(close.right, greaterThan(card.right + 1), reason: 'the square must reach past the card edge');
      await tester.tapAt(Offset(close.right - 1, card.top + banner.layout.cardInset + 0.03 * banner.layout.u));
      await tester.pump();
      expect(dismissed, 1);
    });

    testWidgets('a press on the card just under the square opens the store', (tester) async {
      _useSize(tester, 375, 667);
      var dismissed = 0;
      await tester.pumpWidget(_app(_banner(width: 375, height: 667, onDismiss: () => dismissed++)));
      await _settle(tester);
      final close = tester.getRect(find.byKey(const ValueKey('promoClose')));
      await tester.tapAt(Offset(close.center.dx, close.bottom + 2));
      await _settle(tester);
      expect(dismissed, 0);
      expect(_named('cross_promo_tapped'), hasLength(1));
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('shows once per opening and counts the opening', (tester) async {
    _useSize(tester, 402, 874);
    await tester.pumpWidget(_app(_banner()));
    await _settle(tester);

    final shown = _named('cross_promo_shown');
    expect(shown, hasLength(1));
    final shownParams = Map<String, Object?>.of(shown.single['params'] as Map<String, Object?>);
    expect(shownParams.remove('body_form'), isIn(['full', 'short', 'none']));
    expect(shownParams, {
      'target': 'adventure',
      'placement': 'menu',
      'is_premium': 0,
      'lang': 'ja',
      'launch_count': '1',
      'ride_count': '0',
      'days_since_first_launch': '0',
      'shown_count': '1',
      'first_pattern': 'p1',
      'video_mode': 'video',
    });
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('still only is reported as video_mode still', (tester) async {
    _useSize(tester, 402, 874);
    await tester.pumpWidget(_app(_banner(stillOnly: true)));
    await _settle(tester);

    expect(
      _named('cross_promo_shown').single['params'] as Map,
      containsPair('video_mode', 'still'),
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a tap opens the store once and reports the tap', (tester) async {
    _useSize(tester, 402, 874);
    await tester.pumpWidget(_app(_banner()));
    await _settle(tester);

    await tester.tap(find.text(_texts['ja']![1]));
    await _settle(tester);

    expect(_nativeCalls, ['openPlay']);
    expect(_launched, isEmpty);
    final tapped = _named('cross_promo_tapped');
    expect(tapped, hasLength(1));
    final params = tapped.single['params'] as Map;
    expect(params['opened'], 1);
    expect(params['open_method'], 'market');
    expect(params['target_area'], 'button');
    expect(params['video_pattern'], 'p1');
    expect(params['patterns_seen'], '1');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a second tap while the store is opening does nothing', (
    tester,
  ) async {
    _useSize(tester, 402, 874);
    final release = Completer<bool>();
    PromoStore.invokeNative = (method, args) {
      _nativeCalls.add(method);
      return release.future;
    };
    await tester.pumpWidget(_app(_banner()));
    await _settle(tester);

    await tester.tap(find.text(_texts['ja']![1]));
    await tester.tap(find.text(_texts['ja']![1]));
    release.complete(true);
    await _settle(tester);

    expect(_nativeCalls, hasLength(1));
    expect(_named('cross_promo_tapped'), hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a tap after the store was opened opens it again', (
    tester,
  ) async {
    _useSize(tester, 402, 874);
    await tester.pumpWidget(_app(_banner()));
    await _settle(tester);

    await tester.tap(find.text(_texts['ja']![1]));
    await _settle(tester);
    await tester.tap(find.text(_texts['ja']![1]));
    await _settle(tester);

    expect(_nativeCalls, ['openPlay', 'openPlay']);
    expect(_named('cross_promo_tapped'), hasLength(2));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('when both ways fail, nothing opens and a message shows', (
    tester,
  ) async {
    _useSize(tester, 402, 874);
    _nativeOk = false;
    _urlOk = false;
    await tester.pumpWidget(_app(_banner()));
    await _settle(tester);

    await tester.tap(find.text(_texts['ja']![1]));
    await _settle(tester);
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    final params = _named('cross_promo_tapped').single['params'] as Map;
    expect(params['opened'], 0);
    expect(params['open_method'], 'none');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('leaving the menu reports the view with the tap state', (
    tester,
  ) async {
    _useSize(tester, 402, 874);
    await tester.pumpWidget(_app(_banner()));
    await _settle(tester);
    await tester.pumpWidget(const SizedBox());
    await _settle(tester);

    final ended = _named('cross_promo_view_ended');
    expect(ended, hasLength(1));
    expect(ended.single['params'] as Map, containsPair('tapped', 0));
  });

  testWidgets('leaving the menu after a tap reports tapped 1', (tester) async {
    _useSize(tester, 402, 874);
    await tester.pumpWidget(_app(_banner()));
    await _settle(tester);
    await tester.tap(find.text(_texts['ja']![1]));
    await _settle(tester);
    await tester.pumpWidget(const SizedBox());
    await _settle(tester);

    final ended = _named('cross_promo_view_ended');
    expect(ended, hasLength(1));
    expect(ended.single['params'] as Map, containsPair('tapped', 1));
  });

  for (final tap in [
    ('the video', (WidgetTester t) => find.byType(PromoVideo), 'video'),
    ('the heading', (WidgetTester t) => find.text(_texts['ja']![0]), 'text'),
    ('the logo', (WidgetTester t) => find.byType(Image), 'text'),
  ]) {
    testWidgets('a tap on ${tap.$1} reports target_area ${tap.$3}', (
      tester,
    ) async {
      _useSize(tester, 402, 874);
      await tester.pumpWidget(_app(_banner()));
      await _settle(tester);

      await tester.tap(tap.$2(tester));
      await _settle(tester);

      final params = _named('cross_promo_tapped').single['params'] as Map;
      expect(params['target_area'], tap.$3);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final locale in ['ja', 'en', 'zh']) {
    testWidgets('screen readers read one button in $locale', (tester) async {
      _useSize(tester, 402, 874);
      final handle = tester.ensureSemantics();
      final banner = _banner(locale: locale);
      await tester.pumpWidget(_app(banner, locale: locale));
      await _settle(tester);

      // The card reads heading, name, whole body and button; the close mark is another button.
      final sep = _separators[locale]!;
      final texts = _texts[locale]!;
      final body = banner.plan.body!.replaceAll('\n', '');
      final label = [texts[0], _names[locale]!, body, texts[1]].join(sep);
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.label, label);
      const closeLabels = {'ja': '閉じる', 'en': 'Close', 'zh': '关闭'};
      final close = tester.getSemantics(find.bySemanticsLabel(closeLabels[locale]!));
      expect(close.flagsCollection.isButton, isTrue);
      expect(close.id, isNot(node.id));
      handle.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  }
}

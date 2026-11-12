// Checks the menu notice: its layout in six languages, its events, its taps and its reading for screen readers.
// The video comes from the test fixtures, the store and the analytics are replaced by fakes.

import 'dart:async';
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/analytics_manager.dart';
import 'package:letselevatorneo/l10n/app_localizations.dart';
import 'package:letselevatorneo/promo/promo_banner.dart';
import 'package:letselevatorneo/promo/promo_store.dart';
import 'package:letselevatorneo/promo/promo_video.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Map<String, Uint8List> _assets = {};
final List<Map<String, Object?>> _events = [];
final List<String> _nativeCalls = [];
final List<Uri> _launched = [];
bool _nativeOk = true;
bool _urlOk = true;

/// The title, the store name and the button text of each language, from the arb files.
const Map<String, List<String>> _texts = {
  'ja': ['新作アプリのお知らせ', 'レッツ・エレベーター・アドベンチャー', 'ストアで見る'],
  'en': ['Our New App', 'LETS ELEVATOR ADVENTURE', 'View in Store'],
  'fr': ['Notre nouvelle app', 'LETS ELEVATOR ADVENTURE', 'Voir sur le Store'],
  'ko': ['신작 앱 출시', '렛츠 엘리베이터 어드벤처', '스토어에서 보기'],
  'zh': ['新应用上线', '操作乐趣电梯冒险', '在应用商店中查看'],
  'es': ['Nuestra nueva app', 'LETS ELEVATOR ADVENTURE', 'Ver en la tienda'],
};

/// The text read aloud for each language.
const Map<String, String> _labels = {
  'ja': '新作アプリのお知らせ、レッツ・エレベーター・アドベンチャー、ストアで見る',
  'en': 'Our New App, LETS ELEVATOR ADVENTURE, View in Store',
  'zh': '新应用上线，操作乐趣电梯冒险，在应用商店中查看',
};

Future<Uint8List> _load(String name) async => _assets[name]!;

Widget _app(Widget child, {String locale = 'ja'}) {
  return MaterialApp(
    locale: Locale(locale),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

PromoMenuBanner _banner({
  required double height,
  bool isPremium = false,
  bool stillOnly = false,
  String firstPattern = 'p1',
}) {
  return PromoMenuBanner(
    height: height,
    isPremium: isPremium,
    patterns: const ['p1', 'p2', 'p3'],
    firstPattern: firstPattern,
    stillOnly: stillOnly,
  );
}

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
    // The heights are the minimum and maximum of the spec for an iPhone 17 Pro (402) and an iPhone SE (375).
    final sizes = <(double, double, double)>[
      (402, 874, 0.3059 * 402),
      (375, 667, 0.2732 * 375),
    ];
    for (final size in sizes) {
      for (final locale in _texts.keys) {
        testWidgets(
          '${locale.toUpperCase()} fits at ${size.$1.toInt()}x${size.$2.toInt()}',
          (tester) async {
            _useSize(tester, size.$1, size.$2);
            await tester.pumpWidget(
              _app(_banner(height: size.$3), locale: locale),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);

            final texts = _texts[locale]!;
            final heading = tester.renderObject<RenderParagraph>(
              find.text(texts[0]),
            );
            expect(
              heading.didExceedMaxLines,
              isFalse,
              reason: 'heading must stay on one line',
            );

            final button = tester.renderObject<RenderParagraph>(
              find.text(texts[2]),
            );
            expect(
              button.didExceedMaxLines,
              isFalse,
              reason: 'button text must stay on one line',
            );

            final name = tester.renderObject<RenderParagraph>(
              find.text(texts[1]),
            );
            expect(
              name.didExceedMaxLines,
              isFalse,
              reason: 'name must fit in two lines',
            );
            if (locale == 'ja') {
              // The first line ends with the dot at index 10, and index 11 starts the second line.
              double topOf(int index) => name
                  .getBoxesForSelection(
                    TextSelection(baseOffset: index, extentOffset: index + 1),
                  )
                  .first
                  .top;
              expect(topOf(10), topOf(0));
              expect(topOf(11), greaterThan(topOf(0)));
            }
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  });

  testWidgets('shows once per opening and counts the opening', (tester) async {
    _useSize(tester, 402, 874);
    await tester.pumpWidget(_app(_banner(height: 122.9)));
    await _settle(tester);

    final shown = _named('cross_promo_shown');
    expect(shown, hasLength(1));
    expect(shown.single['params'], {
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
    await tester.pumpWidget(_app(_banner(height: 122.9, stillOnly: true)));
    await _settle(tester);

    expect(
      _named('cross_promo_shown').single['params'] as Map,
      containsPair('video_mode', 'still'),
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a tap opens the store once and reports the tap', (tester) async {
    _useSize(tester, 402, 874);
    await tester.pumpWidget(_app(_banner(height: 122.9)));
    await _settle(tester);

    await tester.tap(find.text(_texts['ja']![2]));
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
    await tester.pumpWidget(_app(_banner(height: 122.9)));
    await _settle(tester);

    await tester.tap(find.text(_texts['ja']![2]));
    await tester.tap(find.text(_texts['ja']![2]));
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
    await tester.pumpWidget(_app(_banner(height: 122.9)));
    await _settle(tester);

    await tester.tap(find.text(_texts['ja']![2]));
    await _settle(tester);
    await tester.tap(find.text(_texts['ja']![2]));
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
    await tester.pumpWidget(_app(_banner(height: 122.9)));
    await _settle(tester);

    await tester.tap(find.text(_texts['ja']![2]));
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
    await tester.pumpWidget(_app(_banner(height: 122.9)));
    await _settle(tester);
    await tester.pumpWidget(const SizedBox());
    await _settle(tester);

    final ended = _named('cross_promo_view_ended');
    expect(ended, hasLength(1));
    expect(ended.single['params'] as Map, containsPair('tapped', 0));
  });

  testWidgets('leaving the menu after a tap reports tapped 1', (tester) async {
    _useSize(tester, 402, 874);
    await tester.pumpWidget(_app(_banner(height: 122.9)));
    await _settle(tester);
    await tester.tap(find.text(_texts['ja']![2]));
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
    ('the name', (WidgetTester t) => find.text(_texts['ja']![1]), 'text'),
  ]) {
    testWidgets('a tap on ${tap.$1} reports target_area ${tap.$3}', (
      tester,
    ) async {
      _useSize(tester, 402, 874);
      await tester.pumpWidget(_app(_banner(height: 122.9)));
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
      await tester.pumpWidget(_app(_banner(height: 122.9), locale: locale));
      await _settle(tester);

      final node = tester.getSemantics(find.bySemanticsLabel(_labels[locale]!));
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.label, _labels[locale]);
      handle.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  }
}

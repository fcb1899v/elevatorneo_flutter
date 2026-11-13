// Checks that the notice's text is drawn in as many lines as planPromoCard measured, in all six languages.
// The banner is built from the real strings and the app's own fonts, on the screens of the design.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/analytics_manager.dart';
import 'package:letselevatorneo/l10n/app_localizations.dart';
import 'package:letselevatorneo/extension.dart';
import 'package:letselevatorneo/promo/promo_banner.dart';
import 'package:letselevatorneo/promo/promo_card_text.dart';
import 'package:letselevatorneo/promo/promo_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The screens of the design with their top and bottom padding: SE, mini, Pro, Max, iPad and Android.
final _screens = <({String name, Size size, double top, double bottom})>[
  (name: 'iPhone SE 1st 320x568', size: const Size(320, 568), top: 20, bottom: 0),
  (name: 'iPhone SE 2nd/3rd 375x667', size: const Size(375, 667), top: 20, bottom: 0),
  (name: 'iPhone 13 mini 375x812', size: const Size(375, 812), top: 50, bottom: 34),
  (name: 'iPhone 16e 390x844', size: const Size(390, 844), top: 47, bottom: 34),
  (name: 'iPhone 17 Pro 402x874', size: const Size(402, 874), top: 62, bottom: 34),
  (name: 'iPhone 11 414x896', size: const Size(414, 896), top: 48, bottom: 34),
  (name: 'iPhone 17 Pro Max 440x956', size: const Size(440, 956), top: 62, bottom: 34),
  (name: 'iPad 768x1024', size: const Size(768, 1024), top: 24, bottom: 20),
  (name: 'iPad A16 820x1180', size: const Size(820, 1180), top: 24, bottom: 20),
  (name: 'iPad Pro 12.9 1024x1366', size: const Size(1024, 1366), top: 24, bottom: 20),
  (name: 'Android 360x640', size: const Size(360, 640), top: 24, bottom: 48),
  (name: 'Android 360x800', size: const Size(360, 800), top: 24, bottom: 48),
  (name: 'Android 412x915', size: const Size(412, 915), top: 24, bottom: 48),
];

const _languages = ['ja', 'en', 'fr', 'ko', 'zh', 'es'];

/// Ad height as in `admobHeight()`.
double _admob(double h) => h < 600 ? 50 : (h < 1000 ? h / 8 - 25 : 100);

Future<void> _loadFonts() async {
  const files = {
    'roboto': 'assets/fonts/Roboto-Bold.ttf',
    'notoJP': 'assets/fonts/NotoSansJP-Bold.ttf',
    'notoSC': 'assets/fonts/NotoSansSC-Bold.ttf',
    'bmDohyeon': 'assets/fonts/bm-dohyeon.regular.ttf',
  };
  for (final entry in files.entries) {
    await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value))).load();
  }
}

/// The width of the first line of [text] as `planPromoCard` measures it: the style with no theme behind it.
double _measuredWidth(String text, TextStyle style) => (TextPainter(
  text: TextSpan(text: text, style: style),
  textDirection: TextDirection.ltr,
  textScaler: TextScaler.noScaling,
  maxLines: 1,
)..layout()).width;

/// The width of the first drawn line: the text boxes of the paragraph that share the first top.
double _drawnWidth(WidgetTester tester, Finder finder) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final length = tester.widget<Text>(finder).data!.length;
  final boxes = paragraph.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: length));
  final top = boxes.first.top;
  return boxes.where((b) => (b.top - top).abs() < 0.5).fold<double>(0, (sum, b) => sum + (b.right - b.left));
}

/// The number of lines a paragraph is drawn in: its height over the line height of its style.
int _linesOf(WidgetTester tester, Finder finder) {
  final style = tester.widget<Text>(finder).style!;
  final lineHeight = style.fontSize! * style.height!;
  return (tester.renderObject<RenderParagraph>(finder).size.height / lineHeight).round();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AnalyticsManager.send = (name, parameters) async {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('vibration'), (_) async => null);
  });

  for (final c in _screens) {
    for (final premium in [false, true]) {
      final state = premium ? 'purchased' : 'unpaid';
      testWidgets('drawn lines equal the measured lines in six languages at ${c.name}, $state', (tester) async {
        tester.view.physicalSize = c.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final layout = PromoLayout(
          screenWidth: c.size.width,
          screenHeight: c.size.height,
          topInset: c.top,
          bottomRowHeight: premium ? 0.075 * (c.size.height < 1000 ? c.size.height : 1000) + c.bottom : _admob(c.size.height),
        );

        for (final lang in _languages) {
          late PromoCardPlan plan;
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(MaterialApp(
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Center(
                child: Builder(builder: (context) {
                  plan = planPromoCard(
                    layout: layout,
                    lang: context.lang(),
                    fontFamily: context.font(),
                    heading: context.promoHeading(),
                    body: context.promoBody(),
                    bodyShort: context.promoBodyShort(),
                  );
                  return PromoMenuBanner(
                    layout: layout,
                    plan: plan,
                    isPremium: premium,
                    patterns: const ['p1'],
                    firstPattern: 'p1',
                    stillOnly: true,
                    onDismiss: () {},
                  );
                }),
              ),
            ),
          ));
          await tester.pump();
          final where = '$lang at ${c.name}, $state';
          expect(plan.showCard, isTrue, reason: 'the card is not shown for $where');
          expect(tester.takeException(), isNull, reason: 'the card overflows for $where');

          // The heading: one line in a FittedBox for ja and zh, up to two lines in a plain Text otherwise
          final heading = find.text(plan.heading);
          expect(heading, findsOneWidget);
          final shrinks = find.ancestor(of: heading, matching: find.byType(FittedBox)).evaluate().isNotEmpty;
          expect(shrinks, lang == 'ja' || lang == 'zh', reason: 'the heading wrapper is wrong for $where');
          if (!shrinks) {
            expect(tester.widget<Text>(heading).maxLines, 2, reason: 'the heading is not maxLines 2 for $where');
          }
          expect(_linesOf(tester, heading), plan.headingLines, reason: 'heading lines for $where');
          expect(tester.widget<Text>(heading).style!.inherit, isFalse, reason: 'the heading inherits the theme for $where');
          if (plan.headingLines == 1) {
            expect(_drawnWidth(tester, heading), closeTo(_measuredWidth(plan.heading, tester.widget<Text>(heading).style!), 0.1),
                reason: 'the heading is drawn wider than measured for $where');
          }

          // The body, when the plan keeps one
          final body = plan.body;
          if (body != null) {
            final bodyFinder = find.text(body);
            expect(bodyFinder, findsOneWidget);
            expect(_linesOf(tester, bodyFinder), plan.bodyLines, reason: 'body lines for $where');
            expect(tester.widget<Text>(bodyFinder).style!.inherit, isFalse, reason: 'the body inherits the theme for $where');
          }

          // The button: one line, unscaled
          final button = find.text(tester.element(find.byType(PromoMenuBanner)).promoButton());
          expect(_linesOf(tester, button), 1, reason: 'button lines for $where');
          expect(tester.renderObject<RenderParagraph>(button).didExceedMaxLines, isFalse, reason: 'button exceeds for $where');
          expect(tester.widget<Text>(button).style!.inherit, isFalse, reason: 'the button inherits the theme for $where');
          expect(_drawnWidth(tester, button), closeTo(_measuredWidth(tester.widget<Text>(button).data!, tester.widget<Text>(button).style!), 0.1),
              reason: 'the button text is drawn wider than measured for $where');
        }
      });
    }
  }
}

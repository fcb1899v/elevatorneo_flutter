// The menu notice takes the free height under the grid; when that strip is short, the grid moves up by the rest.
// Checks the three cases: room to spare, short by a little, and too short for a notice.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:letselevatorneo/constant.dart';
import 'package:letselevatorneo/extension.dart';
import 'package:letselevatorneo/l10n/app_localizations.dart';
import 'package:letselevatorneo/menu.dart';
import 'package:letselevatorneo/promo/promo_session.dart';
import 'package:letselevatorneo/purchase_manager.dart';

final _settings = find.image(const AssetImage(settingsButton));
final _notice = find.byKey(const ValueKey('promoMenuBanner'));

Future<void> _pump(WidgetTester tester, Size size, {required bool installed, double topInset = 0}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = FakeViewPadding(top: topInset);
  addTearDown(tester.view.reset);
  PromoSession.platformOverride = () => true;
  PromoSession.adventureInstalled.value = installed;
  addTearDown(() {
    PromoSession.platformOverride = null;
    PromoSession.adventureInstalled.value = false;
  });
  PurchaseManager.priceSource = () async => null;
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const MenuPage(),
    ),
  ));
  await tester.pump(const Duration(seconds: 5));
}

/// The layout box the grid sits in: the smallest LayoutBuilder that holds the first menu button.
Rect _slot(WidgetTester tester) {
  final center = tester.getCenter(_settings);
  Rect? best;
  for (final e in find.byType(LayoutBuilder).evaluate()) {
    final r = tester.getRect(find.byElementPredicate((x) => x == e));
    if (r.contains(center) && (best == null || r.height < best.height)) best = r;
  }
  return best!;
}

/// The free height the grid is laid in, without the grid itself (R in the notes).
({Rect slot, double room, double margin, double notice}) _measure(WidgetTester tester) {
  final slot = _slot(tester);
  final size = tester.getSize(_settings).height;
  final ctx = tester.element(find.byType(MenuPage));
  final margin = ctx.menuButtonMargin();
  final room = slot.height - 2 * (size + 2 * margin);
  final notice = room - margin < ctx.promoBannerMaxHeight() ? room - margin: ctx.promoBannerMaxHeight();
  return (slot: slot, room: room, margin: margin, notice: notice);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('room to spare: the grid stays where it is with the notice', (tester) async {
    await _pump(tester, const Size(402, 874), installed: true);
    final without = tester.getTopLeft(_settings).dy;
    await _pump(tester, const Size(402, 874), installed: false);
    expect(_notice, findsOneWidget);
    expect(tester.getTopLeft(_settings).dy, closeTo(without, 0.5));
  });

  testWidgets('short by a little: the grid moves up by the rest, notice at its height', (tester) async {
    await _pump(tester, const Size(402, 874), installed: false, topInset: 250);
    final m = _measure(tester);
    final minNotice = tester.element(find.byType(MenuPage)).promoBannerMinHeight();
    expect(m.notice, greaterThanOrEqualTo(minNotice));
    expect(m.room / 2, lessThan(m.notice + m.margin));
    // The notice's strip is notice + margin; the grid sits above it.
    expect(tester.getTopLeft(_settings).dy, closeTo(m.slot.top + m.room - m.notice, 0.5));
    expect(tester.getSize(_notice).height, closeTo(m.notice, 0.5));
  });

  testWidgets('too short for a notice: no notice, grid in the middle', (tester) async {
    await _pump(tester, const Size(402, 874), installed: false, topInset: 300);
    final m = _measure(tester);
    final minNotice = tester.element(find.byType(MenuPage)).promoBannerMinHeight();
    expect(m.notice, lessThan(minNotice));
    expect(_notice, findsNothing);
    expect(tester.getTopLeft(_settings).dy, closeTo(m.slot.top + m.room / 2 + m.margin, 0.5));
  });
}

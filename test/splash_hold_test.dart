import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/splash_hold.dart';

void main() {
  late List<Duration> waits;
  late int removes;

  SplashHold hold(Duration elapsed) => SplashHold(
        elapsed: () => elapsed,
        delay: (d) async => waits.add(d),
        remove: () => removes++,
      );

  setUp(() {
    waits = [];
    removes = 0;
  });

  test('the minimum is 3 seconds', () {
    expect(splashMinDuration, const Duration(seconds: 3));
  });

  test('1 s elapsed waits 2 s, then removes', () async {
    await hold(const Duration(seconds: 1)).removeWhenReady();
    expect(waits, [const Duration(seconds: 2)]);
    expect(removes, 1);
  });

  test('3 s elapsed removes without waiting', () async {
    await hold(const Duration(seconds: 3)).removeWhenReady();
    expect(waits, isEmpty);
    expect(removes, 1);
  });

  test('more than 3 s elapsed removes without waiting', () async {
    await hold(const Duration(seconds: 7)).removeWhenReady();
    expect(waits, isEmpty);
    expect(removes, 1);
  });

  test('0 s elapsed waits 3 s', () async {
    await hold(Duration.zero).removeWhenReady();
    expect(waits, [const Duration(seconds: 3)]);
    expect(removes, 1);
  });

  test('a second call does not remove or wait again', () async {
    final h = hold(Duration.zero);
    await h.removeWhenReady();
    await h.removeWhenReady();
    expect(waits.length, 1);
    expect(removes, 1);
  });

  test('concurrent calls remove once', () async {
    final h = hold(Duration.zero);
    await Future.wait([h.removeWhenReady(), h.removeWhenReady()]);
    expect(removes, 1);
  });

  test('the real clock waits about 3 s when just started', () {
    final h = SplashHold()..start();
    expect(h.remaining(), greaterThan(const Duration(milliseconds: 2500)));
    expect(h.remaining(), lessThanOrEqualTo(splashMinDuration));
  });

  test('the overlay flag turns false after the removal', () async {
    final h = hold(const Duration(seconds: 1));
    expect(h.visible.value, isTrue);
    await h.removeWhenReady();
    expect(h.visible.value, isFalse);
  });

  test('the overlay flag stays true while waiting', () {
    final h = SplashHold(delay: (_) => Completer<void>().future, remove: () {}, elapsed: () => Duration.zero);
    unawaited(h.removeWhenReady());
    expect(h.visible.value, isTrue);
  });

  testWidgets('outside Android the overlay returns the child as is', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: SplashOverlay(child: Text('home')),
    ));
    expect(find.text('home'), findsOneWidget);
    expect(find.byType(RawImage), findsNothing);
  });

  testWidgets('loading the image never throws', (tester) async {
    await tester.runAsync(() => SplashHold().loadImage());
  });

  test('whenRemoved completes at once when the splash is already gone', () async {
    final h = hold(const Duration(seconds: 5));
    await h.removeWhenReady();
    await h.whenRemoved();
  });

  test('whenRemoved waits until the splash is removed', () async {
    final h = SplashHold(delay: (_) => Completer<void>().future, remove: () {}, elapsed: () => Duration.zero);
    var done = false;
    unawaited(h.whenRemoved().then((_) => done = true));
    await Future<void>.delayed(Duration.zero);
    expect(done, isFalse);
    h.visible.value = false;
    await Future<void>.delayed(Duration.zero);
    expect(done, isTrue);
  });

  test('the splash colour is the sRGB value of the iOS launch colour', () {
    expect(splashColor, const Color(0xFFF7B249));
  });
}

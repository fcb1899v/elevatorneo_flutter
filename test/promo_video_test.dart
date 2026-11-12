import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/promo/promo_video.dart';

// Fixtures: p1 and p2 are 3-frame animations of 16x16 frames at 100ms each.
// The stills are 8x8, so a test can tell a still from a frame by the image width.
final Map<String, Uint8List> _assets = {};

Future<Uint8List> _load(String name) async => _assets[name]!;

Widget _app({
  required List<String> patterns,
  required String first,
  required Key key,
  required GlobalKey<PromoVideoState> videoKey,
  bool stillOnly = false,
  void Function(String)? onChanged,
  void Function(String, bool)? onEnded,
  Duration Function()? clock,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(
      width: 200,
      height: 100,
      child: PromoVideo(
        key: videoKey,
        patterns: patterns,
        firstPattern: first,
        loadPattern: _load,
        loadStill: _load,
        stillOnly: stillOnly,
        onPatternChanged: onChanged,
        onPatternEnded: onEnded,
        clock: clock,
      ),
    ),
  );
}

/// Lets real time pass for decoding, then advances fake time by 20ms, repeatedly.
Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    elapsed += const Duration(milliseconds: 20);
  }
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 500 && !condition(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(condition(), isTrue, reason: 'condition was not reached in time');
}

/// A clock on the test's fake time, so scheduling does not depend on real time.
///
/// [skew] moves it ahead, as if a decode took that long.
class _TestClock {
  _TestClock(this._tester) : _start = _tester.binding.clock.now();

  final WidgetTester _tester;
  final DateTime _start;
  Duration skew = Duration.zero;

  Duration call() => _tester.binding.clock.now().difference(_start) + skew;
}

int? _shownWidth(WidgetTester tester) {
  return tester.widget<RawImage>(find.byType(RawImage)).image?.width;
}

void main() {
  setUpAll(() async {
    for (final name in ['p1', 'p2', 'p1_still', 'p2_still']) {
      _assets[name] = await File('test/fixtures/$name.webp').readAsBytes();
    }
    // broken1 is cut inside its first frame, so the codec cannot be created.
    // broken2 has a damaged first frame, so the codec fails when it decodes it.
    final whole = _assets['p1']!;
    _assets['broken1'] = Uint8List.sublistView(whole, 0, 60);
    _assets['broken2'] = Uint8List.fromList(whole)..[0x54] ^= 0xff;
    _assets['broken1_still'] = _assets['p1_still']!;
    _assets['broken2_still'] = _assets['p1_still']!;
  });

  testWidgets('shows the still first, then swaps to the first frame', (
    tester,
  ) async {
    // The animation's bytes are held back until the test releases them,
    // so the still must be on screen before any frame.
    final gate = Completer<void>();
    final videoKey = GlobalKey<PromoVideoState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 200,
          height: 100,
          child: PromoVideo(
            key: videoKey,
            patterns: const ['p1', 'p2'],
            firstPattern: 'p1',
            loadPattern: (name) async {
              await gate.future;
              return _assets[name]!;
            },
            loadStill: _load,
          ),
        ),
      ),
    );
    await _pumpUntil(tester, () => _shownWidth(tester) == 8);
    expect(videoKey.currentState!.patternsPlayed, 0);

    gate.complete();
    await _pumpUntil(tester, () => _shownWidth(tester) == 16);
    expect(videoKey.currentState!.patternsPlayed, 1);
  });

  testWidgets(
    'moves to the next pattern after the last frame and wraps to the first',
    (tester) async {
      final videoKey = GlobalKey<PromoVideoState>();
      final changed = <String>[];
      final ended = <(String, bool)>[];
      await tester.pumpWidget(
        _app(
          patterns: const ['p1', 'p2'],
          first: 'p1',
          key: UniqueKey(),
          videoKey: videoKey,
          onChanged: changed.add,
          onEnded: (p, c) => ended.add((p, c)),
        ),
      );
      final state = videoKey.currentState!;

      await _pumpUntil(tester, () => state.currentPattern == 'p2');
      expect(ended, [('p1', true)]);
      expect(changed, ['p1', 'p2']);

      await _pumpUntil(
        tester,
        () => state.currentPattern == 'p1' && state.patternsPlayed == 3,
      );
      expect(ended, [('p1', true), ('p2', true)]);
      expect(changed, ['p1', 'p2', 'p1']);
      expect(state.patternsPlayed, 3);
    },
  );

  testWidgets('shows only the still when reduced motion is on', (tester) async {
    final videoKey = GlobalKey<PromoVideoState>();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _app(
          patterns: const ['p1', 'p2'],
          first: 'p1',
          key: UniqueKey(),
          videoKey: videoKey,
        ),
      ),
    );
    await _pumpFor(tester, const Duration(milliseconds: 800));
    expect(videoKey.currentState!.patternsPlayed, 0);
    expect(_shownWidth(tester), 8);
  });

  testWidgets('shows only the still when the system reduce-motion flag is on', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final videoKey = GlobalKey<PromoVideoState>();
    await tester.pumpWidget(
      _app(
        patterns: const ['p1', 'p2'],
        first: 'p1',
        key: UniqueKey(),
        videoKey: videoKey,
      ),
    );
    await _pumpFor(tester, const Duration(milliseconds: 800));
    expect(videoKey.currentState!.patternsPlayed, 0);
    expect(_shownWidth(tester), 8);
  });

  testWidgets('stillOnly shows only the still', (tester) async {
    final videoKey = GlobalKey<PromoVideoState>();
    await tester.pumpWidget(
      _app(
        patterns: const ['p1', 'p2'],
        first: 'p1',
        key: UniqueKey(),
        videoKey: videoKey,
        stillOnly: true,
      ),
    );
    await _pumpFor(tester, const Duration(milliseconds: 800));
    expect(videoKey.currentState!.patternsPlayed, 0);
    expect(_shownWidth(tester), 8);
  });

  testWidgets('stops when TickerMode is off and resumes when it is back on', (
    tester,
  ) async {
    final videoKey = GlobalKey<PromoVideoState>();
    final ended = <(String, bool)>[];
    final enabled = ValueNotifier<bool>(true);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ValueListenableBuilder<bool>(
          valueListenable: enabled,
          builder: (context, on, _) => TickerMode(
            enabled: on,
            child: SizedBox(
              width: 200,
              height: 100,
              child: PromoVideo(
                key: videoKey,
                patterns: const ['p1', 'p2'],
                firstPattern: 'p1',
                loadPattern: _load,
                loadStill: _load,
                onPatternEnded: (p, c) => ended.add((p, c)),
              ),
            ),
          ),
        ),
      ),
    );
    final state = videoKey.currentState!;
    await _pumpUntil(
      tester,
      () => state.currentElapsed >= const Duration(milliseconds: 200),
    );

    enabled.value = false;
    await tester.pump();
    final elapsedAtStop = state.currentElapsed;
    final playedAtStop = state.patternsPlayed;
    await _pumpFor(tester, const Duration(milliseconds: 800));
    expect(state.currentElapsed, elapsedAtStop);
    expect(state.patternsPlayed, playedAtStop);
    expect(ended, isEmpty, reason: 'a pause does not end the pattern');

    enabled.value = true;
    await tester.pump();
    await _pumpUntil(tester, () => state.patternsPlayed > playedAtStop);
    expect(ended, [('p1', true)]);
  });

  testWidgets('pauses when the app is not in front without reporting an end', (
    tester,
  ) async {
    final videoKey = GlobalKey<PromoVideoState>();
    final ended = <(String, bool)>[];
    await tester.pumpWidget(
      _app(
        patterns: const ['p1', 'p2'],
        first: 'p1',
        key: UniqueKey(),
        videoKey: videoKey,
        onEnded: (p, c) => ended.add((p, c)),
      ),
    );
    final state = videoKey.currentState!;
    await _pumpUntil(
      tester,
      () => state.currentElapsed >= const Duration(milliseconds: 200),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    final elapsedAtStop = state.currentElapsed;
    await _pumpFor(tester, const Duration(milliseconds: 600));
    expect(state.currentElapsed, elapsedAtStop);
    expect(ended, isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await _pumpUntil(tester, () => state.currentPattern == 'p2');
    expect(ended, [('p1', true)]);
  });

  testWidgets('reports a cut-off pattern once when the widget is removed', (
    tester,
  ) async {
    final videoKey = GlobalKey<PromoVideoState>();
    final ended = <(String, bool)>[];
    await tester.pumpWidget(
      _app(
        patterns: const ['p1', 'p2'],
        first: 'p1',
        key: UniqueKey(),
        videoKey: videoKey,
        onEnded: (p, c) => ended.add((p, c)),
      ),
    );
    final state = videoKey.currentState!;
    await _pumpUntil(
      tester,
      () => state.currentElapsed >= const Duration(milliseconds: 200),
    );

    // A pause first must not add a report of its own.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(ended, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpFor(tester, const Duration(milliseconds: 400));
    expect(ended, [('p1', false)]);
  });

  testWidgets('starts from the first pattern when firstPattern is not listed', (
    tester,
  ) async {
    final videoKey = GlobalKey<PromoVideoState>();
    final changed = <String>[];
    await tester.pumpWidget(
      _app(
        patterns: const ['p1', 'p2'],
        first: 'gone',
        key: UniqueKey(),
        videoKey: videoKey,
        onChanged: changed.add,
      ),
    );
    await _pumpUntil(tester, () => changed.isNotEmpty);
    expect(changed.first, 'p1');
    expect(videoKey.currentState!.currentPattern, 'p1');
  });

  testWidgets('plays nothing and does not fail when the list is empty', (
    tester,
  ) async {
    final videoKey = GlobalKey<PromoVideoState>();
    final changed = <String>[];
    await tester.pumpWidget(
      _app(
        patterns: const [],
        first: 'p1',
        key: UniqueKey(),
        videoKey: videoKey,
        onChanged: changed.add,
      ),
    );
    await _pumpFor(tester, const Duration(milliseconds: 400));
    expect(changed, isEmpty);
    expect(videoKey.currentState!.patternsPlayed, 0);
    expect(videoKey.currentState!.currentPattern, '');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a pattern lasts the sum of its frame lengths, not decode time', (
    tester,
  ) async {
    final clock = _TestClock(tester);
    final videoKey = GlobalKey<PromoVideoState>();
    Duration? endedAt;
    await tester.pumpWidget(
      _app(
        patterns: const ['p1', 'p2'],
        first: 'p1',
        key: UniqueKey(),
        videoKey: videoKey,
        clock: clock.call,
        onEnded: (p, c) {
          if (p == 'p1') endedAt = clock.call();
        },
      ),
    );
    await _pumpUntil(tester, () => endedAt != null);
    // Three frames of 100ms: the pattern ends 300ms after its first frame.
    expect(endedAt!.inMilliseconds, inInclusiveRange(300, 340));
  });

  testWidgets('frames that are late are shown without waiting again', (
    tester,
  ) async {
    final clock = _TestClock(tester);
    final videoKey = GlobalKey<PromoVideoState>();
    Duration? endedAt;
    var stalled = false;
    await tester.pumpWidget(
      _app(
        patterns: const ['p1', 'p2'],
        first: 'p1',
        key: UniqueKey(),
        videoKey: videoKey,
        clock: clock.call,
        // The clock jumps once the first frame is on screen, as if decoding stalled.
        onChanged: (_) {
          if (stalled) return;
          stalled = true;
          clock.skew = const Duration(milliseconds: 150);
        },
        onEnded: (p, c) {
          if (p == 'p1') endedAt = clock.call();
        },
      ),
    );
    final startedAt = tester.binding.clock.now();
    await _pumpUntil(tester, () => endedAt != null);
    // The end is still due 300ms after the first frame on the clock,
    // so only about 150ms of real waiting is left.
    final waited = tester.binding.clock.now().difference(startedAt);
    expect(stalled, isTrue);
    expect(endedAt!.inMilliseconds, inInclusiveRange(300, 340));
    expect(waited.inMilliseconds, inInclusiveRange(120, 200));
  });

  testWidgets('continues at the right speed after a pause', (tester) async {
    final clock = _TestClock(tester);
    final videoKey = GlobalKey<PromoVideoState>();
    Duration? endedAt;
    await tester.pumpWidget(
      _app(
        patterns: const ['p1', 'p2'],
        first: 'p1',
        key: UniqueKey(),
        videoKey: videoKey,
        clock: clock.call,
        onEnded: (p, c) {
          if (p == 'p1') endedAt = clock.call();
        },
      ),
    );
    final state = videoKey.currentState!;
    await _pumpUntil(
      tester,
      () => state.currentElapsed >= const Duration(milliseconds: 200),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    final pausedAt = clock.call();
    await tester.pump(const Duration(seconds: 5));
    expect(endedAt, isNull);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    final resumedAt = clock.call();
    await _pumpUntil(tester, () => endedAt != null);
    // The pattern had about 300ms - pausedAt left when it was paused.
    final left = endedAt! - resumedAt;
    final expected = const Duration(milliseconds: 300) - pausedAt;
    expect(
      (left - expected).inMilliseconds.abs(),
      lessThanOrEqualTo(40),
      reason: 'left $left, expected about $expected',
    );
  });

  testWidgets('skips a pattern that cannot be decoded and plays the next', (
    tester,
  ) async {
    final videoKey = GlobalKey<PromoVideoState>();
    final events = <String>[];
    await tester.pumpWidget(
      _app(
        patterns: const ['broken1', 'p2'],
        first: 'broken1',
        key: UniqueKey(),
        videoKey: videoKey,
        onChanged: (p) => events.add('changed:$p'),
        onEnded: (p, c) => events.add('ended:$p:$c'),
      ),
    );
    await _pumpUntil(tester, () => events.contains('changed:p2'));
    expect(events.where((e) => e == 'ended:broken1:false'), hasLength(1));
    expect(
      events.indexOf('ended:broken1:false'),
      lessThan(events.indexOf('changed:p2')),
    );
    expect(videoKey.currentState!.currentPattern, 'p2');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('stops instead of looping when every pattern fails', (
    tester,
  ) async {
    final videoKey = GlobalKey<PromoVideoState>();
    final ended = <(String, bool)>[];
    var loads = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 200,
          height: 100,
          child: PromoVideo(
            key: videoKey,
            patterns: const ['broken1', 'broken2'],
            firstPattern: 'broken1',
            loadPattern: (name) {
              loads++;
              return _load(name);
            },
            loadStill: _load,
            onPatternEnded: (p, c) => ended.add((p, c)),
          ),
        ),
      ),
    );
    await _pumpUntil(tester, () => ended.length >= 2);
    await _pumpFor(tester, const Duration(milliseconds: 600));
    expect(ended, [('broken1', false), ('broken2', false)]);
    expect(loads, 2);
    expect(videoKey.currentState!.patternsPlayed, 0);
    // The still stays on screen.
    expect(_shownWidth(tester), 8);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

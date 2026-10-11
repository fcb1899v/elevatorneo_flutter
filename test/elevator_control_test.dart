// How the car answers its buttons: door time for hall and car calls, floors behind the car, and cancelling the next stop.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:letselevatorneo/audio_manager.dart';
import 'package:letselevatorneo/extension.dart';
import 'package:letselevatorneo/games_manager.dart';
import 'package:letselevatorneo/homepage.dart';
import 'package:letselevatorneo/l10n/app_localizations.dart';
import 'package:letselevatorneo/plan_provider.dart';
import 'package:letselevatorneo/purchase_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tts = MethodChannel("flutter_tts");

/// A player that starts and ends at once
class _QuietPlayer extends Fake implements AudioPlayer {
  @override
  bool get playing => false;
  @override
  Future<void> stop() async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<Duration?> setAsset(String assetPath, {bool preload = true, String? package, Duration? initialPosition, dynamic tag}) async => null;
  @override
  Future<void> play() async {}
  @override
  PlayerState get playerState => PlayerState(false, ProcessingState.idle);
}

Finder _floorButton(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate((w) => w is GestureDetector && w.onDoubleTap != null),
);

/// The landing's up button, lit or not
Finder _hallUpButton() => find.byWidgetPredicate((w) =>
  w is Image && w.image is AssetImage && RegExp(r"/up\d+(Pressed)?\.png$").hasMatch((w.image as AssetImage).assetName));

/// The alert button: the first button with a long press and no double tap
Finder _alertButton() => find.byWidgetPredicate((w) => w is GestureDetector && w.onLongPress != null && w.onDoubleTap == null).first;

/// Taps [finder] and returns what the app printed while handling the touch
Future<List<String>> _tapLogged(WidgetTester tester, Finder finder) async {
  final logs = <String>[];
  await runZoned(() => tester.tap(finder), zoneSpecification: ZoneSpecification(
    print: (self, parent, zone, line) => logs.add(line),
  ));
  return logs;
}

/// The image under a floor button, which is how its lamp shows
String _lamp(WidgetTester tester, String label) {
  final image = tester.widget<Image>(find.descendant(of: _floorButton(label), matching: find.byType(Image)).first);
  return (image.image as AssetImage).assetName;
}

Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  for (var t = Duration.zero; t < total; t += const Duration(milliseconds: 10)) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

/// The car display reads " 4" for 4F: the letter, a space and the number
bool _displayShows(String floor) => find.text(" $floor", findRichText: true).evaluate().isNotEmpty;

/// Steps in 10 ms until the car display shows [floor]; false after [limit]
Future<bool> _waitDisplay(WidgetTester tester, String floor, {Duration limit = const Duration(seconds: 60)}) async {
  for (var t = Duration.zero; t < limit; t += const Duration(milliseconds: 10)) {
    if (_displayShows(floor)) return true;
    await tester.pump(const Duration(milliseconds: 10));
  }
  return false;
}

Future<void> _doubleTap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<String> spoken;

  int count(String text) => spoken.where((s) => s.contains(text)).length;

  /// Steps in 10 ms until [text] has been spoken [times] times; the time it took, or null after [limit]
  Future<Duration?> waitSpoken(WidgetTester tester, String text, {int times = 1, Duration limit = const Duration(seconds: 60)}) async {
    for (var t = Duration.zero; t < limit; t += const Duration(milliseconds: 10)) {
      if (count(text) >= times) return t;
      await tester.pump(const Duration(milliseconds: 10));
    }
    return null;
  }

  setUp(() {
    spoken = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_tts, (call) async {
      if (call.method == "speak") spoken.add("${call.arguments}");
      return call.method == "getVoices" ? <Object>[] : 1;
    });
    GamesManager.nativeGamesSignIn = () async => false;
    AudioManager.createPlayer = _QuietPlayer.new;
    SharedPreferences.setMockInitialValues({});
    PurchaseManager.resetPrice();
    PurchaseManager.priceSource = () async => "";
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      "plugins.flutter.io/google_mobile_ads/ump", (message) async {
        final method = const StandardMessageCodec().readValue(ReadBuffer(message!));
        return (method == "ConsentInformation#canRequestAds")
          ? const StandardMethodCodec().encodeSuccessEnvelope(false)
          : const StandardMethodCodec().encodeErrorEnvelope(code: "0", message: "no UMP in tests");
      },
    );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_tts, null);
    PurchaseManager.resetPrice();
    AudioManager.createPlayer = AudioPlayer.new;
  });

  /// Opens the home screen, which starts outside on the 1F landing with the car on 2F
  Future<void> openHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [planProvider.overrideWith(() => PlanNotifier(const PlanState(isPremium: true)))],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const HomePage(),
      ),
    ));
    await _pumpFor(tester, const Duration(seconds: 4));
  }

  /// Calls the car to the 1F landing, then steps inside while its doors are open
  Future<void> boardAt1F(WidgetTester tester) async {
    await tester.tap(_hallUpButton().first);
    expect(await waitSpoken(tester, "Doors opening"), isNotNull, reason: "the car arrives at 1F");
    await _pumpFor(tester, const Duration(milliseconds: 2500));
    await tester.tap(find.byIcon(CupertinoIcons.arrowtriangle_up_fill).first);
    await _pumpFor(tester, const Duration(milliseconds: 500));
  }

  group("floor helpers", () {
    test("nothing is behind a car with nothing to do", () {
      expect(2.isBehindCar(counter: 5, nextFloor: 5, departureFloor: 1, isMoving: false), isFalse);
    });
    test("on the way up floors below are behind, on the way down floors above", () {
      expect(2.isBehindCar(counter: 5, nextFloor: 8, departureFloor: 1, isMoving: true), isTrue);
      expect(7.isBehindCar(counter: 5, nextFloor: 8, departureFloor: 1, isMoving: true), isFalse);
      expect(7.isBehindCar(counter: 5, nextFloor: 2, departureFloor: 8, isMoving: true), isTrue);
    });
    test("while the car waits on arrival, the ride's start gives the direction", () {
      expect(3.isBehindCar(counter: 5, nextFloor: 5, departureFloor: 1, isMoving: true), isTrue);
      expect(3.isBehindCar(counter: 5, nextFloor: 5, departureFloor: 9, isMoving: true), isFalse);
    });
    test("the nearest selected floor ahead skips floor 0 and stops at none", () {
      final above = List.generate(164, (_) => false)..[6] = true;
      final under = List.generate(13, (_) => false)..[1] = true;
      expect(2.nearestSelectedAhead(true, above, under), 6);
      expect(6.nearestSelectedAhead(true, above, under), isNull);
      expect(2.nearestSelectedAhead(false, above, under), -1);
      expect((-1).nearestSelectedAhead(false, above, under), isNull);
    });
  });

  testWidgets("after a hall call stop the doors start closing about 5 s after they open", (tester) async {
    await openHome(tester);
    await tester.tap(_hallUpButton().first);
    expect(await waitSpoken(tester, "Doors opening"), isNotNull, reason: "the car arrives at 1F");
    final waited = await waitSpoken(tester, "Doors closing", limit: const Duration(seconds: 20));
    // 2 s of opening and 5 s open; it was 2 s and 10 s
    expect(waited, isNotNull);
    expect(waited!, greaterThan(const Duration(milliseconds: 6500)));
    expect(waited, lessThan(const Duration(milliseconds: 9000)));
    await _pumpFor(tester, const Duration(seconds: 10));
  });

  testWidgets("after a car call stop the doors start closing about 3 s after they open", (tester) async {
    await openHome(tester);
    await boardAt1F(tester);
    await tester.tap(_floorButton("4"));
    expect(await waitSpoken(tester, "4th"), isNotNull, reason: "the car arrives at 4F");
    final closings = count("Doors closing");
    final waited = await waitSpoken(tester, "Doors closing", times: closings + 1, limit: const Duration(seconds: 20));
    expect(waited, isNotNull);
    expect(waited!, greaterThan(const Duration(milliseconds: 4500)));
    expect(waited, lessThan(const Duration(milliseconds: 6000)));
    await _pumpFor(tester, const Duration(seconds: 10));
  });

  testWidgets("a floor behind the rising car does not light; one ahead does", (tester) async {
    await openHome(tester);
    await boardAt1F(tester);
    final unlit = _lamp(tester, "154");
    await tester.tap(_floorButton("14"));
    expect(await _waitDisplay(tester, "4"), isTrue);
    await tester.tap(_floorButton("2"));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(_floorButton("6"));
    // The lamps are redrawn with the next floor step
    expect(await _waitDisplay(tester, "5"), isTrue);
    expect(_lamp(tester, "2"), unlit, reason: "2F is behind the car");
    expect(_lamp(tester, "6"), isNot(unlit), reason: "6F is ahead");
    await _pumpFor(tester, const Duration(seconds: 40));
  });

  testWidgets("cancelling the next stop sends the car on to the next lit floor", (tester) async {
    await openHome(tester);
    await boardAt1F(tester);
    final unlit = _lamp(tester, "154");
    final openings = count("Doors opening");
    await tester.tap(_floorButton("4"));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(_floorButton("6"));
    expect(await _waitDisplay(tester, "2"), isTrue);
    await _doubleTap(tester, _floorButton("4"));
    expect(await _waitDisplay(tester, "3"), isTrue);
    expect(_lamp(tester, "4"), unlit, reason: "the stop was cancelled");
    expect(await waitSpoken(tester, "6th", limit: const Duration(seconds: 30)), isNotNull, reason: "the car goes on to 6F");
    expect(count("Doors opening") - openings, 1, reason: "no stop at 4F on the way");
    await _pumpFor(tester, const Duration(seconds: 15));
  });

  testWidgets("a moving car keeps its only stop ahead when it is cancelled", (tester) async {
    await openHome(tester);
    await boardAt1F(tester);
    final unlit = _lamp(tester, "154");
    await tester.tap(_floorButton("4"));
    expect(await _waitDisplay(tester, "2"), isTrue);
    await _doubleTap(tester, _floorButton("4"));
    expect(await _waitDisplay(tester, "3"), isTrue);
    expect(_lamp(tester, "4"), isNot(unlit), reason: "nothing else to go to, so the stop stays");
    expect(await waitSpoken(tester, "4th", limit: const Duration(seconds: 30)), isNotNull);
    await _pumpFor(tester, const Duration(seconds: 15));
  });

  testWidgets("cancelling while the car waits to depart leaves it where it is", (tester) async {
    await openHome(tester);
    await boardAt1F(tester);
    expect(await waitSpoken(tester, "Doors closing", limit: const Duration(seconds: 20)), isNotNull);
    await _pumpFor(tester, const Duration(seconds: 3));
    final goingUp = count("Going up");
    await tester.tap(_floorButton("4"));
    // Past the 2 s wait after the press: the car now waits inside its own departure wait
    await _pumpFor(tester, const Duration(milliseconds: 2500));
    await _doubleTap(tester, _floorButton("4"));
    await _pumpFor(tester, const Duration(seconds: 10));
    expect(count("Going up"), goingUp, reason: "the car never left 1F");
    expect(_displayShows("1"), isTrue);
  });

  testWidgets("a car with nothing to do takes a floor below it", (tester) async {
    await openHome(tester);
    await boardAt1F(tester);
    final logs = await _tapLogged(tester, _floorButton("B1"));
    expect(logs.where((l) => l.contains("Behind the car")), isEmpty);
    expect(await waitSpoken(tester, "Going down"), isNotNull);
    await _pumpFor(tester, const Duration(seconds: 25));
  });

  testWidgets("a floor behind pressed while the car waits on arrival does not light", (tester) async {
    await openHome(tester);
    await boardAt1F(tester);
    await tester.tap(_floorButton("4"));
    expect(await _waitDisplay(tester, "4"), isTrue);
    final logs = await _tapLogged(tester, _floorButton("2"));
    expect(logs.any((l) => l.contains("Behind the car, not registered: 2")), isTrue);
    await _pumpFor(tester, const Duration(seconds: 20));
  });

  testWidgets("repeated cancels never leave the car stuck", (tester) async {
    await openHome(tester);
    await boardAt1F(tester);
    await tester.tap(_floorButton("4"));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(_floorButton("6"));
    expect(await _waitDisplay(tester, "2"), isTrue);
    await _doubleTap(tester, _floorButton("4"));
    await _doubleTap(tester, _floorButton("6"));
    await tester.tap(_floorButton("14"));
    await tester.pump(const Duration(milliseconds: 50));
    await _doubleTap(tester, _floorButton("6"));
    expect(await waitSpoken(tester, "14th", limit: const Duration(seconds: 40)), isNotNull, reason: "the car goes on to 14F");
    await _pumpFor(tester, const Duration(seconds: 15));
    final openings = count("Doors opening");
    await tester.tap(_floorButton("4"));
    expect(await waitSpoken(tester, "Doors opening", times: openings + 1, limit: const Duration(seconds: 40)), isNotNull, reason: "the car still answers after the cancels");
    await _pumpFor(tester, const Duration(seconds: 15));
  });

  testWidgets("an emergency waits 10 s before the return to 1F is announced", (tester) async {
    await openHome(tester);
    await boardAt1F(tester);
    await tester.tap(_floorButton("100"));
    expect(await _waitDisplay(tester, "9"), isTrue);
    final press = await tester.startGesture(tester.getCenter(_alertButton()));
    await _pumpFor(tester, const Duration(milliseconds: 520));
    await press.up();
    expect(await waitSpoken(tester, "Emergency", limit: const Duration(seconds: 10)), isNotNull);
    final waited = await waitSpoken(tester, "first floor", limit: const Duration(seconds: 20));
    expect(waited, isNotNull);
    expect(waited!, greaterThan(const Duration(milliseconds: 9500)));
    expect(waited, lessThan(const Duration(milliseconds: 10500)));
    await _pumpFor(tester, const Duration(seconds: 60));
  });
}

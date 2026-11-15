// A floor button selects on touch, without waiting out the double-tap window, and a double tap still cancels.

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:letselevatorneo/audio_manager.dart';
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

/// The lamp image of a floor button, which changes when the floor is selected
String _lampOf(WidgetTester tester, String label) {
  final images = find.descendant(of: _floorButton(label), matching: find.byType(Image));
  return tester.widgetList<Image>(images).map((w) => (w.image as AssetImage).assetName).join(",");
}

/// Runs [body] and returns what it printed
Future<List<String>> _printsOf(Future<void> Function() body) async {
  final lines = <String>[];
  await runZoned(body, zoneSpecification: ZoneSpecification(print: (_, _, _, line) => lines.add(line)));
  return lines;
}

/// The line the car prints when it selects [floor] as the next stop: "currentFloor: 1, nextFloor: 6"
bool _selectedAsNext(String line, int floor) => line.startsWith("currentFloor: ") && line.endsWith(", nextFloor: $floor");

Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  for (var t = Duration.zero; t < total; t += const Duration(milliseconds: 10)) {
    await tester.pump(const Duration(milliseconds: 10));
  }
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

  /// Lets the ride and the doors run out, so no timer is left when the test ends
  Future<void> finish(WidgetTester tester) async {
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

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
  /// The floor buttons only show inside the car, so every test boards first
  Future<void> boardAt1F(WidgetTester tester) async {
    await tester.tap(_hallUpButton().first);
    expect(await waitSpoken(tester, "Doors opening"), isNotNull, reason: "the car arrives at 1F");
    await _pumpFor(tester, const Duration(milliseconds: 2500));
    await tester.tap(find.byIcon(CupertinoIcons.arrowtriangle_up_fill).first);
    await _pumpFor(tester, const Duration(milliseconds: 500));
  }

  testWidgets("a touch selects the floor at once, before the double-tap window ends", (tester) async {
    await openHome(tester);
    await boardAt1F(tester);
    final lines = await _printsOf(() async {
      final touch = await tester.startGesture(tester.getCenter(_floorButton("6")));
      await tester.pump(const Duration(milliseconds: 10));
      await touch.up();
    });
    expect(lines.any((l) => _selectedAsNext(l, 6)), isTrue, reason: "selected 10 ms after the touch, well inside the 300 ms double-tap window");
    await finish(tester);
  });

  testWidgets("a double tap cancels a selected floor that is not the next stop", (tester) async {
    await openHome(tester);
    await boardAt1F(tester);
    final unlit = _lampOf(tester, "14");
    await tester.tap(_floorButton("14"));
    await tester.pump(const Duration(milliseconds: 500));
    final lit = _lampOf(tester, "14");
    expect(lit, isNot(unlit), reason: "14 is lit once selected");
    await tester.tap(_floorButton("6"));
    await tester.pump(const Duration(milliseconds: 500));
    final lines = await _printsOf(() async {
      await tester.tap(_floorButton("14"));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(_floorButton("14"));
      await tester.pump(const Duration(milliseconds: 500));
    });
    // Each touch selects first (no change, 14 is already selected), then the double tap cancels 14 and 6 stays next
    expect(lines.where((l) => _selectedAsNext(l, 6)).length, 1, reason: "floorCanceled logged once for the double tap");
    // The lamps are redrawn on a state change, and the doors closing gives one
    // The car has not reached 6 yet, so its lamp is still lit
    await tester.pump(const Duration(seconds: 10));
    expect(_lampOf(tester, "14"), unlit, reason: "14 is unlit again after the double tap");
    expect(_lampOf(tester, "6"), isNot(unlit), reason: "6 stays selected");
    await finish(tester);
  });

  testWidgets("a screen reader can still activate a floor button", (tester) async {
    final handle = tester.ensureSemantics();
    await openHome(tester);
    await boardAt1F(tester);
    final node = tester.getSemantics(find.descendant(of: _floorButton("6"), matching: find.byType(Image)).first);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue, reason: "the tap action a screen reader's double tap uses");
    final lines = await _printsOf(() async {
      tester.semantics.tap(find.semantics.byLabel("6"));
      await tester.pump(const Duration(milliseconds: 10));
    });
    expect(lines.any((l) => _selectedAsNext(l, 6)), isTrue);
    await finish(tester);
    handle.dispose();
  });
}

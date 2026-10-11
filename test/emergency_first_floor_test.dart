// A long press on the alert button that lands while the car passes 1F must still end the emergency, open the doors and free the buttons.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import 'package:letselevatorneo/review_manager.dart';
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

Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  for (var t = Duration.zero; t < total; t += const Duration(milliseconds: 10)) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

/// The text of the car display's first rich text, such as "B 3" for B3 and " 1" for 1F
String _displayText() => find.byType(RichText).evaluate().map((e) => (e.widget as RichText).text.toPlainText()).firstWhere((s) => s.length < 6 && s.trim().isNotEmpty, orElse: () => "");

bool _displayShowsText(String text) => _displayText() == text;

/// Steps in 10 ms until the car display reads [text]; false after [limit]
Future<bool> _waitDisplayText(WidgetTester tester, String text, {Duration limit = const Duration(seconds: 60)}) async {
  for (var t = Duration.zero; t < limit; t += const Duration(milliseconds: 10)) {
    if (_displayShowsText(text)) return true;
    await tester.pump(const Duration(milliseconds: 10));
  }
  return false;
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

  testWidgets("an emergency judged while the car passes 1F ends: the doors open and the car answers", (tester) async {
    await openHome(tester);
    await boardAt1F(tester);
    await tester.tap(_floorButton("B12"));
    expect(await waitSpoken(tester, "12th basement", limit: const Duration(seconds: 90)), isNotNull, reason: "the car reaches B12");
    await _pumpFor(tester, const Duration(seconds: 6));

    // Rising to 14F, the display shows B3 for 0.5 s; a press 0.1 s into B3 is judged 0.8 s on, while B1 shows, and the step in progress ends the car at 1F
    await tester.tap(_floorButton("14"));
    expect(await _waitDisplayText(tester, "B 3"), isTrue, reason: "the car rises to B3");
    await _pumpFor(tester, const Duration(milliseconds: 100));
    final press = await tester.startGesture(tester.getCenter(_alertButton()));
    await _pumpFor(tester, const Duration(milliseconds: 520));
    await press.up();
    await _pumpFor(tester, const Duration(milliseconds: 330));
    expect(await waitSpoken(tester, "Emergency stop"), isNotNull, reason: "the press became an emergency");
    expect(await waitSpoken(tester, "Returning to the first floor", limit: const Duration(seconds: 30)), isNotNull);

    // At 1F nothing arrives, so the emergency ends by itself: the doors open and the view button shows
    final rides = await ReviewManager.incrementRideCount();
    final openings = count("Doors opening");
    expect(await waitSpoken(tester, "Doors opening", times: openings + 1, limit: const Duration(seconds: 20)), isNotNull, reason: "the doors open at 1F");
    await _pumpFor(tester, const Duration(milliseconds: 2500));
    expect(find.byIcon(CupertinoIcons.arrowtriangle_up_fill), findsWidgets, reason: "the view button shows at the open doors");
    expect(await ReviewManager.incrementRideCount(), rides + 2, reason: "the return to 1F counts as a finished ride, as any other arrival does");

    // Recovered: a floor button moves the car again
    await tester.tap(_floorButton("6"));
    expect(await waitSpoken(tester, "6th", limit: const Duration(seconds: 60)), isNotNull, reason: "the car answers after the emergency");
    await _pumpFor(tester, const Duration(seconds: 15));
  });
}

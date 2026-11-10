// Checks that a floor pressed while the car announces its arrival still ends with open doors and a normal next ride.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:letselevatorneo/audio_manager.dart';
import 'package:letselevatorneo/constant.dart';
import 'package:letselevatorneo/games_manager.dart';
import 'package:letselevatorneo/homepage.dart';
import 'package:letselevatorneo/l10n/app_localizations.dart';
import 'package:letselevatorneo/plan_provider.dart';
import 'package:letselevatorneo/purchase_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tts = MethodChannel("flutter_tts");

/// How flutter_tts answers a stop or a new speech while an earlier speech is still going
enum _Interrupt {
  /// The earlier speech is not touched
  none,
  /// The earlier speech ends at once with 0, as on Android
  completes,
  /// The earlier speech never ends, as on iPhone before the fix
  hangs,
}

/// One speech call that has not ended yet
class _Utterance {
  final done = Completer<int>();
  Timer? timer;
}

_Interrupt _mode = _Interrupt.none;
final List<_Utterance> _pending = [];
final List<String> _logs = [];
final String _openingLog = "isDoorState: $openingState";

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

Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  for (var t = Duration.zero; t < total; t += const Duration(milliseconds: 10)) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

/// The car display reads " 4" for 4F: the letter, a space and the number
bool _displayShows(String floor) => find.text(" $floor", findRichText: true).evaluate().isNotEmpty;

/// The view button that shows at open doors
bool _viewButtonShown() => find.byIcon(CupertinoIcons.arrowtriangle_up_fill).evaluate().isNotEmpty;

/// Steps in 10 ms until the doors open, and returns true if the car display reads [floor] then.
/// Returns null if the doors never open or if [untilSpoken] is announced first, so a later floor's opening is not taken for this one.
Future<bool?> _doorsOpenShowing(WidgetTester tester, String floor, {String? untilSpoken, required int Function(String) count}) async {
  for (var t = Duration.zero; t < const Duration(seconds: 20); t += const Duration(milliseconds: 10)) {
    if (_logs.contains(_openingLog)) return _displayShows(floor);
    if (untilSpoken != null && count(untilSpoken) > 0) return null;
    await tester.pump(const Duration(milliseconds: 10));
  }
  return null;
}

/// Steps in 10 ms until [done] is true; false after [limit]
Future<bool> _until(WidgetTester tester, bool Function() done, {Duration limit = const Duration(seconds: 60)}) async {
  for (var t = Duration.zero; t < limit; t += const Duration(milliseconds: 10)) {
    if (done()) return true;
    await tester.pump(const Duration(milliseconds: 10));
  }
  return false;
}

/// Answers one call of the flutter_tts channel; a speech lasts 6 s for an arrival and 2 s otherwise
Future<Object?> _ttsCall(MethodCall call, List<String> spoken) async {
  if (call.method == "getVoices") return <Object>[];
  if (call.method == "stop") {
    _interruptPending();
    return 1;
  }
  if (call.method != "speak") return 1;
  final text = "${call.arguments}";
  spoken.add(text);
  _interruptPending();
  final utterance = _Utterance();
  _pending.add(utterance);
  final seconds = text.contains("Doors opening") ? 6 : 2;
  utterance.timer = Timer(Duration(seconds: seconds), () => _settle(utterance, 1));
  return utterance.done.future;
}

/// Applies the interrupt rule to every speech still going
void _interruptPending() {
  for (final utterance in List.of(_pending)) {
    switch (_mode) {
      case _Interrupt.none:
        break;
      case _Interrupt.completes:
        _settle(utterance, 0);
      case _Interrupt.hangs:
        _drop(utterance);
    }
  }
}

void _settle(_Utterance utterance, int value) {
  utterance.timer?.cancel();
  _pending.remove(utterance);
  if (!utterance.done.isCompleted) utterance.done.complete(value);
}

void _drop(_Utterance utterance) {
  utterance.timer?.cancel();
  _pending.remove(utterance);
}

/// Runs a test body and keeps what the app prints
Future<void> _captured(Future<void> Function() body) => runZoned(body, zoneSpecification: ZoneSpecification(
  print: (self, parent, zone, line) {
    _logs.add(line);
    parent.print(zone, line);
  },
));

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
    _logs.clear();
    _pending.clear();
    _mode = _Interrupt.none;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_tts, (call) => _ttsCall(call, spoken));
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
    for (final utterance in List.of(_pending)) {
      utterance.timer?.cancel();
    }
    _pending.clear();
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

  /// Calls the car to the 1F landing, then steps inside once its view button shows
  Future<void> boardAt1F(WidgetTester tester) async {
    await tester.tap(_hallUpButton().first);
    expect(await waitSpoken(tester, "Doors opening"), isNotNull, reason: "the car arrives at 1F");
    expect(await _until(tester, _viewButtonShown, limit: const Duration(seconds: 20)), isTrue, reason: "the doors open at 1F");
    await _pumpFor(tester, const Duration(milliseconds: 500));
    await tester.tap(find.byIcon(CupertinoIcons.arrowtriangle_up_fill).first);
    await _pumpFor(tester, const Duration(milliseconds: 500));
  }

  /// True if the doors close [closings] times before 6F is announced, so a later 6F closing does not count
  Future<bool> closingBefore6(WidgetTester tester, int closings) async {
    for (var t = Duration.zero; t < const Duration(seconds: 30); t += const Duration(milliseconds: 10)) {
      if (count("Doors closing") >= closings) return true;
      if (count("6th") > 0) return false;
      await tester.pump(const Duration(milliseconds: 10));
    }
    return false;
  }

  /// Rides up to 4F, presses 6 [pressAfter] into the 4F arrival announcement, then checks the stop and the ride on
  Future<void> arrivalThenPress(WidgetTester tester, Duration pressAfter) async {
    await openHome(tester);
    await boardAt1F(tester);
    await tester.tap(_floorButton("4"));
    expect(await waitSpoken(tester, "4th", limit: const Duration(seconds: 60)), isNotNull, reason: "the car reaches 4F");
    final closingsAt4 = count("Doors closing");
    _logs.clear();
    await _pumpFor(tester, pressAfter);
    await tester.tap(_floorButton("6"));

    final openAt4 = await _doorsOpenShowing(tester, "4", untilSpoken: "6th", count: count);
    await _pumpFor(tester, const Duration(milliseconds: 2500));
    final viewAt4 = _viewButtonShown();
    final closedAfter4 = await closingBefore6(tester, closingsAt4 + 1);

    final reached6 = await waitSpoken(tester, "6th", limit: const Duration(seconds: 60)) != null;
    _logs.clear();
    final openAt6 = await _doorsOpenShowing(tester, "6", count: count);
    await _pumpFor(tester, const Duration(milliseconds: 2500));
    await tester.tap(_floorButton("2"));
    final wentDown = await waitSpoken(tester, "Going down", limit: const Duration(seconds: 40)) != null;
    await _pumpFor(tester, const Duration(seconds: 60));

    // Every step is recorded before asserting, so one run shows all the steps that fail
    final steps = <String, bool>{
      "doors open at 4F while the display reads 4": openAt4 == true,
      "view button shows at the open doors at 4F": viewAt4,
      "doors close again after the 4F stop": closedAfter4,
      "car goes on to 6F and announces it": reached6,
      "doors open at 6F while the display reads 6": openAt6 == true,
      "car answers 2F after the 6F stop": wentDown,
    };
    final failed = steps.entries.where((e) => !e.value).map((e) => e.key).toList();
    expect(failed, isEmpty, reason: "steps that failed (4F open result: $openAt4, 6F open result: $openAt6)");
  }

  for (final mode in _Interrupt.values) {
    for (final press in [Duration.zero, const Duration(milliseconds: 500), const Duration(seconds: 2)]) {
      testWidgets("${mode.name}: 6F pressed ${press.inMilliseconds} ms into the 4F arrival ends with doors open at 4F and the ride on", (tester) => _captured(() async {
        _mode = mode;
        await arrivalThenPress(tester, press);
      }));
    }
  }
}

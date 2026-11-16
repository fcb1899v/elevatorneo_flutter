// Checks that the door closing sound and announcement play once per close, even when a second close call overlaps the first.

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

/// The English closeDoor text from lib/l10n/app_en.arb
const _closeText = "Doors closing";

final String _openedLog = "isDoorState: $openedState";
final String _closedLog = "isDoorState: $closedState";

/// One speech call that has not ended yet
class _Utterance {
  final done = Completer<int>();
  Timer? timer;
}

final List<_Utterance> _pending = [];
final List<String> _logs = [];
final List<String> _assets = [];

/// A player that starts and ends at once, and records each asset it is given
class _RecordingPlayer extends Fake implements AudioPlayer {
  @override
  bool get playing => false;
  @override
  Future<void> stop() async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<Duration?> setAsset(
    String assetPath, {
    bool preload = true,
    String? package,
    Duration? initialPosition,
    dynamic tag,
  }) async {
    _assets.add(assetPath);
    return null;
  }

  @override
  Future<void> play() async {}
  @override
  PlayerState get playerState => PlayerState(false, ProcessingState.idle);
}

/// The car's button whose image is named [name] (open, close or phone), lit or not
Finder _operationButton(String name) => find.ancestor(
  of: find.byWidgetPredicate(
    (w) =>
        w is Image &&
        w.image is AssetImage &&
        RegExp("/$name\\d+(Pressed)?\\.png\$")
            .hasMatch((w.image as AssetImage).assetName),
  ),
  matching: find.byWidgetPredicate(
    (w) =>
        w is GestureDetector && w.onLongPressStart != null && w.onTap != null,
  ),
);

/// The landing's up button, lit or not
Finder _hallUpButton() => find.byWidgetPredicate(
  (w) =>
      w is Image &&
      w.image is AssetImage &&
      RegExp(r"/up\d+(Pressed)?\.png$")
          .hasMatch((w.image as AssetImage).assetName),
);

Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  for (
    var t = Duration.zero;
    t < total;
    t += const Duration(milliseconds: 10)
  ) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

/// The view button that shows at open doors
bool _viewButtonShown() =>
    find.byIcon(CupertinoIcons.arrowtriangle_up_fill).evaluate().isNotEmpty;

/// Steps in 10 ms until [done] is true; false after [limit]
Future<bool> _until(
  WidgetTester tester,
  bool Function() done, {
  Duration limit = const Duration(seconds: 60),
}) async {
  for (
    var t = Duration.zero;
    t < limit;
    t += const Duration(milliseconds: 10)
  ) {
    if (done()) return true;
    await tester.pump(const Duration(milliseconds: 10));
  }
  return false;
}

/// Answers one call of the flutter_tts channel; the speech lasts 2 s, so a second close can overlap it
Future<Object?> _ttsCall(MethodCall call, List<String> spoken) async {
  if (call.method == "getVoices") return <Object>[];
  if (call.method == "stop") return 1;
  if (call.method != "speak") return 1;
  final text = "${call.arguments}";
  spoken.add(text);
  final utterance = _Utterance();
  _pending.add(utterance);
  utterance.timer = Timer(
    const Duration(seconds: 2),
    () => _settle(utterance, 1),
  );
  return utterance.done.future;
}

void _settle(_Utterance utterance, int value) {
  utterance.timer?.cancel();
  _pending.remove(utterance);
  if (!utterance.done.isCompleted) utterance.done.complete(value);
}

/// Runs a test body and keeps what the app prints
Future<void> _captured(Future<void> Function() body) => runZoned(
  body,
  zoneSpecification: ZoneSpecification(
    print: (self, parent, zone, line) {
      _logs.add(line);
      parent.print(zone, line);
    },
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<String> spoken;

  int count(String text) => spoken.where((s) => s.contains(text)).length;
  int closeSoundCount() => _assets.where((a) => a == closeSound).length;

  setUp(() {
    spoken = [];
    _logs.clear();
    _assets.clear();
    _pending.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_tts, (call) => _ttsCall(call, spoken));
    GamesManager.nativeGamesSignIn = () async => false;
    AudioManager.createPlayer = _RecordingPlayer.new;
    SharedPreferences.setMockInitialValues({});
    PurchaseManager.resetPrice();
    PurchaseManager.priceSource = () async => "";
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler("plugins.flutter.io/google_mobile_ads/ump", (
          message,
        ) async {
          final method = const StandardMessageCodec().readValue(
            ReadBuffer(message!),
          );
          return (method == "ConsentInformation#canRequestAds")
              ? const StandardMethodCodec().encodeSuccessEnvelope(false)
              : const StandardMethodCodec().encodeErrorEnvelope(
                  code: "0",
                  message: "no UMP in tests",
                );
        });
  });
  tearDown(() {
    for (final utterance in List.of(_pending)) {
      utterance.timer?.cancel();
    }
    _pending.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_tts, null);
    PurchaseManager.resetPrice();
    AudioManager.createPlayer = AudioPlayer.new;
  });

  /// Opens the home screen, which starts outside on the 1F landing with the car on 2F
  Future<void> openHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planProvider.overrideWith(
            () => PlanNotifier(const PlanState(isPremium: true)),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const HomePage(),
        ),
      ),
    );
    await _pumpFor(tester, const Duration(seconds: 4));
  }

  /// Calls the car to the 1F landing, then steps inside once its view button shows
  Future<void> boardAt1F(WidgetTester tester) async {
    await tester.tap(_hallUpButton().first);
    expect(
      await _until(
        tester,
        () =>
            _logs.contains(_openedLog) ||
            spoken.any((s) => s.contains("Doors opening")),
        limit: const Duration(seconds: 60),
      ),
      isTrue,
      reason: "the car arrives at 1F",
    );
    expect(
      await _until(
        tester,
        _viewButtonShown,
        limit: const Duration(seconds: 20),
      ),
      isTrue,
      reason: "the doors open at 1F",
    );
    await _pumpFor(tester, const Duration(milliseconds: 500));
    await tester.tap(find.byIcon(CupertinoIcons.arrowtriangle_up_fill).first);
    await _pumpFor(tester, const Duration(milliseconds: 500));
  }

  testWidgets(
    "close pressed during the car's own closing announcement announces and plays the close once",
    (tester) => _captured(() async {
      await openHome(tester);
      await boardAt1F(tester);
      expect(
        await _until(
          tester,
          () => _logs.contains(_openedLog),
          limit: const Duration(seconds: 20),
        ),
        isTrue,
        reason: "the doors are fully open",
      );

      spoken.clear();
      _assets.clear();
      // The car's own close starts announcing after the open time, while the doors are still open
      expect(
        await _until(
          tester,
          () => count(_closeText) > 0,
          limit: const Duration(seconds: 60),
        ),
        isTrue,
        reason: "the car starts closing on its own",
      );
      // The door state is still open during this announcement, so this second close call passes the state check
      await tester.tap(_operationButton("close"));
      await _pumpFor(tester, const Duration(seconds: 30));

      expect(
        count(_closeText),
        1,
        reason: "the closing announcement plays once (spoken: $spoken)",
      );
      expect(
        closeSoundCount(),
        1,
        reason: "the closing sound plays once (assets: $_assets)",
      );
    }),
  );

  testWidgets(
    "after a close and a reopen, the closing sound and announcement play once again",
    (tester) => _captured(() async {
      await openHome(tester);
      await boardAt1F(tester);
      expect(
        await _until(
          tester,
          () => _logs.contains(_openedLog),
          limit: const Duration(seconds: 20),
        ),
        isTrue,
        reason: "the doors are fully open",
      );
      expect(
        await _until(
          tester,
          () => _logs.contains(_closedLog),
          limit: const Duration(seconds: 60),
        ),
        isTrue,
        reason: "the doors close once",
      );

      spoken.clear();
      _assets.clear();
      _logs.clear();
      // The open button is ignored while the car is still busy, so it is pressed again each second
      var reopened = false;
      for (var i = 0; i < 60 && !reopened; i++) {
        await tester.tap(_operationButton("open"));
        await _pumpFor(tester, const Duration(seconds: 1));
        reopened = _logs.contains(_openedLog);
      }
      expect(reopened, isTrue, reason: "the doors open again");
      expect(
        await _until(
          tester,
          () => count(_closeText) > 0,
          limit: const Duration(seconds: 60),
        ),
        isTrue,
        reason: "the doors start closing again",
      );
      await _pumpFor(tester, const Duration(seconds: 30));

      expect(
        count(_closeText),
        1,
        reason:
            "the closing announcement plays once after reopen (spoken: $spoken)",
      );
      expect(
        closeSoundCount(),
        1,
        reason: "the closing sound plays once after reopen (assets: $_assets)",
      );
    }),
  );
}

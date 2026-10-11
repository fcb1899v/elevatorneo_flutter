// Miles reach the leaderboard on arrival once games services are signed in, and a ride never starts a sign-in.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:letselevatorneo/audio_manager.dart';
import 'package:letselevatorneo/games_manager.dart';
import 'package:letselevatorneo/homepage.dart';
import 'package:letselevatorneo/l10n/app_localizations.dart';
import 'package:letselevatorneo/main.dart';
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

const _games = MethodChannel("games_services");

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

  late List<MethodCall> games;
  late int signIns;
  late bool silentLeaderboard;

  setUp(() {
    dotenv.loadFromString(envString: "ANDROID_LEADERBOARD_ID=android\nIOS_LEADERBOARD_ID=ios");
    games = [];
    silentLeaderboard = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_games, (call) async {
      games.add(call);
      // A leaderboard that never answers, as on a dropped connection
      if (silentLeaderboard && call.method == "submitScore") return Completer<Object?>().future;
      return null;
    });
    signIns = 0;
    GamesManager.resetGamesSignIn();
    GamesManager.nativeGamesSignIn = () async {
      signIns++;
      return true;
    };
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_games, null);
  });

  /// Opens the home screen online, signed in to games services or not, and steps into the car at 1F
  Future<void> boardOnline(WidgetTester tester, {required bool signedIn}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        planProvider.overrideWith(() => PlanNotifier(const PlanState(isPremium: true))),
        gamesSignInProvider.overrideWith(() => GamesSignInNotifier(signedIn)),
        internetProvider.overrideWith(() => InternetNotifier(true)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const HomePage(),
      ),
    ));
    await _pumpFor(tester, const Duration(seconds: 4));
    await tester.tap(_hallUpButton().first);
    expect(await waitSpoken(tester, "Doors opening"), isNotNull, reason: "the car arrives at 1F");
    await _pumpFor(tester, const Duration(milliseconds: 2500));
    await tester.tap(find.byIcon(CupertinoIcons.arrowtriangle_up_fill).first);
    await _pumpFor(tester, const Duration(milliseconds: 500));
  }

  List<MethodCall> submits() => games.where((c) => c.method == "submitScore").toList();

  testWidgets("a signed-in rider's miles reach the leaderboard on arrival", (tester) async {
    await boardOnline(tester, signedIn: true);
    final before = submits().length;
    await tester.tap(_floorButton("4"));
    expect(await waitSpoken(tester, "4th"), isNotNull, reason: "the car arrives at 4F");
    await _pumpFor(tester, const Duration(seconds: 1));
    final saved = (await SharedPreferences.getInstance()).getInt("pointKey");
    expect(submits().length, before + 1, reason: "the arrival sends the miles");
    expect((submits().last.arguments as Map)["value"], saved, reason: "the sent miles are the saved miles");
    await _pumpFor(tester, const Duration(seconds: 10));
  });

  testWidgets("the doors open on arrival even when the leaderboard never answers", (tester) async {
    silentLeaderboard = true;
    await boardOnline(tester, signedIn: true);
    final before = submits().length;
    await tester.tap(_floorButton("4"));
    expect(await waitSpoken(tester, "4th"), isNotNull, reason: "the arrival goes on without waiting for the send");
    expect(submits().length, before + 1, reason: "the send was started");
    await _pumpFor(tester, const Duration(seconds: 10));
  });

  testWidgets("a ride never starts a games sign-in for a rider who is not signed in", (tester) async {
    await boardOnline(tester, signedIn: false);
    final before = signIns;
    await tester.tap(_floorButton("4"));
    expect(await waitSpoken(tester, "4th"), isNotNull, reason: "the car arrives at 4F");
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(signIns, before, reason: "sign-in runs at launch and from the menu, not on arrival");
    expect(submits(), isEmpty, reason: "nothing is sent without a sign-in");
    await _pumpFor(tester, const Duration(seconds: 10));
  });
}

// The menu's leaderboard button uses the sign-in and connection as they are when pressed, not as they were when the menu opened.
// The menu's own network check is real, so the test lets it end before pressing; whatever it finds, a stale state fails the press.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:letselevatorneo/constant.dart';
import 'package:letselevatorneo/games_manager.dart';
import 'package:letselevatorneo/l10n/app_localizations.dart';
import 'package:letselevatorneo/main.dart';
import 'package:letselevatorneo/menu.dart';
import 'package:letselevatorneo/purchase_manager.dart';

const _games = MethodChannel("games_services");
const _vibration = MethodChannel("vibration");

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<MethodCall> games;
  late int signIns;

  setUp(() {
    dotenv.loadFromString(envString: "ANDROID_LEADERBOARD_ID=android\nIOS_LEADERBOARD_ID=ios");
    games = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_games, (call) async {
      games.add(call);
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_vibration, (call) async => null);
    signIns = 0;
    GamesManager.resetGamesSignIn();
    GamesManager.nativeGamesSignIn = () async {
      signIns++;
      return true;
    };
    PurchaseManager.resetPrice();
    PurchaseManager.priceSource = () async => null;
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_games, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_vibration, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler("plugins.flutter.io/google_mobile_ads/ump", null);
    PurchaseManager.resetPrice();
  });

  testWidgets("a sign-in that lands after the menu opened still opens the leaderboard", (tester) async {
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    // Opened at launch, before the home screen's network check and sign-in have answered
    await tester.pumpWidget(ProviderScope(
      overrides: [
        internetProvider.overrideWith(() => InternetNotifier(false)),
        gamesSignInProvider.overrideWith(() => GamesSignInNotifier(false)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const MenuPage(),
      ),
    ));
    // The check's sockets answer in real time and its two 3 s timeouts run on the test clock, so step both
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 500));
    }
    // The home screen's check and sign-in land while the menu is open
    final container = ProviderScope.containerOf(tester.element(find.byType(MenuPage)));
    container.read(internetProvider.notifier).setValue(true);
    container.read(gamesSignInProvider.notifier).setValue(true);
    await tester.pump(const Duration(seconds: 1));
    final before = signIns;
    await tester.tap(find.image(const AssetImage(rankingButton)));
    await tester.pump(const Duration(seconds: 1));
    expect(games.where((c) => c.method == "showLeaderboards"), hasLength(1), reason: "the press opens the leaderboard");
    expect(signIns, before, reason: "already signed in, so the press starts no sign-in");
  });
}

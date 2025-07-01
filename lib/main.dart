import 'dart:async';
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:letselevatorneo/extension.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart' show AppLocalizations;
import 'constant.dart';
import 'homepage.dart';
import 'menu.dart';
import 'settings.dart';

final isTest = false;
// final isTest = true;
final isMenuProvider = StateProvider<bool>((ref) => false);
final floorNumbersProvider = StateProvider<List<int>>((ref) => initialFloorNumbers);
final floorStopsProvider = StateProvider<List<bool>>((ref) => initialFloorStops);
final floorImagesProvider = StateProvider<List<String>>((ref) => initialFloorImages);
final buttonShapeProvider = StateProvider<String>((ref) => initialButtonShape);
final buttonStyleProvider = StateProvider<int>((ref) => initialButtonStyle);
final backgroundStyleProvider = StateProvider<String>((ref) => initialBackgroundStyle);
final glassStyleProvider = StateProvider<String>((ref) => initialGlassStyle);
final outsideProvider = StateProvider<bool>((ref) => true);
final gamesSignInProvider = StateProvider<bool>((ref) => false);
final internetProvider = StateProvider<bool>((ref) => false);
final pointProvider = StateProvider<int>((ref) => 0);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  } else {
    // iOS用の設定
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }// Status bar style
  await dotenv.load(fileName: "assets/.env");
  final prefs = await SharedPreferences.getInstance();
  final savedFloorNumbers = "numbersKey".getSharedPrefListInt(prefs, initialFloorNumbers);
  final savedFloorStops = "stopsKey".getSharedPrefListBool(prefs, initialFloorStops);
  final savedButtonShape = "buttonShapeKey".getSharedPrefString(prefs, initialButtonShape);
  final savedButtonStyle = "buttonStyleKey".getSharedPrefInt(prefs, initialButtonStyle);
  final savedBackgroundStyle = "backgroundStyleKey".getSharedPrefString(prefs, initialBackgroundStyle);
  final savedGlassStyle = "glassStyleKey".getSharedPrefString(prefs, initialGlassStyle);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(
    overrides: [
      floorNumbersProvider.overrideWith((ref) => savedFloorNumbers),
      floorStopsProvider.overrideWith((ref) => savedFloorStops),
      buttonStyleProvider.overrideWith((ref) => savedButtonStyle),
      buttonShapeProvider.overrideWith((ref) => savedButtonShape),
      backgroundStyleProvider.overrideWith((ref) => savedBackgroundStyle),
      glassStyleProvider.overrideWith((ref) => savedGlassStyle),
      internetProvider.overrideWith((ref) => false),
      gamesSignInProvider.overrideWith((ref) => false),
      pointProvider.overrideWith((ref) => 0),
    ],
    child: const MyApp())
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: androidProvider,
    appleProvider: appleProvider,
  );
  await MobileAds.instance.initialize();
  await initATTPlugin();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
      child: child!,
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    title: appTitle,
    theme: ThemeData(primarySwatch: Colors.grey),
    debugShowCheckedModeBanner: false,
    initialRoute: "/h",
    routes: {
      "/h": (context) => const HomePage(),
      "/m": (context) => const MenuPage(),
      "/s": (context) => const SettingsPage(),
    },
    navigatorObservers: <NavigatorObserver>[
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      RouteObserver<ModalRoute>()
    ],
  );
}

///App Tracking Transparency
Future<void> initATTPlugin() async {
  if (Platform.isIOS || Platform.isMacOS) {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }
}

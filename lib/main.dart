import 'dart:async';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common_function.dart';
import 'firebase_options.dart';
import 'my_home_body.dart';
import 'constant.dart';
import 'extension.dart';

const isTest = false;
final isMenuProvider = StateProvider<bool>((ref) => false);
final isSettingsProvider = StateProvider<bool>((ref) => false);
final floorNumbersProvider = StateProvider<List<int>>((ref) => initialFloorNumbers);
final roomImagesProvider = StateProvider<List<String>>((ref) => initialRoomImages);
final pointProvider = StateProvider<int>((ref) => initialPoint);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedFloorNumbers = await "floorsKey".getSharedPrefListInt(prefs, initialFloorNumbers);
  final savedRoomImages = await "roomsKey".getSharedPrefListString(prefs, initialRoomImages);
  final savedPointValue = await 'pointKey'.getSharedPrefInt(prefs, initialPoint);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]); //縦向き指定
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  )); // Status bar style
  await dotenv.load(fileName: "assets/.env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: androidProvider,
    appleProvider: appleProvider,
  );
  await MobileAds.instance.initialize();
  await initATTPlugin();
  runApp(ProviderScope(
    overrides: [
      floorNumbersProvider.overrideWith((ref) => savedFloorNumbers),
      roomImagesProvider.overrideWith((ref) => savedRoomImages),
      pointProvider.overrideWith((ref) => savedPointValue),
    ],
    child: const MyApp())
  );
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
    routes: {"/h": (context) => const MyHomePage()},
    navigatorObservers: <NavigatorObserver>[
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      RouteObserver<ModalRoute>()
    ],
  );
}
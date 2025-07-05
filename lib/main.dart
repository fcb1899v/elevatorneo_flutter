// =============================
// Main: Entry point for elevator simulator application
//
// Handles app initialization, state management, and global configuration.
// Key features: Firebase setup, state providers, UI configuration, tracking
// =============================

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
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart' show AppLocalizations;
import 'firebase_options.dart';
import 'extension.dart';
import 'constant.dart';
import 'homepage.dart';
import 'menu.dart';
import 'settings.dart';

// --- Global Configuration ---
// Application-wide settings and flags for development and testing
final isTest = false;
// final isTest = true;

// --- State Providers ---
// Riverpod providers for global state management across the application
// Includes UI state (menu visibility, view modes), elevator configuration (floors, buttons, styles),
// user preferences, and system state (connectivity, game center, points)
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

// --- Application Initialization ---
// Main entry point that handles all app setup and initialization
// Sets up UI configuration, loads user preferences, initializes Firebase,
// and launches the app with proper state management
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // --- UI Configuration ---
  // Configure system UI, orientation, and platform-specific styling  
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  } else {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }
  // --- Environment and Data Loading ---
  // Load environment variables and restore user preferences from SharedPreferences
  await dotenv.load(fileName: "assets/.env");
  final prefs = await SharedPreferences.getInstance();
  final savedFloorNumbers = "numbersKey".getSharedPrefListInt(prefs, initialFloorNumbers);
  final savedFloorStops = "stopsKey".getSharedPrefListBool(prefs, initialFloorStops);
  final savedButtonShape = "buttonShapeKey".getSharedPrefString(prefs, initialButtonShape);
  final savedButtonStyle = "buttonStyleKey".getSharedPrefInt(prefs, initialButtonStyle);
  final savedBackgroundStyle = "backgroundStyleKey".getSharedPrefString(prefs, initialBackgroundStyle);
  final savedGlassStyle = "glassStyleKey".getSharedPrefString(prefs, initialGlassStyle);
  // --- Firebase Initialization ---
  // Initialize Firebase services with platform-specific configuration
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // --- App Launch ---
  // Launch the app with saved preferences and initial state overrides
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
  // --- Post-Launch Services ---
  // Initialize additional services after app launch (Firebase App Check, ads, tracking)
  await FirebaseAppCheck.instance.activate(
    androidProvider: androidProvider,
    appleProvider: appleProvider,
  );
  await MobileAds.instance.initialize();
  await initATTPlugin();
}

// --- Main Application Widget ---
// Root MaterialApp widget that configures the entire application
// Sets up localization, routing, theme, and navigation tracking
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
      child: child!,
    ),
    // --- Localization ---
    // Multi-language support configuration
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    // --- App Configuration ---
    // Basic app settings and theme
    title: appTitle,
    theme: ThemeData(primarySwatch: Colors.grey),
    debugShowCheckedModeBanner: false,
    // --- Routing ---
    // Navigation routes to different app screens
    initialRoute: "/h",
    routes: {
      "/h": (context) => const HomePage(),    // Elevator simulator
      "/m": (context) => const MenuPage(),    // Menu
      "/s": (context) => const SettingsPage(), // Settings
    },
    // --- Navigation Observers ---
    // Track navigation for analytics and debugging
    navigatorObservers: <NavigatorObserver>[
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      RouteObserver<ModalRoute>()
    ],
  );
}

// --- Privacy and Tracking ---
// App Tracking Transparency implementation for iOS/macOS
// Requests user permission for app tracking on supported platforms
Future<void> initATTPlugin() async {
  if (Platform.isIOS || Platform.isMacOS) {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }
}

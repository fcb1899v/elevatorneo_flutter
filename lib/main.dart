// =============================
// Main: Entry point for elevator simulator application
//
// Handles app initialization, state management, and global configuration.
// Key features: Firebase setup, state providers, UI configuration, tracking
// =============================

import 'dart:async';
import 'dart:io';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart' show AppLocalizations;
import 'firebase_options.dart';
import 'extension.dart';
import 'constant.dart';
import 'plan_provider.dart';
import 'admob_banner.dart';
import 'homepage.dart';
import 'menu.dart';
import 'settings.dart';

// --- Global Configuration ---
// Application-wide settings and flags for development and testing
final isTest = false;
// final isTest = true;

// --- State Providers ---
// Riverpod 3: NotifierProvider for mutable state (StateProvider was removed)

final isMenuProvider = NotifierProvider<IsMenuNotifier, bool>(IsMenuNotifier.new);
final floorNumbersProvider = NotifierProvider<FloorNumbersNotifier, List<int>>(FloorNumbersNotifier.new);
final floorStopsProvider = NotifierProvider<FloorStopsNotifier, List<bool>>(FloorStopsNotifier.new);
final floorImagesProvider = NotifierProvider<FloorImagesNotifier, List<String>>(FloorImagesNotifier.new);
final buttonShapeProvider = NotifierProvider<ButtonShapeNotifier, String>(ButtonShapeNotifier.new);
final buttonStyleProvider = NotifierProvider<ButtonStyleNotifier, int>(ButtonStyleNotifier.new);
final backgroundStyleProvider = NotifierProvider<BackgroundStyleNotifier, String>(BackgroundStyleNotifier.new);
final glassStyleProvider = NotifierProvider<GlassStyleNotifier, String>(GlassStyleNotifier.new);
final outsideProvider = NotifierProvider<OutsideNotifier, bool>(OutsideNotifier.new);
final gamesSignInProvider = NotifierProvider<GamesSignInNotifier, bool>(GamesSignInNotifier.new);
final internetProvider = NotifierProvider<InternetNotifier, bool>(InternetNotifier.new);
final pointProvider = NotifierProvider<PointNotifier, int>(PointNotifier.new);

class IsMenuNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setValue(bool value) => state = value;
}

class FloorNumbersNotifier extends Notifier<List<int>> {
  final List<int>? _override;
  FloorNumbersNotifier([this._override]);
  @override
  List<int> build() => _override ?? initialFloorNumbers;
  void setValue(List<int> value) => state = value;
}

class FloorStopsNotifier extends Notifier<List<bool>> {
  final List<bool>? _override;
  FloorStopsNotifier([this._override]);
  @override
  List<bool> build() => _override ?? initialFloorStops;
  void setValue(List<bool> value) => state = value;
}

class FloorImagesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => initialFloorImages;
  void setValue(List<String> value) => state = value;
}

class ButtonShapeNotifier extends Notifier<String> {
  final String? _override;
  ButtonShapeNotifier([this._override]);
  @override
  String build() => _override ?? initialButtonShape;
  void setValue(String value) => state = value;
}

class ButtonStyleNotifier extends Notifier<int> {
  final int? _override;
  ButtonStyleNotifier([this._override]);
  @override
  int build() => _override ?? initialButtonStyle;
  void setValue(int value) => state = value;
}

class BackgroundStyleNotifier extends Notifier<String> {
  final String? _override;
  BackgroundStyleNotifier([this._override]);
  @override
  String build() => _override ?? initialBackgroundStyle;
  void setValue(String value) => state = value;
}

class GlassStyleNotifier extends Notifier<String> {
  final String? _override;
  GlassStyleNotifier([this._override]);
  @override
  String build() => _override ?? initialGlassStyle;
  void setValue(String value) => state = value;
}

class OutsideNotifier extends Notifier<bool> {
  @override
  bool build() => true;
}

class GamesSignInNotifier extends Notifier<bool> {
  final bool? _override;
  GamesSignInNotifier([this._override]);
  @override
  bool build() => _override ?? false;
  void setValue(bool value) => state = value;
}

class InternetNotifier extends Notifier<bool> {
  final bool? _override;
  InternetNotifier([this._override]);
  @override
  bool build() => _override ?? false;
  void setValue(bool value) => state = value;
}

class PointNotifier extends Notifier<int> {
  final int? _override;
  PointNotifier([this._override]);
  @override
  int build() => _override ?? 0;
  void setValue(int value) => state = value;
  void add(int n) => state = state + n;
}

/// --- Application Initialization ---
// Main entry point that handles all app setup and initialization
// Sets up UI configuration, loads user preferences, initializes Firebase,
// and launches the app with proper state management
Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  /// --- UI Configuration ---
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
  /// --- Environment and Data Loading ---
  // Load environment variables and restore user preferences from SharedPreferences
  await dotenv.load(fileName: "assets/.env");
  final prefs = await SharedPreferences.getInstance();
  // Load saved user preferences and current date
  final savedFloorNumbers = "numbersKey".getSharedPrefListInt(prefs, initialFloorNumbers);
  final savedFloorStops = "stopsKey".getSharedPrefListBool(prefs, initialFloorStops);
  final savedButtonShape = "buttonShapeKey".getSharedPrefString(prefs, initialButtonShape);
  final savedButtonStyle = "buttonStyleKey".getSharedPrefInt(prefs, initialButtonStyle);
  final savedBackgroundStyle = "backgroundStyleKey".getSharedPrefString(prefs, initialBackgroundStyle);
  final savedGlassStyle = "glassStyleKey".getSharedPrefString(prefs, initialGlassStyle);
  /// --- Firebase Initialization ---
  // Initialize Firebase services with platform-specific configuration
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  /// --- Purchase Initialization ---
  // Configure RevenueCat and resolve the premium entitlement before the first frame
  // Skipped when no API key is configured yet, so the app still runs ad-supported
  final apiKey = dotenv.maybeGet(revenueCatApiKey);
  bool initialPremium = false;
  if (apiKey != null && apiKey.isNotEmpty) {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug: LogLevel.warn);
    await Purchases.configure(PurchasesConfiguration(apiKey));
    if (Platform.isIOS || Platform.isMacOS) {
      await Purchases.enableAdServicesAttributionTokenCollection();
    }
    initialPremium = await getInitialPremiumStatus();
  }
  /// --- App Launch ---
  // Launch the app with saved preferences and initial state overrides
  runApp(ProviderScope(
    overrides: [
      floorNumbersProvider.overrideWith(() => FloorNumbersNotifier(savedFloorNumbers)),
      floorStopsProvider.overrideWith(() => FloorStopsNotifier(savedFloorStops)),
      buttonStyleProvider.overrideWith(() => ButtonStyleNotifier(savedButtonStyle)),
      buttonShapeProvider.overrideWith(() => ButtonShapeNotifier(savedButtonShape)),
      backgroundStyleProvider.overrideWith(() => BackgroundStyleNotifier(savedBackgroundStyle)),
      glassStyleProvider.overrideWith(() => GlassStyleNotifier(savedGlassStyle)),
      internetProvider.overrideWith(() => InternetNotifier(false)),
      gamesSignInProvider.overrideWith(() => GamesSignInNotifier(false)),
      pointProvider.overrideWith(() => PointNotifier(0)),
      planProvider.overrideWith(() => PlanNotifier(PlanState(isPremium: initialPremium))),
    ],
    child: const MyApp()
  ));
  /// --- Post-Launch Services ---
  // Initialize additional services after app launch (Firebase App Check, ads, tracking)
  await FirebaseAppCheck.instance.activate(
    providerAndroid: providerAndroid,
    providerApple: providerApple,
  );
  // Same call and same place as before. It goes through the shared future in
  // admob_banner.dart because the banner may reach the ad request before this
  // line runs, and the platform SDK must only be started once
  await initializeMobileAds();
}

/// --- Main Application Widget ---
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
    /// --- Localization ---
    // Multi-language support configuration
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    /// --- App Configuration ---
    // Basic app settings and theme
    title: appTitle,
    theme: ThemeData(primarySwatch: Colors.grey),
    debugShowCheckedModeBanner: false,
    /// --- Routing ---
    // Navigation routes to different app screens
    initialRoute: "/h",
    routes: {
      "/h": (context) => const HomePage(),    // Elevator simulator
      "/m": (context) => const MenuPage(),    // Menu
      "/s": (context) => const SettingsPage(), // Settings
    },
    /// --- Navigation Observers ---
    // Track navigation for analytics and debugging
    navigatorObservers: <NavigatorObserver>[
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      RouteObserver<ModalRoute>()
    ],
  );
}
/// --- Privacy and Tracking ---
// This app has no ATT code of its own. The AdMob UMP flow in admob_banner.dart
// shows the IDFA explainer and the system ATT dialog, so consent and tracking
// are configured in the AdMob console, not here.

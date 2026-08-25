// =============================
// MenuPage: Main menu interface for elevator simulator
//
// This file contains the menu system that provides access to settings,
// rewarded ads, leaderboards, and external links. It manages ad loading,
// user interactions, and navigation to other app sections.
// Key features:
// - Settings page navigation
// - Rewarded ad integration with retry logic
// - Game Center leaderboard access
// - External link navigation
// - AdMob banner integration
// - Internet connectivity checks
// - User feedback and notifications
// =============================

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'analytics_manager.dart';
import 'games_manager.dart';
import 'common_widget.dart';
import 'extension.dart';
import 'constant.dart';
import 'main.dart';
import 'plan_provider.dart';
import 'settings.dart';

class MenuPage extends HookConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // --- Provider State Management ---
    // Riverpod providers for managing app state
    final isConnectedInternet = ref.watch(internetProvider);
    final isGamesSignIn = ref.watch(gamesSignInProvider);
    final isPremium = ref.watch(planProvider).isPremium;

    // --- Hooks State Management ---
    // Local state management using Flutter Hooks
    final rewardedAd = useState<RewardedAd?>(null);           // Rewarded ad instance
    final retryAttempt = useState(0);                         // Ad loading retry counter
    final isLoadingAd = useState(false);                      // Guards against duplicate in-flight loads
    final cancelToken = useMemoized(() => Completer<void>(), []); // Cancellation token for cleanup
    final isLoadingData = useState(false);                    // Data loading state

    // --- Widget and Manager Instances ---
    // UI widget instances and service managers
    final common = CommonWidget(context);
    final menu = MenuWidget(context,
      isConnectedInternet: isConnectedInternet,
      isGamesSignIn: isGamesSignIn,
    );
    final gamesManager = useMemoized(() => GamesManager(
      isGamesSignIn: isGamesSignIn,
      isConnectedInternet: isConnectedInternet,
    ));

    // --- Ad Management Functions ---
    // Functions for handling rewarded ad loading and display

    /// Load rewarded ad with retry logic and error handling
    /// Retries on a linear backoff, capped, since the user is waiting on it
    void loadRewardedAd() async {
      // A second load while one is in flight only burns an ad request
      if (cancelToken.isCompleted || isLoadingAd.value || rewardedAd.value != null) return;
      isLoadingAd.value = true;
      // No ATT gate here: the menu opens long after launch, so the status is
      // already settled, and holding the request would only leave the reward
      // button dead while the user is standing in front of it
      RewardedAd.load(
        adUnitId: dotenv.get(rewardAdUnitID),
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) async {
            // The menu is gone: release the ad instead of leaking a filled one
            if (cancelToken.isCompleted) {
              ad.dispose();
              return;
            }
            'ad loaded'.debugPrint();
            ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) =>
              AnalyticsManager.adRevenue(
                format: "rewarded",
                adUnitId: dotenv.get(rewardAdUnitID),
                valueMicros: valueMicros,
                precision: precision,
                currencyCode: currencyCode,
              );
            isLoadingAd.value = false;
            rewardedAd.value = ad;
            retryAttempt.value = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            'Ad failed to load: $error'.debugPrint();
            if (cancelToken.isCompleted) return;
            isLoadingAd.value = false;
            // Back off from 2s upward; the counter must grow before the delay
            // is computed, otherwise the first retry fires instantly
            retryAttempt.value += 1;
            // Retrying forever would only pile up requests that never become
            // impressions. The button press reloads on demand anyway
            if (retryAttempt.value > rewardedMaxRetry) return;
            Future.delayed(Duration(seconds: 2 * retryAttempt.value), () {
              if (!cancelToken.isCompleted) loadRewardedAd();
            });
          },
        ),
      );
    }

    // --- Ad Loading Effect ---
    // Automatic ad loading and cleanup management
    // The cancel token means "the menu is gone", so this effect must only run
    // on mount and unmount. Keying it on retryAttempt completed the token on
    // the first retry, after which every filled ad was silently discarded.
    useEffect(() {
      loadRewardedAd();
      return () {
        if (!cancelToken.isCompleted) {
          cancelToken.complete();
        }
        rewardedAd.value?.dispose();
      };
    }, []);

    // --- Initialization Functions ---
    // Functions for setting up initial app state

    /// Initialize app state including ad loading and connectivity checks
    /// Sets up initial data and manages loading states
    initState() async {
      isLoadingData.value = true;
      try {
        loadRewardedAd();
        final hasInternet = await gamesManager.checkInternetConnection();
        ref.read(internetProvider.notifier).setValue(hasInternet);
        final signedIn = await GamesManager(
          isGamesSignIn: ref.read(gamesSignInProvider),
          isConnectedInternet: hasInternet,
        ).gamesSignIn();
        ref.read(gamesSignInProvider.notifier).setValue(signedIn);
        isLoadingData.value = false;
      } catch (e) {
        "Error: $e".debugPrint();
        isLoadingData.value = false;
      }
    }

    // --- Initialization Effect ---
    // Automatic initialization when widget is created
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await initState();
      });
      return null;
    }, []);

    // --- User Interaction Functions ---
    // Functions for handling user menu selections and actions

    /// Display rewarded ad and handle reward distribution
    /// Shows ad to user and awards points upon completion
    showRewardedAd() {
      final ad = rewardedAd.value;
      if (ad == null) return;
      // A rewarded instance is single use: drop the reference before showing so
      // the consumed ad cannot block the next preload
      rewardedAd.value = null;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          ad.dispose();
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          '$ad failed to show: $error'.debugPrint();
          ad.dispose();
          loadRewardedAd();
        },
      );
      ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
          "showRewardedAd".debugPrint();
          final prefs = await SharedPreferences.getInstance();
          'rewardEarned: ${reward.type}, rewardAmount: ${reward.amount}'.debugPrint();
          final addPoint = (earnMilesInt > reward.amount.toInt()) ? earnMilesInt: reward.amount.toInt();
          ref.read(pointProvider.notifier).add(addPoint);
          final newPoint = ref.read(pointProvider);
          "pointKey".setSharedPrefInt(prefs, newPoint);
          await gamesManager.gamesSubmitScore(newPoint);
          await AnalyticsManager.rewardAdEarned(addPoint);
        }
      );
    }

    /// Handle menu button presses with navigation and validation
    /// Routes user to appropriate sections based on button index and app state
    pressedMenuLink(int i) async {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      if (i == 0) {
        // Settings page navigation
        if (context.mounted) context.pushFadeReplacement(SettingsPage());
      } else if (!isConnectedInternet) {
        // Internet connectivity check
        menu.showSnackBar(context.notConnectedInternet());
      } else if (i == 1) {
        // Rewarded ad handling
        if (rewardedAd.value == null) {
          loadRewardedAd();
        } else {
          await AnalyticsManager.rewardAdOffered();
          menu.rewardedAdPermissionAlert(onTap: () {
            context.popPage();
            showRewardedAd();
          });
        }
      } else if (!isGamesSignIn) {
        // Game Center sign-in check
        menu.showSnackBar(context.notSignedInGameCenter());
      } else {
        // Leaderboard display
        await gamesManager.gamesShowLeaderboard();
      }
    }

    // --- UI Rendering ---
    // Main menu interface structure
    return Scaffold(
      body: SafeArea(
        child: Stack(alignment: Alignment.topCenter,
          children: [
            /// Background image for menu
            common.commonBackground(menuBackGroundImage),
            /// Main menu content layout
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Spacer(flex: 1),
                /// Menu button grid (Settings, Rewarded Ad, Leaderboard)
                ...List.generate(3, (i) =>
                  GestureDetector(
                    onTap: () async => await pressedMenuLink(i),
                    child: menu.menuButton(i),
                  ),
                ),
                Spacer(flex: 1),
                /// Bottom navigation with external links
                menu.bottomMenuLink(),
                /// AdMob banner space reservation (the banner itself is drawn by HomePage)
                if (!isPremium) Container(
                  height: context.admobHeight(),
                  color: blackColor,
                )
              ]
            ),
            /// Loading indicator during data initialization
            if (isLoadingData.value) common.commonCircularProgressIndicator(),
          ]
        ),
      ),
    );
  }
}

// =============================
// MenuWidget: UI components for menu interface
//
// This class provides all the UI components needed for the menu system,
// including buttons, navigation, alerts, and user feedback elements.
// =============================

class MenuWidget {

  final BuildContext context;
  final bool isConnectedInternet;
  final bool isGamesSignIn;

  MenuWidget(this.context, {
    required this.isConnectedInternet,
    required this.isGamesSignIn,
  });

  // --- Menu Button Components ---
  // UI components for main menu buttons

  /// Create menu button with appropriate image based on index
  /// Returns styled container with button image for settings, ads, or leaderboard
  Widget menuButton(int i) => Container(
    width: context.menuButtonSize(),
    height: context.menuButtonSize(),
    margin: EdgeInsets.symmetric(vertical: context.menuButtonMargin()),
    child: Image.asset(
      (i == 0) ? settingsButton:
      (i == 1) ? adRewardButton:
      (i == 2) ? rankingButton:
      squareButton
    ),
  );

  // --- Navigation Components ---
  // UI components for external link navigation

  /// Create bottom navigation bar with external links
  /// Provides navigation to external websites with connectivity validation
  Widget bottomMenuLink() => Container(
    color: blackColor,
    padding: EdgeInsets.symmetric(vertical: context.menuLinksMargin()),
    child: BottomNavigationBar(
      items: List.generate(context.linkLogos().length, (i) =>
        BottomNavigationBarItem(
          icon: Container(
            margin: EdgeInsets.symmetric(vertical: context.menuLinksMargin()),
            width: context.menuLinksLogoSize(),
            child: Image.asset(context.linkLogos()[i]),
          ),
          label: context.linkTitles()[i],
        ),
      ),
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      onTap: (i) =>{
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp),
        (isConnectedInternet) ? launchUrl(Uri.parse(context.linkLinks()[i])):
          showSnackBar(context.notConnectedInternet()),
      },
      elevation: 0,
      selectedItemColor: lampColor,
      unselectedItemColor: lampColor,
      selectedFontSize: context.menuLinksTitleSize(),
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      unselectedFontSize: context.menuLinksTitleSize(),
      backgroundColor: blackColor,
    ),
  );

  // --- Alert and Feedback Components ---
  // UI components for user notifications and confirmations

  /// Display permission alert for rewarded ad viewing
  /// Shows confirmation dialog before displaying ad
  void rewardedAdPermissionAlert({
    required void Function() onTap
  }) => showDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(context.earnMilesAfterAdTitle(earnMiles),
        style: TextStyle(
          color: blackColor,
          fontSize: context.menuAlertTitleFontSize(),
          fontFamily: context.font(),
        ),
      ),
      content: Text(context.earnMilesAfterAdDesc(earnMiles),
        style: TextStyle(
          color: blackColor,
          fontSize: context.menuAlertDescFontSize(),
          fontFamily: context.font(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.popPage(),
          child: Text(context.cancel(),
            style: TextStyle(
              color: blackColor,
              fontSize: context.menuAlertSelectFontSize(),
              fontFamily: context.font(),
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(context.ok(),
            style: TextStyle(
              color: blackColor,
              fontSize: context.menuAlertSelectFontSize(),
              fontFamily: context.font(),
            ),
          ),
        ),
      ],
    ),
  );

  /// Display snackbar notification with custom styling
  /// Shows user feedback messages with proper text sizing and positioning
  void showSnackBar(String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: blackColor,
          fontSize: context.snackBarFontSize(),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final snackBar = SnackBar(
      content: Text(text,
        style: TextStyle(
          color: blackColor,
          fontWeight: FontWeight.bold,
          fontSize: context.snackBarFontSize(),
        ),
        textAlign: TextAlign.center,
      ),
      backgroundColor: lampColor,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.snackBarBorderRadius()),
      ),
      padding: EdgeInsets.all(context.snackBarPadding()),
      margin: EdgeInsets.symmetric(
        horizontal: context.snackBarSideMargin(textPainter),
        vertical: context.snackBarBottomMargin(),
      ),
    );
    "showSnackBar: $text".debugPrint();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
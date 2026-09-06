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
    // Refs, not state: the consent forms resolve after this screen can be gone,
    // and writing to a disposed ValueNotifier asserts in debug
    final consentUpdated = useRef(false);                     // One consent update per screen
    final pendingLoad = useRef<Completer<RewardedAd?>?>(null); // Lets a press await the load

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

    /// Hand the outcome of a load back to whoever pressed the button and is
    /// waiting on it. A preload that nobody is waiting for finds no completer
    void finishPendingLoad(RewardedAd? ad) {
      final pending = pendingLoad.value;
      pendingLoad.value = null;
      if (pending != null && !pending.isCompleted) pending.complete(ad);
    }

    /// Join a load that is already running, creating the completer when the
    /// load started without one. The retry inside loadRewardedAd calls itself
    /// directly, so a press during the backoff would otherwise be handed a
    /// null and told there is no ad while a request is in flight
    Future<RewardedAd?>? joinLoadInFlight() {
      if (!isLoadingAd.value) return null;
      return (pendingLoad.value ??= Completer<RewardedAd?>()).future;
    }

    /// Load rewarded ad with retry logic and error handling
    /// Retries on a linear backoff, capped, since the user is waiting on it
    /// Only requestAdIfAllowed below may call this: it is past the consent gate
    void loadRewardedAd() async {
      // A second load while one is in flight only burns an ad request
      if (cancelToken.isCompleted || isLoadingAd.value || rewardedAd.value != null) return;
      isLoadingAd.value = true;
      // No ATT gate here: the menu opens long after launch, so the status is
      // already settled, and holding the request would only leave the reward
      // button dead while the user is standing in front of it
      RewardedAd.load(
        adUnitId: rewardAdUnitID,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) async {
            // The menu is gone: release the ad instead of leaking a filled one
            if (cancelToken.isCompleted) {
              ad.dispose();
              finishPendingLoad(null);
              return;
            }
            'ad loaded'.debugPrint();
            ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) =>
              AnalyticsManager.adRevenue(
                format: "rewarded",
                adUnitId: rewardAdUnitID,
                valueMicros: valueMicros,
                precision: precision,
                currencyCode: currencyCode,
              );
            isLoadingAd.value = false;
            rewardedAd.value = ad;
            retryAttempt.value = 0;
            finishPendingLoad(ad);
          },
          onAdFailedToLoad: (LoadAdError error) {
            'Ad failed to load: $error'.debugPrint();
            if (cancelToken.isCompleted) {
              finishPendingLoad(null);
              return;
            }
            isLoadingAd.value = false;
            // Answer a waiting press now rather than holding it behind the
            // backoff. The retry below keeps running for the next press
            finishPendingLoad(null);
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

    // --- Consent Gate ---
    // The single gate for every rewarded request on this screen, including the
    // preload that runs while an ad is on screen. canRequestAds is the SDK's
    // own verdict: it already weighs the region, the TCF consent string and
    // Additional Consent, so the app must not read ConsentStatus and decide for
    // itself. A false answer also covers "the SDK could not tell", and letting
    // that through is exactly what serving without consent looks like in the
    // EEA. This is not the ATT question: ATT can be left pending, consent cannot
    Future<RewardedAd?> requestAdIfAllowed() async {
      final ready = rewardedAd.value;
      if (ready != null) return ready;
      if (cancelToken.isCompleted) return null;
      // A load is already in flight: wait on it rather than start a second one
      final joined = joinLoadInFlight();
      if (joined != null) return joined;
      if (!await ConsentInformation.instance.canRequestAds()) return null;
      // Callers race across that await. The checks below run again because the
      // state can have moved while this one was suspended
      if (cancelToken.isCompleted) return null;
      if (rewardedAd.value != null) return rewardedAd.value;
      final rejoined = joinLoadInFlight();
      if (rejoined != null) return rejoined;
      final completer = Completer<RewardedAd?>();
      pendingLoad.value = completer;
      loadRewardedAd();
      // loadRewardedAd returns without a callback when its own guards stop it,
      // and then nothing would ever complete the completer
      if (!isLoadingAd.value) finishPendingLoad(null);
      return completer.future;
    }

    /// Run the consent info update and let the SDK present a form if it wants
    /// one. This is the only path by which an undecided user reaches the form
    Future<void> updateConsent() {
      final completer = Completer<void>();
      void done() {
        if (!completer.isCompleted) completer.complete();
      }
      ConsentInformation.instance.requestConsentInfoUpdate(ConsentRequestParameters(
        // consentDebugSettings: ConsentDebugSettings(
        //   debugGeography: DebugGeography.debugGeographyEea,
        //   testIdentifiers: ['2793ca2a-5956-45a2-96c0-16fafddc1a15'],
        // ),
      ), () async {
        // The SDK decides whether a form is required, loads it and presents it.
        // It does nothing when no form is needed
        await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
          if (formError != null) {
            "formError: ${formError.errorCode}: ${formError.message}".debugPrint();
          }
          done();
        });
      }, (FormError error) {
        // The update failed, but consent given in an earlier session still
        // stands and canRequestAds can still say yes, so the request is worth
        // trying anyway
        "error: ${error.errorCode}: ${error.message}".debugPrint();
        done();
      });
      return completer.future.timeout(
        const Duration(seconds: consentFormTimeoutSec),
        onTimeout: done,
      );
    }

    /// The press path: what happens when the user asks for the reward and
    /// nothing is loaded. It must never end in silence
    Future<RewardedAd?> prepareRewardedAd() async {
      final ready = rewardedAd.value;
      if (ready != null) return ready;
      if (!consentUpdated.value) {
        consentUpdated.value = true;
        await updateConsent();
        if (cancelToken.isCompleted) return null;
      }
      final requested = await requestAdIfAllowed();
      if (requested != null) return requested;
      if (cancelToken.isCompleted) return null;
      // Still not allowed. canRequestAds turns false only while the consent
      // flow has not completed, not because the user said no: declining still
      // permits non personalised ads. Landing here means the flow was cut
      // short, so the privacy options form is offered as a second chance to
      // finish it. The message below catches whatever that does not fix
      if (!await ConsentInformation.instance.canRequestAds()) {
        final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
        if (status != PrivacyOptionsRequirementStatus.required) return null;
        await ConsentForm.showPrivacyOptionsForm((formError) {
          if (formError != null) {
            "privacyFormError: ${formError.errorCode}: ${formError.message}".debugPrint();
          }
        });
        if (cancelToken.isCompleted) return null;
        return await requestAdIfAllowed();
      }
      // Consent is fine and the request came back empty
      return null;
    }

    // --- Ad Loading Effect ---
    // Automatic ad loading and cleanup management
    // The cancel token means "the menu is gone", so this effect must only run
    // on mount and unmount. Keying it on retryAttempt completed the token on
    // the first retry, after which every filled ad was silently discarded.
    useEffect(() {
      // Preload only when the SDK already says yes from an earlier session. A
      // user who has not consented gets nothing requested here; the button
      // press runs the consent form for them instead
      requestAdIfAllowed();
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
        requestAdIfAllowed();
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
          requestAdIfAllowed();
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          '$ad failed to show: $error'.debugPrint();
          ad.dispose();
          requestAdIfAllowed();
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
      // Preload the next ad while this one is on screen. A reviewer dropped a
      // star over the wait: loading only on dismiss left the button dead for
      // the seconds it takes to fill. The loaded and the showing ad are
      // separate instances with separate ad ids, so they do not interfere.
      // It goes through the gate like every other request: a preload that
      // skipped the consent check would be the same violation as any other
      requestAdIfAllowed();
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
        //
        // The press has to answer every time. Gating the request on consent
        // means a user who has not answered the consent form has no ad and,
        // without this, no way to get one: the button would stay dead forever.
        // So the press runs the consent flow itself, offers the privacy options
        // form to anyone who declined earlier, and only when there is nothing
        // left to ask does it say so
        if (rewardedAd.value == null) {
          // The consent form and the ad request both take a round trip, and the
          // button looks dead while they run
          isLoadingData.value = true;
          final prepared = await prepareRewardedAd();
          // The menu can be gone by now, and the token is what says so
          if (cancelToken.isCompleted) return;
          isLoadingData.value = false;
          if (prepared == null) {
            // Either consent was declined and left declined, or nothing filled.
            // Both are things the user can act on, so say it
            if (context.mounted) menu.showSnackBar(context.rewardAdUnavailable());
            return;
          }
        }
        await AnalyticsManager.rewardAdOffered();
        if (!context.mounted) return;
        menu.rewardedAdPermissionAlert(onTap: () {
          context.popPage();
          showRewardedAd();
        });
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
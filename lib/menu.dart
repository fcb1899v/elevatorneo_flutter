// ===== MenuPage: main menu =====
// Settings, rewarded ad with retry, leaderboard, external links, banner, connectivity.

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'admob_banner.dart';
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
import 'premium_page.dart';
import 'purchase_manager.dart';
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
    // The price the store returned, empty until it answers. The purchase button
    // is drawn from this, never from "the SDK started", which may have nothing to sell
    final storePrice = useState("");
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

    /// Join a load already running, creating the completer if the load has none.
    /// Otherwise a press during the retry backoff is told there is no ad
    Future<RewardedAd?>? joinLoadInFlight() {
      if (!isLoadingAd.value) return null;
      return (pendingLoad.value ??= Completer<RewardedAd?>()).future;
    }

    /// Load rewarded ad with capped linear backoff, since the user is waiting on it.
    /// Only requestAdIfAllowed below may call this: it is past the consent gate
    void loadRewardedAd() async {
      // A second load while one is in flight only burns an ad request
      if (cancelToken.isCompleted || isLoadingAd.value || rewardedAd.value != null) return;
      isLoadingAd.value = true;
      // No ATT gate here: the menu opens long after launch, so the status is
      // settled, and holding the request would only leave the reward button dead
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

    // --- Consent Gate --- the single gate for every rewarded request, preload too.
    // canRequestAds is the SDK's own verdict; false also covers "could not tell"
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
      // main.dart no longer starts the platform SDK at launch, so make sure it is
      // up before the first rewarded request; the shared future makes this a no-op
      if (await initializeMobileAds() == null) {
        // The press is waiting on this completer. Returning without finishing
        // it leaves the button spinning with no ad and no message
        finishPendingLoad(null);
        return null;
      }
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
        // The update failed, but earlier consent still stands and canRequestAds
        // can still say yes, so the request is worth trying anyway
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
      // Still not allowed: canRequestAds is false only while the consent flow is
      // incomplete (declining still permits NPA), so offer the privacy options form
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

    // --- Ad Loading Effect --- must run only on mount and unmount: the cancel token
    // means "the menu is gone", and keying on retryAttempt discarded every filled ad
    useEffect(() {
      // Preload only when the SDK already says yes from an earlier session;
      // otherwise the button press runs the consent form instead
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
        // Preload the price so the button can show an amount. The button itself
        // exists either way; this only decides whether it carries a number
        if (ref.read(planProvider).isPremium) return;
        final price = await PurchaseManager.fetchPrice();
        if (!context.mounted) return;
        if (price != null) {
          storePrice.value = price;
          ref.read(planProvider.notifier).setPrice(price);
        }
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
      // Preload the next ad while this one is on screen, or the button stays dead
      // while it fills. Separate instances, and it still goes through the consent gate
      requestAdIfAllowed();
    }

    /// Handle menu button presses, routing by button index and app state
    // --- Premium Purchase ---

    /// Run the purchase or restore flow and report the result to the user
    Future<void> runPurchase({required bool isRestore}) async {
      isLoadingData.value = true;
      try {
        final purchased = await PurchaseManager.buyPremium(
          isRestore: isRestore,
          source: "menu",
        );
        if (!context.mounted) return;
        if (purchased) {
          await ref.read(planProvider.notifier).setCurrentPlan(true);
          if (!context.mounted) return;
          common.commonSnackBar(context.premiumThanks());
        } else if (isRestore) {
          common.commonSnackBar(context.premiumRestoreFailed());
        }
      } catch (e) {
        "Purchase error: $e".debugPrint();
        // Nothing to sell is not a failed purchase. The reviewer sees this one
        // while the product is still attached to the submission
        if (context.mounted) {
          common.commonSnackBar((e is StoreUnavailableException)
            ? context.premiumUnavailable()
            : context.premiumFailed());
        }
      } finally {
        isLoadingData.value = false;
      }
    }

    /// Open the upgrade dialog from the fourth menu button. The price is fetched
    /// again, since an offering or the network can drop meanwhile; empty is said aloud
    Future<void> openUpgrade() async {
      isLoadingData.value = true;
      final price = await PurchaseManager.fetchPrice();
      if (!context.mounted) return;
      isLoadingData.value = false;
      // An empty price still opens the page: the button says "Buy" without an
      // amount, and pressing it reports why nothing happened
      storePrice.value = price ?? "";
      ref.read(planProvider.notifier).setPrice(price ?? "");
      await AnalyticsManager.upgradeOffered("menu");
      if (!context.mounted) return;
      context.pushPage(PremiumPage(
        price: price ?? "",
        onBuy: () async {
          context.popPage();
          await runPurchase(isRestore: false);
        },
        onRestore: () async {
          context.popPage();
          await runPurchase(isRestore: true);
        },
      ));
    }

    pressedMenuLink(int i) async {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      if (i == 0) {
        // Settings page navigation
        if (context.mounted) context.pushFadeReplacement(SettingsPage());
      } else if (i == 3) {
        // Premium purchase. Placed before the connectivity check on purpose: the
        // purchase page says why nothing happened, which a blocked tap cannot
        await openUpgrade();
      } else if (!isConnectedInternet) {
        // Internet connectivity check
        menu.showSnackBar(context.notConnectedInternet());
      } else if (i == 1) {
        // Rewarded ad handling. The press must answer every time: it runs the consent
        // flow itself, offers the privacy options form, and only then says there is no ad
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
      // bottom: false so the ad reservation below reaches the true bottom; the
      // banner is drawn by HomePage outside its SafeArea
      body: SafeArea(
        bottom: false,
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
                /// Menu button grid, two per row. The fourth (purchase) is dropped
                /// once premium is owned; with three, one is centred. It is shown
                /// with or without a price, so App Review always has a way in
                ...menu.menuButtonRows(
                  onTap: pressedMenuLink,
                  price: isPremium ? null: storePrice.value,
                ),
                Spacer(flex: 1),
                /// Bottom navigation with external links
                // Premium drops the banner below, so the row takes the system inset
                menu.bottomMenuLink(
                  bottomInset: isPremium ? MediaQuery.viewPaddingOf(context).bottom : 0,
                ),
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

// ===== MenuWidget: buttons, navigation, alerts and feedback for the menu =====

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

  /// Lay the buttons out two per row. price is null once premium is owned; the
  /// grid then holds three, one centred on the second row
  List<Widget> menuButtonRows({
    required Future<void> Function(int) onTap,
    String? price,
  }) {
    final count = (price != null) ? 4: 3;
    final buttons = List.generate(count, (i) => GestureDetector(
      onTap: () async => await onTap(i),
      child: menuButton(i),
    ));
    return [
      for (int row = 0; row < count; row += 2)
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: buttons.sublist(row, (row + 2 > count) ? count: row + 2),
        ),
    ];
  }

  /// Create menu button by index. Each is one 512x512 PNG with the border colour
  /// baked in (green, silver, yellow, white); the Semantics label is all a reader has
  Widget menuButton(int i) => Semantics(
    button: true,
    label: (i == 0) ? context.settings():
      (i == 1) ? context.earnMilesAfterAdTitle(earnMiles):
      (i == 2) ? context.ranking():
      context.premiumTitle().trim(),
    child: Container(
      width: context.menuButtonSize(),
      height: context.menuButtonSize(),
      margin: EdgeInsets.symmetric(
        vertical: context.menuButtonMargin(),
        horizontal: context.menuButtonMargin(),
      ),
      // The purchase button carries its own PREMIUM caption, baked into the PNG
      // like adReward's +1000, so no text is drawn over the image here
      child: Image.asset(
        (i == 0) ? settingsButton:
        (i == 1) ? adRewardButton:
        (i == 2) ? rankingButton:
        purchaseButton
      ),
    ),
  );

  // --- Navigation Components ---
  // UI components for external link navigation

  /// External links. A plain Row, not a BottomNavigationBar: the bar added its
  /// own padding under the labels, which left a gap above the ad banner.
  ///
  /// bottomInset is the system inset to take over when nothing is reserved below
  /// this row, which is the case once premium removes the banner
  Widget bottomMenuLink({required double bottomInset}) => Container(
    color: blackColor,
    // The top keeps what the bar gave it: menuLinksMargin twice, plus the half
    // font size the bar added itself. The underside matches it; what the bar
    // added beyond that is gone, which is the gap this replacement was for
    padding: EdgeInsets.only(
      top: context.menuLinksMargin() * 2 + context.menuLinksTitleSize() / 2,
      bottom: context.menuLinksMargin() * 2 + context.menuLinksTitleSize() / 2
        + bottomInset,
    ),
    // The bar clamped text scaling and ellipsized; without both, a large system
    // font setting overflows the row
    child: MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.0,
      child: Row(
        // Expanded, as the bar's tiles were: the whole share is tappable
        children: List.generate(context.linkLogos().length, (i) => Expanded(
          child: Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
                (isConnectedInternet)
                  ? launchUrl(Uri.parse(context.linkLinks()[i]))
                  : showSnackBar(context.notConnectedInternet());
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: context.menuLinksLogoSize(),
                    child: Image.asset(context.linkLogos()[i]),
                  ),
                  SizedBox(height: context.menuLinksMargin()),
                  Text(
                    context.linkTitles()[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: lampColor,
                      fontSize: context.menuLinksTitleSize(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )),
      ),
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
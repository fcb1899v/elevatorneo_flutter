// ===== AnalyticsManager: Firebase Analytics event logging =====
// Gameplay and monetization events for the revenue funnel.

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'extension.dart';

class AnalyticsManager {

  /// The real sender, replaced in tests with a recorder, since widget tests never start Firebase
  @visibleForTesting
  static Future<void> Function(String name, Map<String, Object>? parameters) send =
      (name, parameters) => FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);

  // --- Internal Helper ---

  /// Log an event and swallow any failure so analytics never breaks the app
  static Future<void> _log(String name, [Map<String, Object>? params]) async {
    try {
      await send(name, params);
      "Analytics: $name ${params ?? ""}".debugPrint();
    } catch (e) {
      "Analytics error: $name: $e".debugPrint();
    }
  }

  // --- Gameplay Events ---

  /// Log a completed ride with the travelled distance in floors
  static Future<void> rideComplete({
    required int fromFloor,
    required int toFloor,
    required int totalMiles,
  }) => _log("ride_complete", {
    "from_floor": fromFloor,
    "to_floor": toFloor,
    "distance": (toFloor - fromFloor).abs(),
    "total_miles": totalMiles,
  });

  // --- Unlock Funnel Events ---

  /// Log that a user faced a locked feature: the core demand signal
  /// `feature` identifies which lock was hit, so pricing can be tuned per feature
  static Future<void> unlockBlocked({
    required String feature,
    required int requiredPoint,
    required int currentPoint,
  }) => _log("unlock_blocked", {
    "feature": feature,
    "required_point": requiredPoint,
    "current_point": currentPoint,
    "shortage": (requiredPoint - currentPoint).clamp(0, requiredPoint),
  });

  /// Log that a locked feature became available to the user
  static Future<void> unlockAchieved({
    required String feature,
    required int requiredPoint,
  }) => _log("unlock_achieved", {
    "feature": feature,
    "required_point": requiredPoint,
  });

  // --- Ad Events ---

  /// Log that the reward ad dialog was presented to the user
  static Future<void> rewardAdOffered() => _log("reward_ad_offered");

  /// Log that the user finished a reward ad and earned miles
  static Future<void> rewardAdEarned(int amount) =>
      _log("reward_ad_earned", {"amount": amount});

  /// Log that an interstitial was actually shown
  static Future<void> interstitialShown(String placement) =>
      _log("interstitial_shown", {"placement": placement});

  // --- Purchase Events ---

  /// Log that the upgrade dialog was shown, with the trigger that opened it
  static Future<void> upgradeOffered(String source) =>
      _log("upgrade_offered", {"source": source});

  /// Log that the user started the purchase flow
  static Future<void> upgradeStarted(String source) =>
      _log("upgrade_started", {"source": source});

  /// Log a completed purchase
  static Future<void> upgradePurchased(String source) =>
      _log("upgrade_purchased", {"source": source});

  /// Log that the user closed the store sheet without buying
  static Future<void> upgradeCancelled(String source) =>
      _log("upgrade_cancelled", {"source": source});

  /// Log a purchase or restore that threw, with a short fixed reason
  static Future<void> upgradeFailed({
    required String source,
    required String flow,
    required String reason,
  }) => _log("upgrade_failed", {"source": source, "flow": flow, "reason": reason});

  /// Log a restore attempt and whether it granted the entitlement
  static Future<void> upgradeRestored(bool isPremium) =>
      _log("upgrade_restored", {"is_premium": isPremium ? 1 : 0});

  // --- Coupon Events ---

  /// Log that the user opened the coupon code entry
  static Future<void> couponEntryOpened() => _log("coupon_entry_opened");

  /// Log the result of a coupon code check: valid, invalid, or unavailable
  static Future<void> couponCodeChecked(String result) =>
      _log("coupon_code_checked", {"result": result});

  // --- Review Events ---

  /// Log that the in-app store review prompt was requested
  static Future<void> reviewRequested() => _log("review_requested");

  // --- Cross-Promo Events ---

  /// Log that the cross-promo was shown in the menu, once per open
  /// Bucketed values are sent as strings, and booleans as 0 or 1
  static Future<void> crossPromoShown({
    required String placement,
    required bool isPremium,
    required String lang,
    required String launchCount,
    required String rideCount,
    required String daysSinceFirstLaunch,
    required String shownCount,
    required String firstPattern,
    required String videoMode,
    required String bodyForm,
  }) => _log("cross_promo_shown", _promoShownParams(
    placement: placement,
    isPremium: isPremium,
    lang: lang,
    launchCount: launchCount,
    rideCount: rideCount,
    daysSinceFirstLaunch: daysSinceFirstLaunch,
    shownCount: shownCount,
    firstPattern: firstPattern,
    videoMode: videoMode,
    bodyForm: bodyForm,
  ));

  /// Log that a video pattern finished, or stopped when the menu closed
  static Future<void> crossPromoVideoPlayed({
    required String pattern,
    required bool completed,
    required bool isPremium,
  }) => _log("cross_promo_video_played", {
    "target": "adventure",
    "pattern": pattern,
    "completed": completed ? 1 : 0,
    "is_premium": isPremium ? 1 : 0,
  });

  /// Log that the cross-promo was tapped and the store opening has started
  /// The open result is sent as "none" by the caller when nothing opened
  static Future<void> crossPromoTapped({
    required String placement,
    required bool isPremium,
    required String lang,
    required String launchCount,
    required String rideCount,
    required String daysSinceFirstLaunch,
    required String shownCount,
    required String firstPattern,
    required String videoMode,
    required String bodyForm,
    required String videoPattern,
    required String videoPosition,
    required String patternsSeen,
    required String targetArea,
    required String visible,
    required String openMethod,
    required bool opened,
  }) => _log("cross_promo_tapped", {
    ..._promoShownParams(
      placement: placement,
      isPremium: isPremium,
      lang: lang,
      launchCount: launchCount,
      rideCount: rideCount,
      daysSinceFirstLaunch: daysSinceFirstLaunch,
      shownCount: shownCount,
      firstPattern: firstPattern,
      videoMode: videoMode,
      bodyForm: bodyForm,
    ),
    "video_pattern": videoPattern,
    "video_position": videoPosition,
    "patterns_seen": patternsSeen,
    "target_area": targetArea,
    "visible": visible,
    "open_method": openMethod,
    "opened": opened ? 1 : 0,
  });

  /// Log that the cross-promo left the screen when the menu closed
  static Future<void> crossPromoViewEnded({
    required String placement,
    required String visible,
    required bool tapped,
    required String patternsSeen,
    required bool isPremium,
    bool dismissed = false,
  }) => _log("cross_promo_view_ended", {
    "target": "adventure",
    "placement": placement,
    "visible": visible,
    "tapped": tapped ? 1 : 0,
    "patterns_seen": patternsSeen,
    "is_premium": isPremium ? 1 : 0,
    "dismissed": dismissed ? 1 : 0,
  });

  /// Log that the card's close button removed the card, with the video and visibility at that time
  static Future<void> crossPromoDismissed({
    required String placement,
    required bool isPremium,
    required String lang,
    required String launchCount,
    required String rideCount,
    required String daysSinceFirstLaunch,
    required String shownCount,
    required String firstPattern,
    required String videoMode,
    required String bodyForm,
    required String dismissCount,
    required String videoPattern,
    required String videoPosition,
    required String patternsSeen,
    required String visible,
  }) => _log("cross_promo_dismissed", {
    ..._promoShownParams(
      placement: placement,
      isPremium: isPremium,
      lang: lang,
      launchCount: launchCount,
      rideCount: rideCount,
      daysSinceFirstLaunch: daysSinceFirstLaunch,
      shownCount: shownCount,
      firstPattern: firstPattern,
      videoMode: videoMode,
      bodyForm: bodyForm,
    ),
    "method": "close_x",
    "dismiss_count": dismissCount,
    "video_pattern": videoPattern,
    "video_position": videoPosition,
    "patterns_seen": patternsSeen,
    "visible": visible,
  });

  /// Log that the user came back from the store after the cross-promo tap
  static Future<void> crossPromoStoreReturned({
    required String placement,
    required String videoPattern,
    required String openMethod,
    required String away,
  }) => _log("cross_promo_store_returned", {
    "target": "adventure",
    "placement": placement,
    "video_pattern": videoPattern,
    "open_method": openMethod,
    "away": away,
  });

  /// Log the first time the target app is found installed on this device
  static Future<void> crossPromoTargetFound({
    required bool tappedBefore,
    required String lastPlacement,
    required String lastPattern,
    required String sinceTap,
    required bool isPremium,
  }) => _log("cross_promo_target_found", {
    "target": "adventure",
    "tapped_before": tappedBefore ? 1 : 0,
    "last_placement": lastPlacement,
    "last_pattern": lastPattern,
    "since_tap": sinceTap,
    "is_premium": isPremium ? 1 : 0,
  });

  /// Shared parameters of the shown and tapped events
  static Map<String, Object> _promoShownParams({
    required String placement,
    required bool isPremium,
    required String lang,
    required String launchCount,
    required String rideCount,
    required String daysSinceFirstLaunch,
    required String shownCount,
    required String firstPattern,
    required String videoMode,
    required String bodyForm,
  }) => {
    "target": "adventure",
    "placement": placement,
    "is_premium": isPremium ? 1 : 0,
    "lang": lang,
    "launch_count": launchCount,
    "ride_count": rideCount,
    "days_since_first_launch": daysSinceFirstLaunch,
    "shown_count": shownCount,
    "first_pattern": firstPattern,
    "video_mode": videoMode,
    "body_form": bodyForm,
  };

  // No ATT event on purpose: UMP owns the prompt, so there is no answer callback.
  // Reading the status at launch would only record notDetermined.
}

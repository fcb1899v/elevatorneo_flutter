// =============================
// AnalyticsManager: Firebase Analytics event logging
//
// Centralizes all custom analytics events so the revenue funnel can be
// measured: rides -> unlock blocked -> reward ad / purchase.
// Key features:
// - Gameplay events (ride completion)
// - Monetization events (reward ad, interstitial, purchase)
// - Ad revenue reporting via AdMob paid event listener
// =============================

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'extension.dart';

class AnalyticsManager {

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // --- Internal Helper ---

  /// Log an event and swallow any failure so analytics never breaks the app
  static Future<void> _log(String name, [Map<String, Object>? params]) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
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

  /// Log realized ad revenue for LTV analysis and ROAS bidding
  /// Called from the AdMob `onPaidEvent` callback of each ad format
  static Future<void> adRevenue({
    required String format,
    required String adUnitId,
    required double valueMicros,
    required PrecisionType precision,
    required String currencyCode,
  }) => _log("ad_impression", {
    "ad_platform": "AdMob",
    "ad_format": format,
    "ad_unit_name": adUnitId,
    "currency": currencyCode,
    "value": valueMicros / 1000000.0,
    "precision": precision.name,
  });

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

  /// Log a restore attempt and whether it granted the entitlement
  static Future<void> upgradeRestored(bool isPremium) =>
      _log("upgrade_restored", {"is_premium": isPremium ? 1 : 0});

  // --- Review Events ---

  /// Log that the in-app store review prompt was requested
  static Future<void> reviewRequested() => _log("review_requested");

  // --- Tracking Events ---

  /// Log the outcome of the App Tracking Transparency prompt
  static Future<void> attResult(String status) =>
      _log("att_result", {"status": status});
}

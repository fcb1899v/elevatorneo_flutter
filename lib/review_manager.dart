// =============================
// ReviewManager: ride counting and store review requests
//
// The ride count drives both the store review prompt and interstitial
// pacing, so new users are never interrupted before they enjoy the app.
// Key features:
// - Persistent ride counter
// - One-shot in-app review request after enough rides
// =============================

import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_manager.dart';
import 'constant.dart';
import 'extension.dart';

class ReviewManager {

  static const String rideCountKey = "rideCountKey";
  static const String reviewRequestedKey = "reviewRequestedKey";

  // --- Ride Counter ---

  /// Read the stored number of completed rides
  static Future<int> getRideCount() async {
    final prefs = await SharedPreferences.getInstance();
    return rideCountKey.getSharedPrefInt(prefs, 0);
  }

  /// Increment and persist the ride counter, returning the new value
  static Future<int> incrementRideCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = rideCountKey.getSharedPrefInt(prefs, 0) + 1;
    rideCountKey.setSharedPrefInt(prefs, count);
    return count;
  }

  // --- Store Review ---

  /// Ask for a store review once the user has ridden enough to have an opinion
  /// The prompt is requested only once, and only when the OS allows it
  static Future<void> requestReviewIfEarned(int rideCount) async {
    if (rideCount < reviewRequestRides) return;
    final prefs = await SharedPreferences.getInstance();
    if (reviewRequestedKey.getSharedPrefBool(prefs, false)) return;
    try {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        reviewRequestedKey.setSharedPrefBool(prefs, true);
        await inAppReview.requestReview();
        await AnalyticsManager.reviewRequested();
        "review requested at ride $rideCount".debugPrint();
      }
    } catch (e) {
      "Review request error: $e".debugPrint();
    }
  }
}

// =============================
// AdInterstitialManager: full screen ads shown at natural breaks
//
// Interstitials are only shown between activities (leaving the settings
// screen), never during elevator operation, and are frequency capped so the
// experience stays intact.
// Key features:
// - Preloading with retry
// - Session cap, minimum interval and minimum ride count
// - Skipped entirely for premium users and when no ad unit is configured
// =============================

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'analytics_manager.dart';
import 'att_manager.dart';
import 'constant.dart';
import 'extension.dart';

class AdInterstitialManager {

  static InterstitialAd? _interstitialAd;
  static bool _isLoading = false;
  static int _numAttemptLoad = 0;
  static int _shownCount = 0;
  static DateTime? _lastShownAt;

  /// The ad unit is optional: without it configured in .env the feature is off
  static String? get _adUnitId => dotenv.maybeGet(interstitialAdUnitID);

  /// Whether an interstitial may be shown right now
  static bool _canShow(int rideCount) {
    if (_interstitialAd == null) return false;
    if (rideCount < interstitialMinRides) return false;
    if (_shownCount >= interstitialMaxPerSession) return false;
    final last = _lastShownAt;
    if (last != null && DateTime.now().difference(last).inSeconds < interstitialIntervalSec) {
      return false;
    }
    return true;
  }

  // --- Ad Loading ---

  /// Preload an interstitial so it can be shown without a wait
  /// Retries a few times with a growing delay, then gives up until next call
  static Future<void> load({required bool isPremium}) async {
    final adUnitId = _adUnitId;
    if (isPremium || adUnitId == null || _isLoading || _interstitialAd != null) return;
    _isLoading = true;
    await AttManager.ready;
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          'interstitial loaded'.debugPrint();
          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) =>
            AnalyticsManager.adRevenue(
              format: "interstitial",
              adUnitId: adUnitId,
              valueMicros: valueMicros,
              precision: precision,
              currencyCode: currencyCode,
            );
          _interstitialAd = ad;
          _isLoading = false;
          _numAttemptLoad = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          'interstitial failed to load: $error'.debugPrint();
          _interstitialAd = null;
          _isLoading = false;
          _numAttemptLoad++;
          if (_numAttemptLoad <= 2) {
            Future.delayed(Duration(seconds: 2 * _numAttemptLoad), () => load(isPremium: isPremium));
          }
        },
      ),
    );
  }

  // --- Ad Display ---

  /// Show a preloaded interstitial if every capping rule allows it
  /// Returns true when an ad was actually shown
  static Future<bool> showIfAllowed({
    required String placement,
    required bool isPremium,
    required int rideCount,
    void Function()? onDismissed,
  }) async {
    if (isPremium || _adUnitId == null) return false;
    if (!_canShow(rideCount)) {
      // Keep one ready for the next opportunity
      await load(isPremium: isPremium);
      return false;
    }
    final ad = _interstitialAd;
    if (ad == null) return false;
    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        _shownCount++;
        _lastShownAt = DateTime.now();
        AnalyticsManager.interstitialShown(placement);
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        onDismissed?.call();
        load(isPremium: isPremium);
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        '$ad failed to show: $error'.debugPrint();
        ad.dispose();
        onDismissed?.call();
        load(isPremium: isPremium);
      },
    );
    await ad.show();
    return true;
  }

  /// Release the cached ad, e.g. right after a premium purchase
  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}

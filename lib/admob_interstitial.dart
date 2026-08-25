// =============================
// AdInterstitialManager: NOT IN USE
//
// Nothing calls this. Interstitials were removed on 2026-08-24: the only
// placement was the moment the user leaves settings to get back to the
// elevator, and interrupting that intent was judged not worth the retention
// cost. Rewarded is the only full screen format this app shows.
//
// Kept because the capping design (session cap, minimum interval, minimum ride
// count) is worth having if the decision is ever revisited. Re-enabling means
// restoring the call sites in settings.dart and homepage.dart, and the
// dispose() on premium purchase in settings.dart.
// =============================

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'analytics_manager.dart';
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

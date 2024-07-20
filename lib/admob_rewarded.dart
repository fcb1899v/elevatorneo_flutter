import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'extension.dart';

RewardedAd? rewardedAd() {
  final rewardedAd = useState<RewardedAd?>(null);
  final retryAttempt = useState(0);
  //Dispose時のエラー対策
  final cancelToken = useState(Completer<void>());

  // バナー広告ID
  String rewardedAdId =
    (!kDebugMode && Platform.isIOS) ? dotenv.get("IOS_REWARDED_UNIT_ID"):
    (!kDebugMode && Platform.isAndroid) ? dotenv.get("ANDROID_REWARDED_UNIT_ID"):
    (Platform.isIOS) ? dotenv.get("IOS_REWARDED_TEST_ID"):
    dotenv.get("ANDROID_REWARDED_TEST_ID");

  void loadAd() {
    RewardedAd.load(
      adUnitId: rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) async {
          if (!cancelToken.value.isCompleted) {
            // 広告が正常にロードされたとき
            'ad loaded'.debugPrint();
            rewardedAd.value = ad;
            // リトライカウンタをリセット
            retryAttempt.value = 0;
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          'Ad failed to load: $error'.debugPrint();
          if (!cancelToken.value.isCompleted) {
            Future.delayed(Duration(seconds: 2 * retryAttempt.value), () {
              retryAttempt.value += 1; // リトライカウンタをインクリメント
            });
          }
        },
      ),
    );
  }

  useEffect(() {
    if (!cancelToken.value.isCompleted) {
      loadAd();
    }
    return () {
      cancelToken.value.complete();
      rewardedAd.value?.dispose();
    };
  }, [retryAttempt.value]);

  return rewardedAd.value;
}
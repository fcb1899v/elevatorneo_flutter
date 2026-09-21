import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'analytics_manager.dart';
import 'constant.dart';
import 'extension.dart';
import 'plan_provider.dart';

// ===== AdBannerWidget: bottom anchored adaptive banner, skipped for premium =====
// The UMP flow below owns the ATT prompt; ad requests never wait on that decision.

// Shared one-shot start of the Mobile Ads SDK; main() does not start it at launch.
// Dropped on failure so a later request can retry; returns null, never throws.
Future<InitializationStatus?>? _mobileAdsInitialization;

Future<InitializationStatus?> initializeMobileAds() =>
  _mobileAdsInitialization ??= _startMobileAds();

Future<InitializationStatus?> _startMobileAds() async {
  try {
    return await MobileAds.instance.initialize();
  } catch (e) {
    _mobileAdsInitialization = null;
    "MobileAds initialize failed: $e".debugPrint();
    return null;
  }
}

class AdBannerWidget extends HookConsumerWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(planProvider).isPremium;
    final adLoaded = useState(false);
    final adHeight = useState(context.admobHeight());
    final bannerAd = useState<BannerAd?>(null);
    // Refs, not state: the SDK calls back after unmount, and a disposed notifier asserts.
    final retryAttempt = useRef(0);
    final isLoadingAd = useRef(false);
    // Three callers can ask for the first ad; only one may own a request.
    // The retry path below bypasses this
    final isAdRequested = useRef(false);
    // final testIdentifiers = ['2793ca2a-5956-45a2-96c0-16fafddc1a15'];

    // Banner ad unit id
    String bannerUnitId() => bannerAdUnitID;

    Future<void> loadAdBanner() async {
      // Callers wait on consent or a retry timer, so the screen may already be gone.
      if (!context.mounted) return;
      // Re-read the plan, because isPremium was captured at build time.
      // A premium user must never get a request, since nothing would dispose that BannerAd.
      if (ref.read(planProvider).isPremium) return;
      // A pending retry and a fresh consent callback can both land here.
      // A second BannerAd would orphan the first.
      if (isLoadingAd.value) return;
      isLoadingAd.value = true;
      final adWidth = context.width().truncate();
      final adMaxHeight = context.admobHeight().truncate();
      final adBanner = BannerAd(
        adUnitId: bannerUnitId(),
        size: AdSize.getInlineAdaptiveBannerAdSize(adWidth, adMaxHeight),
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) async {
            'Ad: $ad loaded.'.debugPrint();
            isLoadingAd.value = false;
            // Mount the AdWidget first, because awaiting the size call delays the impression.
            // A screen change during that wait would drop an ad that already filled.
            adLoaded.value = true;
            // Then fit the container to the size the server actually returned.
            // The request caps the height, so this only ever shrinks the slot
            final platformAdSize = await (ad as BannerAd).getPlatformAdSize();
            'AdSize: cap $adMaxHeight width $adWidth / served: ${platformAdSize?.width} x ${platformAdSize?.height}'.debugPrint();
            if (platformAdSize != null) {
              adHeight.value = platformAdSize.height.toDouble();
            }
          },
          onAdFailedToLoad: (ad, error) {
            'Ad: $ad failed to load: $error'.debugPrint();
            isLoadingAd.value = false;
            // A failed auto refresh reports here too while the SDK keeps refreshing.
            // So an ad that already reached the screen is left alone.
            if (adLoaded.value) return;
            ad.dispose();
            retryAttempt.value += 1;
            // Capped retry: unfilled requests never match, and they pollute the match rate.
            // This widget lives as long as the screen, so an uncapped retry never stops.
            if (retryAttempt.value > bannerMaxRetry) return;
            final backoffSec = math.min(
              bannerRetryBaseSec * (1 << (retryAttempt.value - 1)),
              bannerRetryMaxSec,
            );
            Future.delayed(Duration(seconds: backoffSec), () {
              if (adLoaded.value || !context.mounted) return;
              loadAdBanner();
            });
          },
          onPaidEvent: (ad, valueMicros, precision, currencyCode) =>
            AnalyticsManager.adRevenue(
              format: "banner",
              adUnitId: bannerUnitId(),
              valueMicros: valueMicros,
              precision: precision,
              currencyCode: currencyCode,
            ),
        ),
      );
      adBanner.load();
      bannerAd.value = adBanner;
    }

    // The single gate for the first request.
    // canRequestAds is the SDK's verdict (region, TCF, Additional Consent); unsure means no.
    Future<void> requestAdIfAllowed() async {
      if (isAdRequested.value) return;
      if (!await ConsentInformation.instance.canRequestAds()) return;
      // Callers race across that await, so claim the request with no await in between.
      // Then no second BannerAd is ever created for the same slot.
      if (isAdRequested.value) return;
      isAdRequested.value = true;
      if (await initializeMobileAds() == null) {
        // Release the claim, or this slot stays empty for the rest of the screen's life.
        // A later request may well win the start that failed here.
        isAdRequested.value = false;
        return;
      }
      await loadAdBanner();
    }

    useEffect(() {
      // Premium users never see ads, so no consent form and no ad request
      if (isPremium) return null;
      // Coming back from premium leaves the old ad disposed while adLoaded is still true.
      // Resetting it keeps the slot empty until the new ad is ready.
      adLoaded.value = false;
      retryAttempt.value = 0;
      // Coming back from premium has to be able to request again.
      // The flag only guards duplicates within one run of this effect.
      isAdRequested.value = false;
      // isLoadingAd is not reset: a request in flight still owes a callback.
      // Clearing it would let a second request start and orphan the first.

      // Last session's consent is on the device, so this runs alongside the update below.
      requestAdIfAllowed();

      ConsentInformation.instance.requestConsentInfoUpdate(ConsentRequestParameters(
        // consentDebugSettings: ConsentDebugSettings(
        //   debugGeography: DebugGeography.debugGeographyEea,
        //   testIdentifiers: testIdentifiers,
        // ),
      ), () async {
        // The SDK decides whether a form is needed and shows it only then.
        await ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
          if (formError != null) {
            "formError: ${formError.errorCode}: ${formError.message}".debugPrint();
          }
          await requestAdIfAllowed();
        });
      }, (FormError error) async {
        // The update failed, but earlier consent stands and canRequestAds may still say yes.
        // Do not throw away those impressions.
        "error: ${error.errorCode}: ${error.message}".debugPrint();
        await requestAdIfAllowed();
      });
      "bannerAd: ${bannerAd.value}".debugPrint();
      return () => bannerAd.value?.dispose();      // Drop the ad on unmount
    }, [isPremium]);

    if (isPremium) return const SizedBox.shrink();
    return Column(mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Spacer(),
        Container(
          width: context.width(),
          height: context.admobHeight(),
          color: blackColor,
          alignment: Alignment.center,
          child: (adLoaded.value && bannerAd.value != null) ? SizedBox(
            width: context.width(),
            height: adHeight.value,
            child: AdWidget(ad: bannerAd.value!),
          ): null,
        ),
      ]
    );
  }
}

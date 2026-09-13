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

// Shared one-shot start of the Mobile Ads SDK; main() no longer starts it at launch.
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
    // Refs, not state: the SDK calls back after unmount, and writing to a
    // disposed ValueNotifier asserts in debug and is a silent no-op in release
    final retryAttempt = useRef(0);
    final isLoadingAd = useRef(false);
    // Three callers can ask for the first ad; only one may own a request.
    // The retry path below bypasses this
    final isAdRequested = useRef(false);
    // final testIdentifiers = ['2793ca2a-5956-45a2-96c0-16fafddc1a15'];

    // バナー広告ID
    String bannerUnitId() => bannerAdUnitID;

    Future<void> loadAdBanner() async {
      // Every caller sits behind the consent round trip or a retry timer, so
      // the screen can already be gone by the time this runs
      if (!context.mounted) return;
      // Re-read the plan: isPremium was captured at build time, and a premium
      // user must never get a request (nothing would dispose that BannerAd)
      if (ref.read(planProvider).isPremium) return;
      // A pending retry and a fresh consent callback can both land here; a
      // second BannerAd would orphan the first
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
            // Mount the AdWidget first: awaiting the size call delays the
            // impression, and a screen change meanwhile drops a filled ad
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
            // A failed auto refresh reports on the live AdView too; the SDK keeps
            // refreshing, so an ad that reached the screen is left alone
            if (adLoaded.value) return;
            ad.dispose();
            retryAttempt.value += 1;
            // Capped retry: this widget lives for the whole screen, and unfilled
            // requests never match, so they pollute the match rate
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

    // The single gate for the first request. canRequestAds is the SDK's own
    // verdict (region, TCF string, Additional Consent); unsure means no
    Future<void> requestAdIfAllowed() async {
      if (isAdRequested.value) return;
      if (!await ConsentInformation.instance.canRequestAds()) return;
      // Callers race across that await; claiming the request with no await in
      // between means no second BannerAd is ever created for the same slot
      if (isAdRequested.value) return;
      isAdRequested.value = true;
      if (await initializeMobileAds() == null) {
        // Release the claim. Holding it would keep this slot empty for the rest
        // of the screen's life over a start that a later request may well win
        isAdRequested.value = false;
        return;
      }
      await loadAdBanner();
    }

    useEffect(() {
      // Premium users never see ads, so no consent form and no ad request
      if (isPremium) return null;
      // Coming back from premium leaves the previous ad disposed while adLoaded
      // is still true, so the slot starts empty until the new ad is ready
      adLoaded.value = false;
      retryAttempt.value = 0;
      // Coming back from premium has to be able to request again. The flag only
      // guards duplicate requests within one run of this effect
      isAdRequested.value = false;
      // isLoadingAd is not reset: a request in flight still owes a callback,
      // and clearing it would let a second request start and orphan the first

      // Last session's consent is already on the device, so this runs in parallel
      // with the update below and proceeds only if the SDK already says yes
      requestAdIfAllowed();

      ConsentInformation.instance.requestConsentInfoUpdate(ConsentRequestParameters(
        // consentDebugSettings: ConsentDebugSettings(
        //   debugGeography: DebugGeography.debugGeographyEea,
        //   testIdentifiers: testIdentifiers,
        // ),
      ), () async {
        // The SDK decides whether a form is needed, loads and presents it; it
        // does nothing when no form is required
        await ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
          if (formError != null) {
            "formError: ${formError.errorCode}: ${formError.message}".debugPrint();
          }
          await requestAdIfAllowed();
        });
      }, (FormError error) async {
        // The update failed, but earlier consent still stands and canRequestAds
        // can still say yes, so do not throw away those impressions
        "error: ${error.errorCode}: ${error.message}".debugPrint();
        await requestAdIfAllowed();
      });
      "bannerAd: ${bannerAd.value}".debugPrint();
      return () => bannerAd.value?.dispose();      // unmount時に広告を破棄する
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

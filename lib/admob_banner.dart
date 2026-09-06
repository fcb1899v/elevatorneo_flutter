import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'analytics_manager.dart';
import 'constant.dart';
import 'extension.dart';
import 'plan_provider.dart';

// =============================
// AdBannerWidget: bottom anchored banner
//
// Uses an inline adaptive size capped to the reserved slot height so Google
// can pick the best performing creative without shifting the app layout.
// The request fires as soon as consent allows and is skipped for premium users.
//
// The UMP consent flow below is also the only place tracking is asked for. On
// iOS the AdMob form shows the IDFA explainer and then the system ATT dialog,
// so the app must not present a prompt of its own: UMP answers ATT while an app
// side dialog is still on screen. The request itself never waits on that
// decision, since a wait costs impressions and personalization catches up on
// the next refresh anyway.
// =============================

// The Mobile Ads SDK has to be started before an ad is requested. main() starts
// it right after runApp, but the consent check in this file reads a cached
// answer over a single channel call, so it can reach a request first. Both
// paths go through this future, which keeps the platform start at exactly one
// call and leaves main()'s await where it was.
Future<InitializationStatus>? _mobileAdsInitialization;
Future<InitializationStatus> initializeMobileAds() =>
  _mobileAdsInitialization ??= MobileAds.instance.initialize();

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
    // Three callers can ask for the first ad: the cached consent check at
    // mount, the consent form callback and the consent update failure. Only
    // one of them may own a request, and the retry path below bypasses this
    final isAdRequested = useRef(false);
    // final testIdentifiers = ['2793ca2a-5956-45a2-96c0-16fafddc1a15'];

    // バナー広告ID
    String bannerUnitId() => bannerAdUnitID;

    Future<void> loadAdBanner() async {
      // Every caller sits behind the consent round trip or a retry timer, so
      // the screen can already be gone by the time this runs
      if (!context.mounted) return;
      // isPremium was captured when this build ran. Read the plan again: buying
      // premium across that gap would send a request for a user who must not
      // get ads, and the premium branch of the effect registers no cleanup, so
      // nothing would ever dispose that BannerAd
      if (ref.read(planProvider).isPremium) return;
      // A pending retry and a fresh consent callback can both land here. The
      // second BannerAd would overwrite bannerAd.value and leave the first with
      // no owner to dispose it
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
            // Mount the AdWidget first. Awaiting the platform size call before
            // this delays the impression, and a screen change during that gap
            // throws away an ad that was already filled
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
            // The listener stays attached to one platform AdView for its whole
            // life, so a failed auto refresh reports here on the very instance
            // the AdWidget is showing. Disposing it would tear down a live view
            // and the SDK keeps refreshing on its own, so an ad that reached
            // the screen is left alone. The retry below is for the first fill
            if (adLoaded.value) return;
            ad.dispose();
            retryAttempt.value += 1;
            // This widget stays mounted for the whole screen, so a fixed retry
            // with no ceiling would keep asking a device that has no fill.
            // Unfilled requests never match, so they pollute the match rate
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

    // The single gate for the first ad request. canRequestAds is the SDK's own
    // verdict: it already weighs the region, the TCF consent string and
    // Additional Consent, so the app must not read ConsentStatus and decide for
    // itself. unknown means the SDK could not determine consent, and letting
    // that through is exactly what serving without consent looks like in the
    // EEA. Anything the SDK is unsure about is a no here
    Future<void> requestAdIfAllowed() async {
      if (isAdRequested.value) return;
      if (!await ConsentInformation.instance.canRequestAds()) return;
      // Callers race across that await. Claiming the request happens with no
      // await in between, so whoever resumes second always sees the flag and
      // no second BannerAd is ever created for the same slot
      if (isAdRequested.value) return;
      isAdRequested.value = true;
      await initializeMobileAds();
      await loadAdBanner();
    }

    useEffect(() {
      // Premium users never see ads, so no consent form and no ad request
      if (isPremium) return null;
      // Coming back from premium leaves the previous ad disposed by that
      // switch's cleanup, while adLoaded still says true. Rendering an AdWidget
      // around a disposed instance is what that stale pair would do, so the
      // slot starts empty again and only fills once the new ad is ready
      adLoaded.value = false;
      retryAttempt.value = 0;
      // Coming back from premium has to be able to request again. The flag only
      // guards duplicate requests within one run of this effect
      isAdRequested.value = false;
      // isLoadingAd is deliberately not reset: a request already in flight
      // still owes us a callback, and clearing the flag here would let a second
      // request start and orphan the first

      // The consent decision from the last session is already on the device, so
      // the first request does not have to wait for the update below. This runs
      // in parallel with it and only proceeds if the SDK already says yes
      requestAdIfAllowed();

      ConsentInformation.instance.requestConsentInfoUpdate(ConsentRequestParameters(
        // consentDebugSettings: ConsentDebugSettings(
        //   debugGeography: DebugGeography.debugGeographyEea,
        //   testIdentifiers: testIdentifiers,
        // ),
      ), () async {
        // The SDK decides whether a form is needed, loads it and presents it.
        // Assembling that by hand from isConsentFormAvailable, loadConsentForm
        // and getConsentStatus re-implements rules that Google changes on their
        // side. This call does nothing when no form is required
        await ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
          if (formError != null) {
            "formError: ${formError.errorCode}: ${formError.message}".debugPrint();
          }
          await requestAdIfAllowed();
        });
      }, (FormError error) async {
        // The update failed, but consent given in an earlier session still
        // stands and canRequestAds can still say yes. Stopping here would throw
        // away impressions the SDK would have allowed
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

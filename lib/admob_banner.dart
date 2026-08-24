import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'analytics_manager.dart';
import 'att_manager.dart';
import 'constant.dart';
import 'extension.dart';
import 'plan_provider.dart';

// =============================
// AdBannerWidget: bottom anchored banner
//
// Uses an inline adaptive size capped to the reserved slot height so Google
// can pick the best performing creative without shifting the app layout.
// The ad request waits for the ATT decision and is skipped for premium users.
// =============================

class AdBannerWidget extends HookConsumerWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(planProvider).isPremium;
    final adLoaded = useState(false);
    final adFailedLoading = useState(false);
    final adHeight = useState(context.admobHeight());
    final bannerAd = useState<BannerAd?>(null);
    // final testIdentifiers = ['2793ca2a-5956-45a2-96c0-16fafddc1a15'];

    // バナー広告ID
    String bannerUnitId() => dotenv.get(bannerAdUnitID);

    Future<void> loadAdBanner() async {
      // Read layout metrics before awaiting so no BuildContext crosses the gap
      final adWidth = context.width().truncate();
      final adMaxHeight = context.admobHeight().truncate();
      // Wait for the ATT decision so the first impression can use the IDFA
      await AttManager.ready;
      final adBanner = BannerAd(
        adUnitId: bannerUnitId(),
        size: AdSize.getInlineAdaptiveBannerAdSize(adWidth, adMaxHeight),
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) async {
            'Ad: $ad loaded.'.debugPrint();
            // Fit the container to the size the server actually returned
            final platformAdSize = await (ad as BannerAd).getPlatformAdSize();
            if (platformAdSize != null) {
              adHeight.value = platformAdSize.height.toDouble();
            }
            adLoaded.value = true;
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            'Ad: $ad failed to load: $error'.debugPrint();
            adFailedLoading.value = true;
            Future.delayed(const Duration(seconds: 30), () {
              if (!adLoaded.value && !adFailedLoading.value) loadAdBanner();
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

    useEffect(() {
      // Premium users never see ads, so no consent form and no ad request
      if (isPremium) return null;
      ConsentInformation.instance.requestConsentInfoUpdate(ConsentRequestParameters(
        // consentDebugSettings: ConsentDebugSettings(
        //   debugGeography: DebugGeography.debugGeographyEea,
        //   testIdentifiers: testIdentifiers,
        // ),
      ), () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          ConsentForm.loadConsentForm((ConsentForm consentForm) async {
            var status = await ConsentInformation.instance.getConsentStatus();
            "status: $status".debugPrint();
            if (status == ConsentStatus.required) {
              consentForm.show((formError) async => await loadAdBanner());
            } else {
              await loadAdBanner();
            }
          }, (formError) {
            "formError: $formError".debugPrint();
          });
        } else {
          await loadAdBanner();
        }
      }, (FormError error) {
        "error: ${error.message}: $error".debugPrint();
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

/// Store links for the LETS ELEVATOR ADVENTURE cross-promo.
///
/// The package name, URL name, app ID and provider token are public values, not secrets.
/// Placement is `menu` or `launch`, and app is `letselevator` or `letselevatorneo`.
library;

/// Android package name of LETS ELEVATOR ADVENTURE.
const String promoAdventureAndroidPackage = 'nakajimamasao.appstudio.elevator3d';

/// iOS URL name (bundle ID) of LETS ELEVATOR ADVENTURE.
///
/// The store link builders below do not use it.
const String promoAdventureIosUrlName = 'nakajimamasao.appstudio.elevator3d';

/// Numeric iOS app ID of LETS ELEVATOR ADVENTURE (the number after `id`).
///
/// Copied from App Store Connect; empty until then.
/// iOS links stay off while empty.
const String promoAdventureIosAppId = '';

/// iOS provider token (`pt`) for the App Store link.
///
/// Copied from App Analytics; empty until then.
/// iOS links stay off while empty.
const String promoAdventureIosPt = '';

/// Whether the promo is shown on Android.
const bool promoAndroidEnabled = true;

/// Whether the promo is shown on iOS. Turned on only after the iOS ADVENTURE is released.
const bool promoIosEnabled = false;

/// Returns the Android `referrer` value for [app] and [placement].
///
/// Throws an [ArgumentError] when [placement] is not `menu` or `launch`.
String promoAndroidReferrer({required String app, required String placement}) {
  _checkPlacement(placement);
  return 'utm_source%3D$app%26utm_medium%3Din_app%26utm_campaign%3D$placement';
}

/// Returns the Google Play inline install URL for Android.
///
/// Opened with the package set to `com.android.vending`, it shows the store page in a half sheet.
String promoAndroidInlineInstallUrl({required String app, required String placement}) {
  final referrer = promoAndroidReferrer(app: app, placement: placement);
  return 'https://play.google.com/d?id=$promoAdventureAndroidPackage&referrer=$referrer';
}

/// Returns the normal Google Play store page URL for Android.
///
/// Used when the inline install cannot be opened.
String promoAndroidStoreUrl({required String app, required String placement}) {
  final referrer = promoAndroidReferrer(app: app, placement: placement);
  return 'https://play.google.com/store/apps/details?id=$promoAdventureAndroidPackage&referrer=$referrer';
}

/// Returns the iOS `ct` value (campaign token) for [placement].
///
/// Only the placement is in `ct`. The app is told apart by the App Referrer.
/// Throws an [ArgumentError] when [placement] is not `menu` or `launch`.
String promoIosCampaignToken({required String placement}) {
  _checkPlacement(placement);
  return 'promo_$placement';
}

/// Returns the App Store URL for [appId], [pt] and [placement], or null when [appId] or [pt] is empty.
///
/// The format is `https://apps.apple.com/app/id<appId>?pt=<pt>&ct=<ct>&mt=8`.
String? promoIosStoreUrlFor({
  required String appId,
  required String pt,
  required String placement,
}) {
  if (appId.isEmpty || pt.isEmpty) return null;
  final ct = promoIosCampaignToken(placement: placement);
  return 'https://apps.apple.com/app/id$appId?pt=$pt&ct=$ct&mt=8';
}

/// Returns the App Store URL of ADVENTURE for [placement] from the constants above, or null while the ID or the provider token (`pt`) is empty.
String? promoIosStoreUrl({required String placement}) => promoIosStoreUrlFor(
      appId: promoAdventureIosAppId,
      pt: promoAdventureIosPt,
      placement: placement,
    );

/// Whether the promo may be shown on iOS now.
///
/// False while [promoIosEnabled] is false, or while the ID or the token is empty.
bool promoShowOnIos() =>
    promoIosEnabled && promoAdventureIosAppId.isNotEmpty && promoAdventureIosPt.isNotEmpty;

void _checkPlacement(String placement) {
  if (placement != 'menu' && placement != 'launch') {
    throw ArgumentError.value(placement, 'placement', 'must be menu or launch');
  }
}

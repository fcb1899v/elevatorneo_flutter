/// Remote Config settings and defaults for the whole app, applied once.
///
/// Every reader (coupon codes and the cross-promo) calls [ensureRemoteConfigReady] first.
/// Calling setDefaults from two places would let the later call replace the earlier defaults.
library;

import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Defaults for every Remote Config key the app reads. Keys match PromoConfig and CouponManager.
const Map<String, Object> remoteConfigDefaults = {
  'promo_menu_enabled': true,
  'promo_video_patterns': 'p1,p2,p3',
  'promo_video_enabled': true,
  'coupon_codes': '',
};

Future<void>? _ready;

/// Sets the Remote Config settings and defaults once. A failed setup is retried on the next call.
Future<void> ensureRemoteConfigReady() => _ready ??= _setup();

Future<void> _setup() async {
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await remoteConfig.setDefaults(remoteConfigDefaults);
  } catch (_) {
    _ready = null;
    rethrow;
  }
}

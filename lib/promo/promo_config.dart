/// Remote Config switches for the LETS ELEVATOR ADVENTURE cross-promo.
///
/// The values change the menu notice without an app update.
/// The defaults are the values shipped in the app, so the promo still works offline.
library;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../extension.dart';
import '../remote_config_setup.dart';

/// Holds the Remote Config keys, the bundled video patterns and the current values.
class PromoConfig {
  /// Remote Config key that turns the menu notice on or off.
  static const String menuEnabledKey = 'promo_menu_enabled';

  /// Remote Config key with the comma separated video patterns to play, in order.
  static const String videoPatternsKey = 'promo_video_patterns';

  /// Remote Config key that turns the video on or off.
  static const String videoEnabledKey = 'promo_video_enabled';

  /// The patterns bundled in the app, in play order.
  static const List<String> allPatterns = ['p1', 'p2', 'p3'];

  /// Current values. They hold the defaults until a fetch succeeds.
  static bool menuEnabled = true;

  /// Current video patterns, in play order.
  static List<String> videoPatterns = allPatterns;

  /// Current video switch.
  static bool videoEnabled = true;

  /// Fetches and activates Remote Config, then applies the values. Never throws.
  static Future<void> fetch() async {
    try {
      // Settings and defaults are shared with the coupon check, so they are set once in one place.
      await ensureRemoteConfigReady();
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();
      applyValues(
        menuEnabled: remoteConfig.getBool(menuEnabledKey),
        patterns: remoteConfig.getString(videoPatternsKey),
        videoEnabled: remoteConfig.getBool(videoEnabledKey),
      );
      'PromoConfig: menu=$menuEnabled patterns=$videoPatterns video=$videoEnabled'.debugPrint();
    } catch (e) {
      'PromoConfig: fetch error: $e'.debugPrint();
    }
  }

  /// Applies raw values. Tests call it directly.
  @visibleForTesting
  static void applyValues({
    required bool menuEnabled,
    required String patterns,
    required bool videoEnabled,
  }) {
    PromoConfig.menuEnabled = menuEnabled;
    videoPatterns = parsePatterns(patterns);
    PromoConfig.videoEnabled = videoEnabled;
  }

  /// Turns a comma separated list into known pattern names.
  ///
  /// Unknown names are dropped, and repeated names keep only their first place.
  /// An empty result falls back to [allPatterns].
  @visibleForTesting
  static List<String> parsePatterns(String raw) {
    final result = <String>[];
    for (final part in raw.split(',')) {
      final name = part.trim();
      if (allPatterns.contains(name) && !result.contains(name)) {
        result.add(name);
      }
    }
    return result.isEmpty ? allPatterns : result;
  }

  /// Puts the defaults back. Tests call it.
  @visibleForTesting
  static void reset() {
    menuEnabled = true;
    videoPatterns = allPatterns;
    videoEnabled = true;
  }
}

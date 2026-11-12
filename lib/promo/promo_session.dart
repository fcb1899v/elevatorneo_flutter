/// Runs the LETS ELEVATOR ADVENTURE cross-promo checks at launch and when the app comes back.
///
/// It finds out whether ADVENTURE is installed, and logs the first find once per device.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../analytics_manager.dart';
import '../extension.dart';
import 'promo_buckets.dart';
import 'promo_config.dart';
import 'promo_links.dart';
import 'promo_prefs.dart';
import 'promo_store.dart';

/// Checks ADVENTURE again each time the app is resumed.
class _PromoLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(PromoSession.refreshInstalled());
  }
}

/// Holds the launch steps and the installed state of the cross-promo.
class PromoSession {
  /// True once ADVENTURE is found on this device. The menu hides the notice while true.
  static final ValueNotifier<bool> adventureInstalled = ValueNotifier(false);

  /// The pattern to play first, read at launch so the menu can start at once.
  static String? nextPattern;

  /// Tests replace it to show the promo on any platform.
  @visibleForTesting
  static bool Function()? platformOverride;

  /// Returns the platform name. Tests replace it.
  @visibleForTesting
  static String Function() platformSource = () => Platform.operatingSystem;

  static bool _started = false;
  static bool _refreshing = false;
  static bool Function()? _isPremium;
  static _PromoLifecycleObserver? _observer;

  /// Whether the promo may be shown on this platform now.
  static bool platformEnabled() {
    final override = platformOverride;
    if (override != null) return override();
    switch (platformSource()) {
      case 'android':
        return promoAndroidEnabled;
      case 'ios':
        // The debug-only switch lets a development build show the iOS notice before release.
        return promoShowOnIos() || (kDebugMode && const bool.fromEnvironment('PROMO_FORCE_IOS'));
      default:
        return false;
    }
  }

  /// Runs the launch steps once. Never throws.
  static Future<void> start({required bool Function() isPremium}) async {
    if (_started) return;
    _started = true;
    _isPremium = isPremium;
    try {
      await PromoPrefs.recordLaunch();
      nextPattern = await PromoPrefs.getAdventureVideoNextPattern();
      if (!platformEnabled()) return;
      await PromoConfig.fetch();
      await refreshInstalled();
      if (_observer == null) {
        final observer = _PromoLifecycleObserver();
        _observer = observer;
        WidgetsBinding.instance.addObserver(observer);
      }
    } catch (e) {
      'PromoSession: start error: $e'.debugPrint();
    }
  }

  /// Checks whether ADVENTURE is installed and logs the first find. Never throws.
  static Future<void> refreshInstalled() async {
    // A call made while another check runs is dropped, so the first find is logged once.
    if (_refreshing || !platformEnabled()) return;
    _refreshing = true;
    try {
      final installed = await PromoStore.isAdventureInstalled();
      adventureInstalled.value = installed;
      if (!installed || await PromoPrefs.isAdventureFoundLogged()) return;
      final tapped = await PromoPrefs.getAdventureTapped();
      final tappedAt = await PromoPrefs.getAdventureTappedAt();
      final pattern = await PromoPrefs.getAdventureLastTappedPattern();
      await AnalyticsManager.crossPromoTargetFound(
        tappedBefore: tapped != null,
        lastPlacement: tapped ?? 'none',
        lastPattern: pattern ?? 'none',
        sinceTap: sinceTapBucket(tappedAt == null ? null : DateTime.now().difference(tappedAt)),
        isPremium: _isPremium?.call() ?? false,
      );
      await PromoPrefs.markAdventureFoundLogged();
    } catch (e) {
      'PromoSession: refresh error: $e'.debugPrint();
    } finally {
      _refreshing = false;
    }
  }

  /// Puts the static state back. Tests call it.
  @visibleForTesting
  static void reset() {
    adventureInstalled.value = false;
    nextPattern = null;
    platformOverride = null;
    platformSource = () => Platform.operatingSystem;
    _started = false;
    _refreshing = false;
    _isPremium = null;
    final observer = _observer;
    if (observer != null) WidgetsBinding.instance.removeObserver(observer);
    _observer = null;
  }
}

// ===== PurchaseManager: the premium unlock, bought once =====
// SDK starts on first use, never at launch (1.5.24 launch-crash rejection; see 2026-09-06 note).

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_manager.dart';
import 'constant.dart';
import 'extension.dart';
import 'plan_provider.dart';

/// The store answered, but there is nothing to sell: no offering, no package,
/// or the SDK could not start. Distinct from a purchase that was attempted and
/// failed, because the message the user reads is different
class StoreUnavailableException implements Exception {
  final String reason;
  const StoreUnavailableException(this.reason);
  @override
  String toString() => "StoreUnavailableException: $reason";
}

class PurchaseManager {

  /// Guards against a second purchase flow while one is still running
  static bool _isPurchasing = false;

  // --- Setup ---

  /// The one configure() call, shared by everyone who needs the store.
  /// Held so a second caller joins the first instead of configuring twice
  static Future<bool>? _configuring;

  /// Starts the store SDK on first use; every other call here awaits this.
  /// Returns false with no API key, and the caller must then hide the purchase UI
  static Future<bool> _ensureConfigured() => _configuring ??= _configure();

  static Future<bool> _configure() async {
    try {
      final apiKey = dotenv.maybeGet(revenueCatApiKey);
      if (apiKey == null || apiKey.isEmpty) {
        "No RevenueCat API key: purchases stay off".debugPrint();
        return false;
      }
      if (await Purchases.isConfigured) return true;
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug: LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      if (Platform.isIOS || Platform.isMacOS) {
        await Purchases.enableAdServicesAttributionTokenCollection();
      }
      return true;
    } catch (e) {
      // Clear the shared future so a later attempt can try again: a failure
      // here is usually the network, and the user may well tap the lock twice
      _configuring = null;
      "RevenueCat configure failed: $e".debugPrint();
      return false;
    }
  }

  /// Picks the package to sell: the lifetime one, otherwise the first available
  static Package? _premiumPackage(Offerings offerings) {
    final current = offerings.current;
    if (current == null) return null;
    if (current.lifetime != null) return current.lifetime;
    return current.availablePackages.isNotEmpty ? current.availablePackages.first: null;
  }

  // --- Entitlement ---

  /// Writes the entitlement to the local cache so the next launch can read it
  static Future<void> _cachePremium(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    premiumKey.setSharedPrefBool(prefs, isPremium);
  }

  /// The store's localized price, or null when it has nothing to sell.
  ///
  /// Null no longer hides the purchase entry points. An app's first In-App
  /// Purchase has to be attached to the same submission as the binary, and
  /// Apple documents that StoreKit can return no products in the App Review
  /// sandbox in exactly that state. Hiding on null would show the reviewer an
  /// app with no purchase at all, and the purchase would be rejected with it.
  /// The button is drawn either way; pressing it with no price says so aloud
  static Future<String?> fetchPrice() async {
    try {
      if (!await _ensureConfigured()) return null;
      final Offerings offerings = await Purchases.getOfferings();
      final package = _premiumPackage(offerings);
      if (package == null) return null;
      "premium price: ${package.storeProduct.priceString}".debugPrint();
      return package.storeProduct.priceString;
    } catch (e) {
      "Error fetching offerings: $e".debugPrint();
      return null;
    }
  }

  // --- Purchase and Restore ---

  /// Fetches offerings and initiates purchase. The PlatformException is not wrapped:
  /// buyPremium reads its error code to tell a user cancel from a real failure
  static Future<bool> _purchasePremium() async {
    if (!await _ensureConfigured()) {
      throw const StoreUnavailableException("configure");
    }
    // Only this call is wrapped. getOfferings throws when the dashboard has no
    // product, which is "nothing to sell", not a purchase that failed. The
    // purchase() below is deliberately left bare: buyPremium reads the error
    // code off its PlatformException to tell a user-initiated cancel apart
    final Offerings offerings;
    try {
      offerings = await Purchases.getOfferings();
    } catch (e) {
      throw StoreUnavailableException("offerings: $e");
    }
    if (offerings.current == null) {
      throw const StoreUnavailableException("no offering");
    }
    final package = _premiumPackage(offerings);
    if (package == null) {
      throw const StoreUnavailableException("no package");
    }
    final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
    final isPremium = purchaseResult.customerInfo.entitlements.active[premiumEntitlementID]?.isActive ?? false;
    "purchased isPremium: $isPremium".debugPrint();
    return isPremium;
  }

  /// Restores previous purchases from the app store
  /// Returns the premium status carried by the restored entitlements
  static Future<bool> _restorePremium() async {
    if (!await _ensureConfigured()) {
      throw const StoreUnavailableException("configure");
    }
    final restoredInfo = await Purchases.restorePurchases();
    final isPremium = restoredInfo.entitlements.active[premiumEntitlementID]?.isActive ?? false;
    "restored isPremium: $isPremium".debugPrint();
    return isPremium;
  }

  /// Purchase/restore entry point for the UI. Returns true when the user ends up
  /// premium, false on cancellation, and throws on failure
  static Future<bool> buyPremium({required bool isRestore, required String source}) async {
    if (_isPurchasing) return false;
    _isPurchasing = true;
    try {
      final bool isPremium;
      if (isRestore) {
        isPremium = await _restorePremium();
        await AnalyticsManager.upgradeRestored(isPremium);
      } else {
        await AnalyticsManager.upgradeStarted(source);
        isPremium = await _purchasePremium();
        if (isPremium) await AnalyticsManager.upgradePurchased(source);
      }
      // Cache only an upgrade: a restore that finds nothing is not proof of no
      // premium, and writing false would show ads to a paying user next launch
      if (isPremium) await _cachePremium(true);
      _isPurchasing = false;
      return isPremium;
    } catch (e) {
      "Purchase flow error: $e".debugPrint();
      _isPurchasing = false;
      if (e is PlatformException) {
        final errorCode = PurchasesErrorHelper.getErrorCode(e);
        // A user-initiated cancel is not an error worth surfacing
        if (errorCode == PurchasesErrorCode.purchaseCancelledError) return false;
      }
      rethrow;
    }
  }
}

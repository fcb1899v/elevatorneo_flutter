// =============================
// PurchaseManager: NOT IN USE
//
// Nothing calls this. The store SDK setup and the premium purchase flow were
// taken out of the launch path on 2026-08-29, after iOS 1.5.24 was rejected in
// App Store review as "The app crashed after the initial launch". The crash log
// has not been obtained yet, so the cause is NOT confirmed. This is a decision
// to resubmit without the newest moving parts, not a fix for a known defect.
//
// Nothing in this file runs unless it is called, so no Purchases API is reached
// while it stays unreferenced. purchases_flutter stays in pubspec.yaml, and its
// iOS plugin only registers a method channel at startup, so the store is never
// contacted.
//
// The SPM graph is NOT identical to the rejected build. The linked native SDK
// is newer: commit c82f832 moved purchases_flutter to ^10.10.0 and
// Package.resolved followed it, taking purchases-hybrid-common from 17.55.1 to
// 18.32.1 and purchases-ios-spm from 5.67.1 to 5.85.0. Those versions ship in
// this build even though nothing starts them. Removing the dependency would
// rebuild the package graph instead, which is the larger of the two changes.
//
// Kept because the entitlement design (local cache fallback, lifetime package
// pick, restore flow required by both stores) is worth having when purchases
// come back in a later release.
//
// The removed call sites are in git at commit a0c5f7e: settings.dart held
// runPurchase() and showUpgrade(), and plan_provider.dart held the purchase
// methods this file now owns. Re-enabling means:
//   1. main.dart: call PurchaseManager.configure() before runApp(), then use
//      await PurchaseManager.getInitialPremiumStatus() for initialPremium in
//      place of the cached premiumKey read
//   2. settings.dart: restore the whole lock tap flow. What is there now,
//      logLockTap(), only logs unlockBlocked, so all of this has to come back:
//        - PurchaseManager.fetchPrice() feeding CommonWidget.upgradeAlert()
//        - AnalyticsManager.upgradeOffered(feature) once the alert is shown
//        - context.popPage() to close the alert before the purchase starts
//        - isLoadingData true/false around the purchase, so the spinner shows
//        - the result messages: premiumThanks() on success,
//          premiumRestoreFailed() when a restore grants nothing, and
//          premiumFailed() on error. Leave these out and the purchase UI
//          reports neither success nor failure
//        - context.mounted checks after each await that is followed by UI work
//        - PlanNotifier.setCurrentPlan() with the buyPremium() result
//      Both lock entry points route through onLockTap: settingsLockContainer()
//      and the alertLockWidget() inside the photo picker dialog. Restoring the
//      handler covers both
//   3. Nothing else was touched: upgradeAlert() in common_widget.dart, the
//      premium strings in l10n, AnalyticsManager.upgrade* and the PlanState
//      fields are all still in place
// =============================

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

class PurchaseManager {

  /// Guards against a second purchase flow while one is still running
  static bool _isPurchasing = false;

  // --- Setup ---

  /// Starts the store SDK. Every other call here needs this to have run first:
  /// calling any Purchases API before configure() throws
  static Future<void> configure() async {
    final apiKey = dotenv.maybeGet(revenueCatApiKey);
    if (apiKey == null || apiKey.isEmpty) return;
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug: LogLevel.warn);
    await Purchases.configure(PurchasesConfiguration(apiKey));
    if (Platform.isIOS || Platform.isMacOS) {
      await Purchases.enableAdServicesAttributionTokenCollection();
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

  /// Returns the premium status for app startup (used from main() before ProviderScope)
  /// Falls back to the locally cached value when the store is unreachable
  static Future<bool> getInitialPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedPremium = premiumKey.getSharedPrefBool(prefs, false);
    try {
      final CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      final bool isPremium = customerInfo.entitlements.active[premiumEntitlementID]?.isActive ?? false;
      premiumKey.setSharedPrefBool(prefs, isPremium);
      "initial isPremium: $isPremium".debugPrint();
      return isPremium;
    } catch (e) {
      "Error initializing premium status: $e".debugPrint();
      return cachedPremium;
    }
  }

  /// Writes the entitlement to the local cache so the next launch can read it
  static Future<void> _cachePremium(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    premiumKey.setSharedPrefBool(prefs, isPremium);
  }

  /// Fetches the localized price of the premium package for display
  /// Returns null when offerings are unavailable, so the caller keeps its value
  static Future<String?> fetchPrice() async {
    try {
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

  /// Fetches available offerings and initiates purchase
  /// Throws exception on error for UI to handle
  static Future<bool> _purchasePremium() async {
    try {
      final Offerings offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        throw Exception("No offerings available");
      }
      final package = _premiumPackage(offerings);
      if (package == null) {
        throw Exception("No premium package available");
      }
      final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
      final isPremium = purchaseResult.customerInfo.entitlements.active[premiumEntitlementID]?.isActive ?? false;
      "purchased isPremium: $isPremium".debugPrint();
      return isPremium;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      throw Exception("Purchase Error: $errorCode");
    }
  }

  /// Restores previous purchases from the app store
  /// Returns the premium status carried by the restored entitlements
  static Future<bool> _restorePremium() async {
    try {
      final restoredInfo = await Purchases.restorePurchases();
      final isPremium = restoredInfo.entitlements.active[premiumEntitlementID]?.isActive ?? false;
      "restored isPremium: $isPremium".debugPrint();
      return isPremium;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      throw Exception("Restore Error: $errorCode");
    }
  }

  /// Main purchase/restore function for the UI to call
  /// Returns true when the user ends up with the premium entitlement
  /// Throws on failure so the UI can show a message; cancellation returns false
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
      await _cachePremium(isPremium);
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

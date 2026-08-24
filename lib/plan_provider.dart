// =============================
// PlanProvider: premium entitlement state via RevenueCat
//
// The premium entitlement removes ads and unlocks every customization
// without touching the EV mile balance, so Game Center rankings stay intact.
// Key features:
// - Startup entitlement resolution with local cache fallback
// - Purchase and restore flows
// - Purchasing state for UI loading indicators
// =============================

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_manager.dart';
import 'constant.dart';
import 'extension.dart';

/// Provider for managing premium plan state across the app
final planProvider = NotifierProvider<PlanNotifier, PlanState>(PlanNotifier.new);

/// SharedPreferences key holding the cached entitlement status
const String premiumKey = "premiumKey";

/// Picks the package to sell: the lifetime one, otherwise the first available
Package? _premiumPackage(Offerings offerings) {
  final current = offerings.current;
  if (current == null) return null;
  if (current.lifetime != null) return current.lifetime;
  return current.availablePackages.isNotEmpty ? current.availablePackages.first: null;
}

/// Returns the initial premium status for app startup (used from main() before ProviderScope).
/// Falls back to the locally cached value when RevenueCat is unreachable.
Future<bool> getInitialPremiumStatus() async {
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

/// Immutable state class for premium plan information
@immutable
class PlanState {
  /// Whether the user has premium access
  final bool isPremium;
  /// Whether a purchase/restore operation is currently in progress
  final bool isPurchasing;
  /// Localized price string of the premium package, empty until offerings load
  final String priceString;

  const PlanState({
    this.isPremium = false,
    this.isPurchasing = false,
    this.priceString = "",
  });

  PlanState copyWith({bool? isPremium, bool? isPurchasing, String? priceString}) => PlanState(
    isPremium: isPremium ?? this.isPremium,
    isPurchasing: isPurchasing ?? this.isPurchasing,
    priceString: priceString ?? this.priceString,
  );
}

/// Notifier for managing premium plan state and purchase operations
class PlanNotifier extends Notifier<PlanState> {
  final PlanState? _initial;

  PlanNotifier([this._initial]);

  @override
  PlanState build() => _initial ?? const PlanState();

  /// Updates the current premium plan status and caches it locally
  Future<void> setCurrentPlan(bool isPremium) async {
    state = state.copyWith(isPremium: isPremium);
    final prefs = await SharedPreferences.getInstance();
    premiumKey.setSharedPrefBool(prefs, isPremium);
  }

  /// Updates the purchasing state (loading indicator)
  void setPurchasing(bool isPurchasing) {
    state = state.copyWith(isPurchasing: isPurchasing);
  }

  /// Fetches the localized price of the premium package for display
  /// Silently keeps the previous value when offerings are unavailable
  Future<void> fetchPrice() async {
    try {
      final Offerings offerings = await Purchases.getOfferings();
      final package = _premiumPackage(offerings);
      if (package != null) {
        state = state.copyWith(priceString: package.storeProduct.priceString);
        "premium price: ${package.storeProduct.priceString}".debugPrint();
      }
    } catch (e) {
      "Error fetching offerings: $e".debugPrint();
    }
  }

  /// Fetches available offerings and initiates purchase
  /// Throws exception on error for UI to handle
  Future<void> _purchasePremium() async {
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
      await setCurrentPlan(isPremium);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      throw Exception("Purchase Error: $errorCode");
    }
  }

  /// Restores previous purchases from the app store
  /// Updates premium status based on restored entitlements
  Future<void> _restorePremium() async {
    try {
      final restoredInfo = await Purchases.restorePurchases();
      final isPremium = restoredInfo.entitlements.active[premiumEntitlementID]?.isActive ?? false;
      "restored isPremium: $isPremium".debugPrint();
      await setCurrentPlan(isPremium);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      throw Exception("Restore Error: $errorCode");
    }
  }

  /// Main purchase/restore function called from UI
  /// Returns true when the user ends up with the premium entitlement
  /// Throws on failure so the UI can show a message; cancellation returns false
  Future<bool> buyPremium({required bool isRestore, required String source}) async {
    if (state.isPurchasing) return state.isPremium;
    setPurchasing(true);
    try {
      if (isRestore) {
        await _restorePremium();
        await AnalyticsManager.upgradeRestored(state.isPremium);
      } else {
        await AnalyticsManager.upgradeStarted(source);
        await _purchasePremium();
        if (state.isPremium) await AnalyticsManager.upgradePurchased(source);
      }
      setPurchasing(false);
      return state.isPremium;
    } catch (e) {
      "Purchase flow error: $e".debugPrint();
      setPurchasing(false);
      if (e is PlatformException) {
        final errorCode = PurchasesErrorHelper.getErrorCode(e);
        // A user-initiated cancel is not an error worth surfacing
        if (errorCode == PurchasesErrorCode.purchaseCancelledError) return false;
      }
      rethrow;
    }
  }
}

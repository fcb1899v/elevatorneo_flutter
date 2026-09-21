import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/constant.dart';
import 'package:letselevatorneo/purchase_manager.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// A CustomerInfo whose active entitlements are exactly [activeIds]
CustomerInfo _customerWith(List<String> activeIds, {bool isActive = true}) {
  final entitlements = {
    for (final id in activeIds)
      id: EntitlementInfo(id, isActive, false, "2026-09-15T00:00:00Z",
        "2026-09-15T00:00:00Z", "premium_product", true),
  };
  return CustomerInfo(EntitlementInfos(entitlements, entitlements),
    const {}, const [], const ["premium_product"], const [],
    "2026-09-15T00:00:00Z", "test_user", const {}, "2026-09-15T00:00:00Z");
}

void main() {
  test("entitlement id is the one attached in RevenueCat", () {
    expect(premiumEntitlementID, "elevatorneo_premium");
  });

  test("elevatorneo_premium active: premium", () {
    expect(PurchaseManager.isPremiumIn(_customerWith(["elevatorneo_premium"])), isTrue);
  });

  test("only another app's premium entitlement: not premium", () {
    expect(PurchaseManager.isPremiumIn(_customerWith(["premium"])), isFalse);
    expect(PurchaseManager.isPremiumIn(_customerWith(["letselevator_premium"])), isFalse);
  });

  test("no entitlement, or an inactive one: not premium", () {
    expect(PurchaseManager.isPremiumIn(_customerWith([])), isFalse);
    expect(PurchaseManager.isPremiumIn(
      _customerWith(["elevatorneo_premium"], isActive: false)), isFalse);
  });
}

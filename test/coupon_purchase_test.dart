import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/constant.dart';
import 'package:letselevatorneo/plan_provider.dart';
import 'package:letselevatorneo/purchase_manager.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  group("handleCustomerInfo", () {
    late int granted;

    setUp(() {
      SharedPreferences.setMockInitialValues({premiumKey: false});
      granted = 0;
      PurchaseManager.onPremiumGranted = () => granted++;
    });

    tearDown(() => PurchaseManager.onPremiumGranted = null);

    Future<bool> stored() async =>
      (await SharedPreferences.getInstance()).getBool(premiumKey) ?? false;

    test("an active premium entitlement caches premium and calls onPremiumGranted", () async {
      await PurchaseManager.handleCustomerInfo(_customerWith([premiumEntitlementID]));
      expect(granted, 1);
      expect(await stored(), isTrue);
    });

    test("a customer without the premium entitlement changes nothing", () async {
      await PurchaseManager.handleCustomerInfo(_customerWith([]));
      expect(granted, 0);
      expect(await stored(), isFalse);
    });

    test("an inactive premium entitlement changes nothing", () async {
      await PurchaseManager.handleCustomerInfo(
        _customerWith([premiumEntitlementID], isActive: false));
      expect(granted, 0);
      expect(await stored(), isFalse);
    });

    test("no onPremiumGranted set: premium is still cached without a crash", () async {
      PurchaseManager.onPremiumGranted = null;
      await PurchaseManager.handleCustomerInfo(_customerWith([premiumEntitlementID]));
      expect(await stored(), isTrue);
    });
  });
}

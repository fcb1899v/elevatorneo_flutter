import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

  group("dropRevokedPremium", () {
    Future<ProviderContainer> launch(bool savedPremium) async {
      SharedPreferences.setMockInitialValues({"premiumKey": savedPremium});
      final container = ProviderContainer(overrides: [
        planProvider.overrideWith(() => PlanNotifier(PlanState(isPremium: savedPremium))),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    Future<bool> stored() async =>
      (await SharedPreferences.getInstance()).getBool("premiumKey") ?? false;

    final realSource = PurchaseManager.customerInfoSource;
    tearDown(() => PurchaseManager.customerInfoSource = realSource);

    test("no active entitlement resets a stored purchase", () async {
      final container = await launch(true);
      PurchaseManager.customerInfoSource = () async => _customerWith([]);
      await PurchaseManager.dropRevokedPremium(
        container.read(planProvider).isPremium, () => container.read(planProvider.notifier).setCurrentPlan(false));
      expect(container.read(planProvider).isPremium, isFalse);
      expect(await stored(), isFalse);
    });

    test("an active entitlement keeps premium", () async {
      final container = await launch(true);
      PurchaseManager.customerInfoSource = () async => _customerWith(["elevatorneo_premium"]);
      await PurchaseManager.dropRevokedPremium(
        container.read(planProvider).isPremium, () => container.read(planProvider.notifier).setCurrentPlan(false));
      expect(container.read(planProvider).isPremium, isTrue);
      expect(await stored(), isTrue);
    });

    test("an unreachable RevenueCat keeps a stored purchase", () async {
      final container = await launch(true);
      PurchaseManager.customerInfoSource = () async => throw Exception("offline");
      await PurchaseManager.dropRevokedPremium(
        container.read(planProvider).isPremium, () => container.read(planProvider.notifier).setCurrentPlan(false));
      expect(container.read(planProvider).isPremium, isTrue);
      expect(await stored(), isTrue);
    });

    test("a build without an API key keeps a stored purchase", () async {
      final container = await launch(true);
      await PurchaseManager.dropRevokedPremium(
        container.read(planProvider).isPremium,
        () => container.read(planProvider.notifier).setCurrentPlan(false));
      expect(container.read(planProvider).isPremium, isTrue);
      expect(await stored(), isTrue);
    });

    test("a free launch never asks RevenueCat", () async {
      final container = await launch(false);
      var asked = false;
      PurchaseManager.customerInfoSource = () async { asked = true; return _customerWith(["elevatorneo_premium"]); };
      await PurchaseManager.dropRevokedPremium(
        container.read(planProvider).isPremium, () => container.read(planProvider.notifier).setCurrentPlan(false));
      expect(asked, isFalse);
      expect(container.read(planProvider).isPremium, isFalse);
    });
  });

  group("restoreOwnedPremium", () {
    Future<ProviderContainer> launch(bool savedPremium) async {
      SharedPreferences.setMockInitialValues({"premiumKey": savedPremium});
      final container = ProviderContainer(overrides: [
        planProvider.overrideWith(() => PlanNotifier(PlanState(isPremium: savedPremium))),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    Future<bool> stored() async =>
      (await SharedPreferences.getInstance()).getBool("premiumKey") ?? false;

    Future<void> run(ProviderContainer c) => PurchaseManager.restoreOwnedPremium(
      c.read(planProvider).isPremium, () => c.read(planProvider.notifier).setCurrentPlan(true));

    final realSource = PurchaseManager.customerInfoSource;
    tearDown(() => PurchaseManager.customerInfoSource = realSource);

    test("an owned entitlement on a free device grants premium", () async {
      final container = await launch(false);
      PurchaseManager.customerInfoSource = () async => _customerWith(["elevatorneo_premium"]);
      await run(container);
      expect(container.read(planProvider).isPremium, isTrue);
      expect(await stored(), isTrue);
    });

    test("no entitlement keeps the app free", () async {
      final container = await launch(false);
      PurchaseManager.customerInfoSource = () async => _customerWith([]);
      await run(container);
      expect(container.read(planProvider).isPremium, isFalse);
      expect(await stored(), isFalse);
    });

    test("an unreachable RevenueCat keeps the app free", () async {
      final container = await launch(false);
      PurchaseManager.customerInfoSource = () async => throw Exception("offline");
      await run(container);
      expect(container.read(planProvider).isPremium, isFalse);
    });

    test("a premium device never asks RevenueCat", () async {
      final container = await launch(true);
      var asked = false;
      PurchaseManager.customerInfoSource = () async { asked = true; return _customerWith([]); };
      await run(container);
      expect(asked, isFalse);
      expect(container.read(planProvider).isPremium, isTrue);
    });
  });
}

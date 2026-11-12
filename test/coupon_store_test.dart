// The coupon purchase in PurchaseManager: the coupon id is tagged first, the offering "coupon" is sold, and premium is granted once.
// The store is a fake behind the RevenueCat channel, so the real buyPremium and the real customer info listener are used.

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/constant.dart';
import 'package:letselevatorneo/plan_provider.dart';
import 'package:letselevatorneo/purchase_manager.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = MethodChannel('purchases_flutter');
const _price = "¥500";

/// The state of the fake store for one test
late List<MethodCall> _calls;
late bool _configured;
Object? _attributesError;
late Map<String, dynamic> _offerings;
int _granted = 0;

/// A customer whose premium entitlement is active
Map<String, dynamic> _customer() {
  final entitlement = {
    'identifier': premiumEntitlementID,
    'isActive': true,
    'willRenew': false,
    'latestPurchaseDate': '2026-10-01T00:00:00Z',
    'originalPurchaseDate': '2026-10-01T00:00:00Z',
    'productIdentifier': 'premium_product',
    'isSandbox': true,
    'ownershipType': 'PURCHASED',
    'store': 'PLAY_STORE',
    'periodType': 'NORMAL',
    'verification': 'NOT_REQUESTED',
  };
  final active = {premiumEntitlementID: entitlement};
  return {
    'entitlements': {'all': active, 'active': active, 'verification': 'NOT_REQUESTED'},
    'allPurchaseDates': <String, dynamic>{},
    'activeSubscriptions': <String>[],
    'allPurchasedProductIdentifiers': <String>[],
    'nonSubscriptionTransactions': <dynamic>[],
    'firstSeen': '2026-10-01T00:00:00Z',
    'originalAppUserId': 'test_user',
    'allExpirationDates': <String, dynamic>{},
    'requestDate': '2026-10-01T00:00:00Z',
  };
}

/// A package with [id], sold in the offering [offeringId]
Map<String, dynamic> _package(String id, String offeringId) => {
  'identifier': id,
  'packageType': 'CUSTOM',
  'product': {
    'identifier': 'product_$id',
    'description': 'premium',
    'title': 'premium',
    'price': 500,
    'priceString': _price,
    'currencyCode': 'JPY',
  },
  'presentedOfferingContext': {
    'offeringIdentifier': offeringId,
    'placementIdentifier': null,
    'targetingContext': null,
  },
};

/// An offering [id] holding one package
Map<String, dynamic> _offering(String id, String packageId) => {
  'identifier': id,
  'serverDescription': id,
  'metadata': <String, dynamic>{},
  'availablePackages': [_package(packageId, id)],
};

/// The store's offerings: "default" is current, and "coupon" exists only when [withCoupon]
Map<String, dynamic> _offeringsJson({required bool withCoupon}) => {
  'all': {
    'default': _offering('default', 'default_pkg'),
    if (withCoupon) 'coupon': _offering('coupon', 'coupon_pkg'),
  },
  'current': _offering('default', 'default_pkg'),
};

void _storeAnswers() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (call) async {
    _calls.add(call);
    switch (call.method) {
      case 'isConfigured':
        return _configured;
      case 'setupPurchases':
        _configured = true;
        return null;
      case 'getOfferings':
        return _offerings;
      case 'setAttributes':
        if (_attributesError != null) throw _attributesError!;
        return null;
      case 'purchasePackage':
        return {
          'customerInfo': _customer(),
          'transaction': {
            'transactionIdentifier': 'tx_1',
            'productIdentifier': 'product_coupon_pkg',
            'purchaseDate': '2026-10-01T00:00:00Z',
          },
        };
      case 'getCustomerInfo':
        return _customer();
      default:
        return null;
    }
  });
}

/// Delivers a customer info update from the store, the way the SDK receives it
Future<void> _sendCustomerInfoUpdate(Map<String, dynamic> info) async {
  final data = const StandardMethodCodec().encodeMethodCall(MethodCall('Purchases-CustomerInfoUpdated', info));
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(_channel.name, data, (_) {});
}

List<String> _methods() => _calls.map((c) => c.method).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(envString: "$revenueCatApiKey=test_key");
    PurchaseManager.resetStore();
    _calls = [];
    _configured = true;
    _attributesError = null;
    _offerings = _offeringsJson(withCoupon: true);
    _granted = 0;
    _storeAnswers();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_channel, null);
    Purchases.removeCustomerInfoUpdateListener(PurchaseManager.handleCustomerInfo);
    PurchaseManager.onPremiumGranted = null;
    PurchaseManager.resetStore();
  });

  group("coupon purchase", () {
    test("the coupon id is tagged on the purchase before the purchase starts", () async {
      final bought = await PurchaseManager.buyPremium(isRestore: false, source: "coupon", couponId: "x");
      expect(bought, isTrue);
      final tag = _calls.firstWhere((c) => c.method == "setAttributes");
      expect(tag.arguments, {"attributes": {"coupon_id": "x"}});
      expect(_methods().indexOf("setAttributes"), lessThan(_methods().indexOf("purchasePackage")));
    });

    test("the package bought comes from the offering coupon, not the current offering", () async {
      await PurchaseManager.buyPremium(isRestore: false, source: "coupon", couponId: "x");
      final purchase = _calls.firstWhere((c) => c.method == "purchasePackage");
      expect(purchase.arguments["packageIdentifier"], "coupon_pkg");
      expect(PurchaseManager.couponOfferingId, "coupon");
    });

    test("a failing coupon tag does not stop the purchase", () async {
      _attributesError = PlatformException(code: "1", message: "attributes failed");
      final bought = await PurchaseManager.buyPremium(isRestore: false, source: "coupon", couponId: "x");
      expect(bought, isTrue);
      expect(_methods(), contains("purchasePackage"));
    });

    test("without the offering coupon the purchase throws StoreUnavailableException", () async {
      _offerings = _offeringsJson(withCoupon: false);
      await expectLater(
        PurchaseManager.buyPremium(isRestore: false, source: "coupon", couponId: "x"),
        throwsA(isA<StoreUnavailableException>()),
      );
      expect(_methods(), isNot(contains("purchasePackage")));
    });
  });

  test("a customer info update with premium calls onPremiumGranted once, even after configuring twice", () async {
    _configured = false;
    PurchaseManager.onPremiumGranted = () => _granted++;
    // The first attempt configures the SDK and adds the listener once.
    await PurchaseManager.customerInfoSource();
    // The second attempt, after resetStore, finds the SDK configured and must not add the listener again.
    PurchaseManager.resetStore();
    await PurchaseManager.customerInfoSource();
    expect(_methods().where((m) => m == "setupPurchases").length, 1);
    expect(_granted, 0);

    await _sendCustomerInfoUpdate(_customer());
    for (var i = 0; i < 100 && _granted == 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    // A short extra wait so a second delivery would show up before the count is checked.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(_granted, 1);
    expect((await SharedPreferences.getInstance()).getBool(premiumKey), isTrue);
  });
}

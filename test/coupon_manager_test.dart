import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/coupon_manager.dart';

// Test-only code; its hash is computed by `shasum -a 256` separately.
const _code = "ABCD2345EFGH";
const _hash = "051b058e42b48b1287414506ce03203567d8505b82b28e0b4d7906f43cde8114";

/// A config with one entry for [_code], expiring on [expires]
String _config({String sha = _hash, String expires = "2026-10-30"}) => jsonEncode({
  "codes": [
    {"id": "coupon_001", "sha256": sha, "expires": expires},
  ],
});

void main() {
  // Captured when main() starts, before any test replaces them.
  final originalConfigSource = CouponManager.configSource;
  final originalPlatformSource = CouponManager.platformSource;
  final originalOsVersionSource = CouponManager.osVersionSource;
  final originalUrlLauncher = CouponManager.urlLauncher;
  final originalRemoteFetchSource = CouponManager.remoteFetchSource;
  final originalRemoteReadSource = CouponManager.remoteReadSource;

  tearDown(() {
    CouponManager.configSource = originalConfigSource;
    CouponManager.platformSource = originalPlatformSource;
    CouponManager.osVersionSource = originalOsVersionSource;
    CouponManager.urlLauncher = originalUrlLauncher;
    CouponManager.remoteFetchSource = originalRemoteFetchSource;
    CouponManager.remoteReadSource = originalRemoteReadSource;
  });

  group("hashOf and normalize", () {
    test("hashOf matches the shasum value", () {
      expect(CouponManager.hashOf(_code), _hash);
    });

    test("spaces, tabs, and newlines are removed and letters are upper-cased", () {
      expect(CouponManager.normalize(" abcd 2345\tefgh\n"), _code);
    });

    test("full-width letters and digits become half-width", () {
      expect(CouponManager.normalize("ＡＢＣＤ２３４５ＥＦＧＨ"), _code);
    });

    test("a full-width space is removed", () {
      expect(CouponManager.normalize("ＡＢＣＤ　２３４５ＥＦＧＨ"), _code);
    });
  });

  group("match", () {
    final now = DateTime(2026, 10, 30, 12);

    test("the right code gives valid with its id", () {
      final result = CouponManager.match(_code, _config(), now);
      expect(result.result, CouponCheck.valid);
      expect(result.couponId, "coupon_001");
    });

    test("a different code gives invalid", () {
      final result = CouponManager.match("ABCD2345EFGJ", _config(), now);
      expect(result.result, CouponCheck.invalid);
      expect(result.couponId, isNull);
    });

    test("the day after expiry gives invalid", () {
      final result = CouponManager.match(_code, _config(), DateTime(2026, 10, 31, 0, 0));
      expect(result.result, CouponCheck.invalid);
    });

    test("23:59 on the expiry day gives valid", () {
      final result = CouponManager.match(_code, _config(), DateTime(2026, 10, 30, 23, 59));
      expect(result.result, CouponCheck.valid);
    });

    test("an upper-case sha256 in the config still matches", () {
      final upper = _config(sha: _hash.toUpperCase());
      expect(CouponManager.match(_code, upper, now).result, CouponCheck.valid);
    });

    test("broken JSON gives invalid", () {
      expect(CouponManager.match(_code, "{", now).result, CouponCheck.invalid);
    });

    test("an empty config gives invalid", () {
      expect(CouponManager.match(_code, "", now).result, CouponCheck.invalid);
    });

    test("codes that is not a list gives invalid", () {
      expect(CouponManager.match(_code, '{"codes":5}', now).result, CouponCheck.invalid);
    });

    test("an entry with an impossible date is skipped", () {
      final result = CouponManager.match(_code, _config(expires: "2026-13-01"), now);
      expect(result.result, CouponCheck.invalid);
    });

    test("an entry with a broken date is skipped, and a later correct entry still matches", () {
      final config = jsonEncode({
        "codes": [
          {"id": "broken", "sha256": _hash, "expires": "2026/10/30"},
          {"id": "coupon_002", "sha256": _hash, "expires": "2026-10-30"},
        ],
      });
      final result = CouponManager.match(_code, config, now);
      expect(result.result, CouponCheck.valid);
      expect(result.couponId, "coupon_002");
    });

    test("an expired entry before a valid entry with the same hash does not stop the match", () {
      final config = jsonEncode({
        "codes": [
          {"id": "expired", "sha256": _hash, "expires": "2026-10-29"},
          {"id": "coupon_002", "sha256": _hash, "expires": "2026-10-31"},
        ],
      });
      final result = CouponManager.match(_code, config, now);
      expect(result.result, CouponCheck.valid);
      expect(result.couponId, "coupon_002");
    });

    test("an empty code gives invalid", () {
      expect(CouponManager.match("", _config(), now).result, CouponCheck.invalid);
      expect(CouponManager.match(" 　 ", _config(), now).result, CouponCheck.invalid);
    });

    test("typed variants are normalized and still match", () {
      for (final typed in [" abcd 2345\tefgh\n", "ＡＢＣＤ　２３４５ＥＦＧＨ", "abcd2345efgh"]) {
        final result = CouponManager.match(typed, _config(), now);
        expect(result.result, CouponCheck.valid, reason: typed);
        expect(result.couponId, "coupon_001", reason: typed);
      }
    });
  });

  group("check", () {
    test("a null config gives unavailable", () async {
      CouponManager.configSource = () async => null;
      expect((await CouponManager.check(_code)).result, CouponCheck.unavailable);
    });

    test("an empty config gives invalid", () async {
      CouponManager.configSource = () async => "";
      expect((await CouponManager.check(_code)).result, CouponCheck.invalid);
    });

    test("a correct config gives valid", () async {
      CouponManager.configSource = () async => _config(expires: "2999-12-31");
      final result = await CouponManager.check(_code);
      expect(result.result, CouponCheck.valid);
      expect(result.couponId, "coupon_001");
    });
  });

  group("the default configSource", () {
    test("a successful fetch returns the value read", () async {
      CouponManager.remoteFetchSource = () async {};
      CouponManager.remoteReadSource = () => "fresh";
      expect(await CouponManager.configSource(), "fresh");
    });

    test("a successful fetch with an empty value returns an empty string, and check gives invalid", () async {
      CouponManager.remoteFetchSource = () async {};
      CouponManager.remoteReadSource = () => "";
      expect(await CouponManager.configSource(), "");
      expect((await CouponManager.check(_code)).result, CouponCheck.invalid);
    });

    test("a failed fetch returns the previous value when it is not empty", () async {
      CouponManager.remoteFetchSource = () async => throw Exception("offline");
      CouponManager.remoteReadSource = () => "previous";
      expect(await CouponManager.configSource(), "previous");
    });

    test("a failed fetch with an empty previous value returns null, and check gives unavailable", () async {
      CouponManager.remoteFetchSource = () async => throw Exception("offline");
      CouponManager.remoteReadSource = () => "";
      expect(await CouponManager.configSource(), isNull);
      expect((await CouponManager.check(_code)).result, CouponCheck.unavailable);
    });

    test("a failed fetch and a failed read return null", () async {
      CouponManager.remoteFetchSource = () async => throw Exception("offline");
      CouponManager.remoteReadSource = () => throw Exception("unreadable");
      expect(await CouponManager.configSource(), isNull);
    });
  });

  group("openRedeem", () {
    test("opens the redeem URL and returns the launcher result", () async {
      final opened = <Uri>[];
      for (final launched in [true, false]) {
        CouponManager.urlLauncher = (uri) async {
          opened.add(uri);
          return launched;
        };
        expect(await CouponManager.openRedeem(), launched);
      }
      expect(opened, [CouponManager.redeemUrl, CouponManager.redeemUrl]);
    });

    test("a launcher that throws gives false", () async {
      CouponManager.urlLauncher = (uri) async => throw Exception("cannot open");
      expect(await CouponManager.openRedeem(), isFalse);
    });
  });

  group("supportsIosOfferCode", () {
    test("reads the version from the iOS version string", () {
      // The simulator's real value (iPhone 17 Pro, iOS 26.3.1).
      expect(CouponManager.supportsIosOfferCode("Version 26.3.1 (Build 23D8133)"), isTrue);
      expect(CouponManager.supportsIosOfferCode("Version 16.3 (Build 20D47)"), isTrue);
      expect(CouponManager.supportsIosOfferCode("Version 16.2.1 (Build 20C80)"), isFalse);
      expect(CouponManager.supportsIosOfferCode("Version 15.8 (Build 19H370)"), isFalse);
      expect(CouponManager.supportsIosOfferCode("Version 17.0 (Build 21A329)"), isTrue);
      expect(CouponManager.supportsIosOfferCode("unknown"), isFalse);
    });
  });

  group("isEntryAvailable", () {
    test("Android is available", () {
      CouponManager.platformSource = () => "android";
      expect(CouponManager.isEntryAvailable(), isTrue);
    });

    test("iOS 16.3 is available", () {
      CouponManager.platformSource = () => "ios";
      CouponManager.osVersionSource = () => "Version 16.3 (Build 20D47)";
      expect(CouponManager.isEntryAvailable(), isTrue);
    });

    test("iOS 15.8 is not available", () {
      CouponManager.platformSource = () => "ios";
      CouponManager.osVersionSource = () => "Version 15.8 (Build 19H370)";
      expect(CouponManager.isEntryAvailable(), isFalse);
    });

    test("macOS is not available", () {
      CouponManager.platformSource = () => "macos";
      expect(CouponManager.isEntryAvailable(), isFalse);
    });
  });
}

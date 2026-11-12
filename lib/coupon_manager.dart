// ===== CouponManager: discount code check against hashed codes in Remote Config =====
// Codes are compared as SHA-256 on the device, so the config holds hashes, never codes.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'analytics_manager.dart';
import 'extension.dart';
import 'remote_config_setup.dart';

/// The outcome of checking a typed code
enum CouponCheck { valid, invalid, unavailable }

/// The check result; [couponId] is set only when the result is valid
class CouponMatch {
  final CouponCheck result;
  final String? couponId;
  const CouponMatch(this.result, [this.couponId]);
}

class CouponManager {

  /// Remote Config key that holds the hashed code list as JSON
  static const configKey = "coupon_codes";

  /// App Store redeem page for offer codes; the code is typed by the user there
  static final Uri redeemUrl = Uri.parse("https://apps.apple.com/redeem?ctx=offercodes&id=6479341144");

  /// Reads the config text; null means it cannot be read.
  /// Tests replace it.
  @visibleForTesting
  static Future<String?> Function() configSource = _fetchConfig;

  /// Opens a URL outside the app.
  /// Tests replace it.
  @visibleForTesting
  static Future<bool> Function(Uri) urlLauncher =
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

  /// Returns the platform name.
  /// Tests replace it.
  @visibleForTesting
  static String Function() platformSource = () => Platform.operatingSystem;

  /// Returns the OS version string.
  /// Tests replace it.
  @visibleForTesting
  static String Function() osVersionSource = () => Platform.operatingSystemVersion;

  /// Converts full-width ASCII, drops all spaces, and upper-cases the code
  static String normalize(String code) {
    final halfWidth = String.fromCharCodes(
      code.runes.map((r) => r >= 0xFF01 && r <= 0xFF5E ? r - 0xFEE0 : r),
    );
    return halfWidth.replaceAll(RegExp(r"\s"), "").toUpperCase();
  }

  /// SHA-256 of the normalized code, as lowercase hex
  static String hashOf(String code) =>
      sha256.convert(utf8.encode(normalize(code))).toString();

  /// Finds the code in the config; a broken entry is skipped
  static CouponMatch match(String code, String config, DateTime now) {
    final normalized = normalize(code);
    if (normalized.isEmpty || config.isEmpty) return const CouponMatch(CouponCheck.invalid);
    final hash = hashOf(code);
    final today = DateTime(now.year, now.month, now.day);
    final decoded = _decode(config);
    if (decoded is! Map || decoded["codes"] is! List) {
      return const CouponMatch(CouponCheck.invalid);
    }
    for (final entry in decoded["codes"] as List) {
      if (entry is! Map) continue;
      final sha = entry["sha256"];
      final id = entry["id"];
      final expires = entry["expires"];
      if (sha is! String || id is! String || expires is! String) continue;
      if (sha.toLowerCase() != hash) continue;
      final expiry = _parseDate(expires);
      if (expiry == null || id.isEmpty) continue;
      if (!today.isAfter(expiry)) return CouponMatch(CouponCheck.valid, id);
    }
    return const CouponMatch(CouponCheck.invalid);
  }

  /// Decodes the config JSON; returns null when it is not valid JSON
  static Object? _decode(String config) {
    try {
      return jsonDecode(config);
    } catch (_) {
      return null;
    }
  }

  /// Reads a YYYY-MM-DD string; returns null for any other shape or an impossible date
  static DateTime? _parseDate(String text) {
    final m = RegExp(r"^(\d{4})-(\d{2})-(\d{2})$").firstMatch(text);
    if (m == null) return null;
    final year = int.parse(m.group(1)!);
    final month = int.parse(m.group(2)!);
    final day = int.parse(m.group(3)!);
    final date = DateTime(year, month, day);
    if (date.month != month || date.day != day) return null;
    return date;
  }

  /// Fetches the config from Remote Config.
  /// Tests replace it.
  @visibleForTesting
  static Future<void> Function() remoteFetchSource = _fetchRemoteConfig;

  /// Reads the config text already held by Remote Config.
  /// Tests replace it.
  @visibleForTesting
  static String Function() remoteReadSource =
      () => FirebaseRemoteConfig.instance.getString(configKey);

  static Future<void> _fetchRemoteConfig() async {
    await ensureRemoteConfigReady();
    await FirebaseRemoteConfig.instance.fetchAndActivate();
  }

  /// Fetches the config from Remote Config; on failure, falls back to the last value
  static Future<String?> _fetchConfig() async {
    try {
      await remoteFetchSource();
      return remoteReadSource();
    } catch (e) {
      "Coupon config fetch failed: $e".debugPrint();
      return _readCachedConfig();
    }
  }

  /// Reads the value already on the device; null when empty or unreadable
  static String? _readCachedConfig() {
    try {
      final cached = remoteReadSource();
      return cached.isEmpty ? null : cached;
    } catch (_) {
      return null;
    }
  }

  /// Checks a typed code and logs the result without waiting for the log
  static Future<CouponMatch> check(String code) async {
    final config = await configSource();
    final CouponMatch result;
    if (config == null) {
      result = const CouponMatch(CouponCheck.unavailable);
    } else {
      result = match(code, config, DateTime.now());
    }
    unawaited(AnalyticsManager.couponCodeChecked(result.result.name));
    return result;
  }

  /// Opens the App Store offer code page; a failure returns false
  static Future<bool> openRedeem() async {
    try {
      return await urlLauncher(redeemUrl);
    } catch (e) {
      "Coupon redeem open failed: $e".debugPrint();
      return false;
    }
  }

  /// Whether the iOS version can redeem a one-time offer code (16.3 or later)
  static bool supportsIosOfferCode(String osVersion) {
    final m = RegExp(r"(\d+)\.(\d+)").firstMatch(osVersion);
    if (m == null) return false;
    final major = int.parse(m.group(1)!);
    final minor = int.parse(m.group(2)!);
    return major > 16 || (major == 16 && minor >= 3);
  }

  /// Whether this device can show the code entry: Android, or iOS 16.3 or later
  static bool isEntryAvailable() {
    final platform = platformSource();
    if (platform == "android") return true;
    if (platform == "ios") return supportsIosOfferCode(osVersionSource());
    return false;
  }
}

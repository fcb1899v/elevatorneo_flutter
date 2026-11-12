/// Opens the LETS ELEVATOR ADVENTURE store page for the cross-promo.
///
/// The first way is a native call (Google Play inline install on Android, StoreKit sheet on iOS).
/// When that fails, the second way opens the store URL outside the app.
library;

import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'promo_links.dart';

/// The result of opening the store page.
///
/// [openMethod] is `sheet` (iOS first way), `market` (Android first way) or `url` (second way).
/// It is null when [opened] is false.
class PromoOpenResult {
  const PromoOpenResult({required this.opened, required this.openMethod});

  final bool opened;
  final String? openMethod;
}

/// Calls back once when the user comes back from the store.
///
/// The iOS sheet reports `storeClosed`; the other ways return when the app is `resumed` again.
/// It removes itself after the first return.
class PromoStoreReturnWatcher with WidgetsBindingObserver {
  PromoStoreReturnWatcher({
    required this.onReturned,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Called with how long the user was away and the open method.
  final void Function(Duration away, String openMethod) onReturned;

  final DateTime Function() _clock;
  String? _openMethod;
  DateTime? _openedAt;
  DateTime? _leftAt;
  bool _armed = false;

  /// Starts watching after the store was opened with [openMethod].
  void start(String openMethod) {
    _openMethod = openMethod;
    _openedAt = _clock();
    _leftAt = null;
    if (_armed) return;
    _armed = true;
    WidgetsBinding.instance.addObserver(this);
    PromoStore.storeClosedListener = handleStoreClosed;
  }

  /// Stops watching without calling back.
  void stop() {
    if (!_armed) return;
    _armed = false;
    WidgetsBinding.instance.removeObserver(this);
    if (PromoStore.storeClosedListener == handleStoreClosed) {
      PromoStore.storeClosedListener = null;
    }
  }

  /// Handles the iOS sheet being closed.
  @visibleForTesting
  void handleStoreClosed() {
    if (!_armed || _openMethod != 'sheet') return;
    _finish(_clock().difference(_openedAt ?? _clock()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The iOS sheet is judged by storeClosed only, not by lifecycle changes.
    if (!_armed || _openMethod == 'sheet') return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _leftAt ??= _clock();
      return;
    }
    if (state == AppLifecycleState.resumed && _leftAt != null) {
      _finish(_clock().difference(_leftAt!));
    }
  }

  void _finish(Duration away) {
    final method = _openMethod ?? 'url';
    stop();
    onReturned(away, method);
  }
}

/// Opens the store page and reports how it was opened.
class PromoStore {
  static const MethodChannel _channel = MethodChannel('nakajimamasao.appstudio/store_promo');

  static bool _handlerInstalled = false;

  static PromoStoreReturnWatcher? _currentWatcher;

  /// The App Store ID and provider token for the iOS sheet.
  /// Tests replace them.
  @visibleForTesting
  static String iosAppId = promoAdventureIosAppId;

  @visibleForTesting
  static String iosPt = promoAdventureIosPt;

  /// Set by [PromoStoreReturnWatcher] while the iOS sheet is open.
  @visibleForTesting
  static void Function()? storeClosedListener;

  /// Calls the native side with [method] and [arguments].
  /// Tests replace it.
  @visibleForTesting
  static Future<bool?> Function(String method, Map<String, Object?>? arguments) invokeNative =
      (method, arguments) => _channel.invokeMethod<bool>(method, arguments);

  /// Opens a URL outside the app.
  /// Tests replace it.
  @visibleForTesting
  static Future<bool> Function(Uri uri) urlLauncher =
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

  /// Returns true when the app for [uri] can be opened on this device.
  /// Tests replace it.
  @visibleForTesting
  static Future<bool> Function(Uri uri) canLaunch = (uri) => canLaunchUrl(uri);

  /// Returns the OS name, such as `android` or `ios`.
  /// Tests replace it.
  @visibleForTesting
  static String Function() platformSource = () => Platform.operatingSystem;

  /// Handles calls from the native side. Tests call it directly.
  @visibleForTesting
  static Future<dynamic> dispatchNativeCall(MethodCall call) async {
    if (call.method == 'storeClosed') storeClosedListener?.call();
    return null;
  }

  /// Returns true when ADVENTURE is installed on this device. Any failure gives false.
  static Future<bool> isAdventureInstalled() async {
    try {
      final platform = platformSource();
      if (platform == 'android') {
        return await invokeNative('isInstalled', null) ?? false;
      }
      if (platform == 'ios') {
        return await canLaunch(Uri.parse('nakajimamasao.appstudio.elevator3d://'));
      }
      return false;
    } on Exception {
      return false;
    }
  }

  /// Opens the ADVENTURE store page for [placement] (`menu` or `launch`).
  ///
  /// When [onReturned] is given, it is called once when the user comes back from the store.
  /// The caller should check whether it is still mounted before using the UI.
  static Future<PromoOpenResult> open({
    required String app,
    required String placement,
    void Function(Duration away, String openMethod)? onReturned,
  }) async {
    if (platformSource() == 'ios') {
      return _openIos(placement: placement, onReturned: onReturned);
    }
    return _openAndroid(app: app, placement: placement, onReturned: onReturned);
  }

  static Future<PromoOpenResult> _openAndroid({
    required String app,
    required String placement,
    void Function(Duration away, String openMethod)? onReturned,
  }) async {
    final inlineUrl = promoAndroidInlineInstallUrl(app: app, placement: placement);
    try {
      _ensureNativeHandler();
      final ok = await invokeNative('openPlay', {'url': inlineUrl}) ?? false;
      if (ok) return _opened('market', onReturned);
    } on Exception {
      // The first way failed; the second way is tried below.
    }
    final storeUrl = promoAndroidStoreUrl(app: app, placement: placement);
    return _openByUrl(Uri.parse(storeUrl), onReturned);
  }

  static Future<PromoOpenResult> _openIos({
    required String placement,
    void Function(Duration away, String openMethod)? onReturned,
  }) async {
    // The sheet needs both IDs; without them the native call would show an empty page.
    if (iosAppId.isNotEmpty && iosPt.isNotEmpty) {
      try {
        _ensureNativeHandler();
        final ok = await invokeNative('openAppStore', {
              'appId': iosAppId,
              'ct': promoIosCampaignToken(placement: placement),
              'pt': iosPt,
            }) ??
            false;
        if (ok) return _opened('sheet', onReturned);
      } on Exception {
        // The first way failed; the second way is tried below.
      }
    }
    final url = promoIosStoreUrl(placement: placement);
    if (url == null) return const PromoOpenResult(opened: false, openMethod: null);
    return _openByUrl(Uri.parse(url), onReturned);
  }

  static Future<PromoOpenResult> _openByUrl(
    Uri uri,
    void Function(Duration away, String openMethod)? onReturned,
  ) async {
    try {
      final ok = await urlLauncher(uri);
      if (ok) return _opened('url', onReturned);
    } on Exception {
      // Both ways failed.
    }
    return const PromoOpenResult(opened: false, openMethod: null);
  }

  static PromoOpenResult _opened(
    String method,
    void Function(Duration away, String openMethod)? onReturned,
  ) {
    // Only one watcher lives at a time, so one return reports once.
    _currentWatcher?.stop();
    _currentWatcher = null;
    if (onReturned != null) {
      _currentWatcher = PromoStoreReturnWatcher(onReturned: onReturned)..start(method);
    }
    return PromoOpenResult(opened: true, openMethod: method);
  }

  static void _ensureNativeHandler() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _channel.setMethodCallHandler(dispatchNativeCall);
  }
}

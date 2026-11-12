// Checks the launch steps of the cross-promo: the installed check, the first-find event and the platform switch.
// The native call, the platform and the analytics sender are replaced, so no store or Firebase call is made.

import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/analytics_manager.dart';
import 'package:letselevatorneo/promo/promo_prefs.dart';
import 'package:letselevatorneo/promo/promo_session.dart';
import 'package:letselevatorneo/promo/promo_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final originalSend = AnalyticsManager.send;
  final originalNative = PromoStore.invokeNative;
  final originalPlatform = PromoStore.platformSource;
  final events = <Map<String, Object?>>[];
  late bool installedAnswer;
  final nativeCalls = <String>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    events.clear();
    nativeCalls.clear();
    installedAnswer = false;
    AnalyticsManager.send = (name, parameters) async => events.add({"name": name, "params": parameters});
    PromoStore.invokeNative = (method, args) async {
      nativeCalls.add(method);
      return installedAnswer;
    };
    PromoStore.platformSource = () => 'android';
    PromoSession.reset();
    PromoSession.platformSource = () => 'android';
  });

  tearDown(() {
    PromoSession.reset();
    AnalyticsManager.send = originalSend;
    PromoStore.invokeNative = originalNative;
    PromoStore.platformSource = originalPlatform;
  });

  test('Android, not installed: the notice stays and no event is sent', () async {
    installedAnswer = false;
    await PromoSession.refreshInstalled();
    expect(PromoSession.adventureInstalled.value, isFalse);
    expect(events, isEmpty);
  });

  test('Android, installed: the flag is true and the first find is sent once', () async {
    installedAnswer = true;
    await PromoSession.refreshInstalled();
    expect(PromoSession.adventureInstalled.value, isTrue);
    expect(events, [
      {
        "name": "cross_promo_target_found",
        "params": {
          "target": "adventure",
          "tapped_before": 0,
          "last_placement": "none",
          "last_pattern": "none",
          "since_tap": "none",
          "is_premium": 0,
        },
      },
    ]);
    expect(await PromoPrefs.isAdventureFoundLogged(), isTrue);

    await PromoSession.refreshInstalled();
    expect(events.length, 1);
  });

  test('a tap before the find is reported with its placement, pattern and time', () async {
    await PromoPrefs.recordAdventureTap(placement: 'menu', pattern: 'p2');
    installedAnswer = true;
    await PromoSession.refreshInstalled();
    final params = events.single["params"] as Map<String, Object?>;
    expect(params["tapped_before"], 1);
    expect(params["last_placement"], 'menu');
    expect(params["last_pattern"], 'p2');
    expect(params["since_tap"], 'lt1h');
  });

  test('platformEnabled: iOS is off while the ID and token are empty', () {
    PromoStore.platformSource = () => 'ios';
    PromoSession.platformSource = () => 'ios';
    expect(PromoSession.platformEnabled(), isFalse);
  });

  test('platformEnabled: macOS is off', () {
    PromoStore.platformSource = () => 'macos';
    PromoSession.platformSource = () => 'macos';
    expect(PromoSession.platformEnabled(), isFalse);
  });

  test('platformEnabled: Android is on', () {
    PromoStore.platformSource = () => 'android';
    PromoSession.platformSource = () => 'android';
    expect(PromoSession.platformEnabled(), isTrue);
  });

  test('platformEnabled: platformOverride wins over the platform', () {
    PromoSession.platformSource = () => 'macos';
    PromoSession.platformOverride = () => true;
    expect(PromoSession.platformEnabled(), isTrue);
    PromoSession.platformSource = () => 'android';
    PromoSession.platformOverride = () => false;
    expect(PromoSession.platformEnabled(), isFalse);
  });

  test('start adds one to the launch count, even when called twice', () async {
    await PromoSession.start(isPremium: () => false);
    await PromoSession.start(isPremium: () => false);
    expect(await PromoPrefs.getLaunchCount(), 1);
  });

  test('start on Android checks the install once', () async {
    installedAnswer = false;
    await PromoSession.start(isPremium: () => false);
    expect(nativeCalls, ['isInstalled']);
  });
}

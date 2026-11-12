// Checks how the cross-promo store page is opened: the first way, the second way, and the return.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/promo/promo_links.dart';
import 'package:letselevatorneo/promo/promo_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <String>[];
  late Future<bool?> Function(String, Map<String, Object?>?) fakeNative;
  late Future<bool> Function(Uri) fakeLauncher;
  late String Function() fakePlatform;
  late List<Uri> launched;

  setUp(() {
    calls.clear();
    launched = [];
    fakeNative = (method, args) async => true;
    fakeLauncher = (uri) async {
      launched.add(uri);
      return true;
    };
    fakePlatform = () => 'android';
    PromoStore.invokeNative = (method, args) {
      calls.add(method);
      return fakeNative(method, args);
    };
    PromoStore.urlLauncher = (uri) => fakeLauncher(uri);
    PromoStore.platformSource = () => fakePlatform();
    PromoStore.storeClosedListener = null;
    PromoStore.iosAppId = promoAdventureIosAppId;
    PromoStore.iosPt = promoAdventureIosPt;
  });

  tearDown(() {
    PromoStore.invokeNative = (method, args) => Future.value(null);
    PromoStore.urlLauncher = (uri) async => false;
    PromoStore.platformSource = () => 'android';
    PromoStore.storeClosedListener = null;
  });

  test('Android: the first way is used when it works', () async {
    final result = await PromoStore.open(app: 'letselevatorneo', placement: 'menu');
    expect(result.opened, isTrue);
    expect(result.openMethod, 'market');
    expect(calls, ['openPlay']);
    expect(launched, isEmpty);
  });

  test('Android: when the first way is false, the second URL is opened', () async {
    fakeNative = (method, args) async {
      expect(args, isNotNull);
      return false;
    };
    final result = await PromoStore.open(app: 'letselevatorneo', placement: 'menu');
    expect(result.opened, isTrue);
    expect(result.openMethod, 'url');
    expect(launched.single.host, 'play.google.com');
    expect(launched.single.path, '/store/apps/details');
    expect(launched.single.queryParameters['id'], 'nakajimamasao.appstudio.elevator3d');
  });

  test('Android: when the first way throws, the second URL is opened', () async {
    fakeNative = (method, args) async => throw PlatformException(code: 'x');
    final result = await PromoStore.open(app: 'letselevator', placement: 'launch');
    expect(result.openMethod, 'url');
    expect(launched.single.queryParameters['referrer'],
        'utm_source=letselevator&utm_medium=in_app&utm_campaign=launch');
  });

  test('Android: both ways failing gives opened=false and no open method', () async {
    fakeNative = (method, args) async => false;
    fakeLauncher = (uri) async => false;
    final result = await PromoStore.open(app: 'letselevatorneo', placement: 'menu');
    expect(result.opened, isFalse);
    expect(result.openMethod, isNull);
  });

  test('Android: a launcher exception gives opened=false', () async {
    fakeNative = (method, args) async => false;
    fakeLauncher = (uri) async => throw PlatformException(code: 'no app');
    final result = await PromoStore.open(app: 'letselevatorneo', placement: 'menu');
    expect(result.opened, isFalse);
  });

  test('iOS: with no App Store ID the native call is skipped and opened=false', () async {
    fakePlatform = () => 'ios';
    fakeNative = (method, args) async => false;
    final result = await PromoStore.open(app: 'letselevatorneo', placement: 'menu');
    expect(calls, isEmpty);
    expect(result.opened, isFalse);
    expect(launched, isEmpty);
  });

  test('iOS: with the IDs set, the first way is the native call', () async {
    fakePlatform = () => 'ios';
    PromoStore.iosAppId = '123456789';
    PromoStore.iosPt = '987654';
    final result = await PromoStore.open(app: 'letselevatorneo', placement: 'menu');
    expect(calls, ['openAppStore']);
    expect(result.openMethod, 'sheet');
  });

  test('isAdventureInstalled asks the native side on Android', () async {
    fakeNative = (method, args) async => true;
    expect(await PromoStore.isAdventureInstalled(), isTrue);
    expect(calls, ['isInstalled']);
  });

  test('isAdventureInstalled gives false when the native side fails', () async {
    fakeNative = (method, args) async => throw PlatformException(code: 'x');
    expect(await PromoStore.isAdventureInstalled(), isFalse);
  });

  test('isAdventureInstalled checks the URL scheme on iOS and gives false on error', () async {
    fakePlatform = () => 'ios';
    final seen = <Uri>[];
    PromoStore.canLaunch = (uri) async {
      seen.add(uri);
      return true;
    };
    expect(await PromoStore.isAdventureInstalled(), isTrue);
    expect(seen.single.toString(), 'nakajimamasao.appstudio.elevator3d://');

    PromoStore.canLaunch = (uri) async => throw PlatformException(code: 'x');
    expect(await PromoStore.isAdventureInstalled(), isFalse);
    PromoStore.canLaunch = (uri) async => false;
  });

  test('the return is reported once after resumed, with the away time and method', () async {
    var now = DateTime(2026, 11, 12, 10, 0, 0);
    final reports = <(Duration, String)>[];
    final watcher = PromoStoreReturnWatcher(
      onReturned: (away, method) => reports.add((away, method)),
      clock: () => now,
    );
    watcher.start('market');
    watcher.didChangeAppLifecycleState(AppLifecycleState.inactive);
    now = now.add(const Duration(seconds: 4));
    watcher.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 6));
    watcher.didChangeAppLifecycleState(AppLifecycleState.resumed);
    watcher.didChangeAppLifecycleState(AppLifecycleState.resumed);

    // The away time starts at the first leave (inactive), not at the later paused state.
    expect(reports, [(const Duration(seconds: 10), 'market')]);
    watcher.stop();
  });

  test('the iOS sheet is judged by storeClosed, not by lifecycle', () async {
    var now = DateTime(2026, 11, 12, 10, 0, 0);
    final reports = <(Duration, String)>[];
    final watcher = PromoStoreReturnWatcher(
      onReturned: (away, method) => reports.add((away, method)),
      clock: () => now,
    );
    watcher.start('sheet');
    watcher.didChangeAppLifecycleState(AppLifecycleState.inactive);
    watcher.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(reports, isEmpty);

    now = now.add(const Duration(seconds: 9));
    await PromoStore.dispatchNativeCall(const MethodCall('storeClosed'));
    expect(reports, [(const Duration(seconds: 9), 'sheet')]);
  });

  test('open with onReturned calls back once through storeClosed on iOS', () async {
    fakePlatform = () => 'ios';
    PromoStore.iosAppId = '123456789';
    PromoStore.iosPt = '987654';
    fakeNative = (method, args) async => true;
    final reports = <String>[];
    final result = await PromoStore.open(
      app: 'letselevatorneo',
      placement: 'menu',
      onReturned: (away, method) => reports.add(method),
    );
    expect(result.openMethod, 'sheet');
    expect(PromoStore.storeClosedListener, isNotNull);

    await PromoStore.dispatchNativeCall(const MethodCall('storeClosed'));
    await PromoStore.dispatchNativeCall(const MethodCall('storeClosed'));
    expect(reports, ['sheet']);
    expect(PromoStore.storeClosedListener, isNull);
  });

  test('opening twice then returning once calls back once, for the later open', () async {
    final reports = <String>[];
    await PromoStore.open(
      app: 'letselevatorneo',
      placement: 'menu',
      onReturned: (away, method) => reports.add('first'),
    );
    await PromoStore.open(
      app: 'letselevatorneo',
      placement: 'menu',
      onReturned: (away, method) => reports.add('second'),
    );
    final binding = TestWidgetsFlutterBinding.instance;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(reports, ['second']);
  });
}

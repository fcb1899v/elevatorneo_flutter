// The banner asks for consent and an ad only after the launch splash is gone.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/admob_banner.dart';
import 'package:letselevatorneo/splash_hold.dart';

const _ump = 'plugins.flutter.io/google_mobile_ads/ump';
const _ads = 'plugins.flutter.io/google_mobile_ads';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<String> calls;

  String methodOf(ByteData? message) => const StandardMessageCodec().readValue(ReadBuffer(message!)) as String;

  setUp(() {
    calls = [];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // Consent is already given, so the SDK may request ads at once
    Future<ByteData?> record(ByteData? message) async {
      final method = methodOf(message);
      calls.add(method);
      return const StandardMethodCodec().encodeSuccessEnvelope(method == 'ConsentInformation#canRequestAds' ? true : null);
    }
    messenger.setMockMessageHandler(_ump, record);
    messenger.setMockMessageHandler(_ads, record);
  });

  tearDown(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler(_ump, null);
    messenger.setMockMessageHandler(_ads, null);
  });

  testWidgets('no consent request while the splash is up, one after it goes', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: Scaffold(body: AdBannerWidget())),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(splashHold.visible.value, isTrue);
    expect(calls.where((m) => m.contains('requestConsentInfoUpdate')), isEmpty);

    splashHold.visible.value = false;
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(calls.where((m) => m.contains('requestConsentInfoUpdate')), isNotEmpty);
  });
}

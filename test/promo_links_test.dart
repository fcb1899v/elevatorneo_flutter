// Checks the cross-promo link values against the spec table, character for character.

import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/promo/promo_links.dart';

void main() {
  test('ADVENTURE identifiers match the spec', () {
    expect(promoAdventureAndroidPackage, 'nakajimamasao.appstudio.elevator3d');
    expect(promoAdventureIosUrlName, 'nakajimamasao.appstudio.elevator3d');
    expect(promoAdventureIosAppId, '');
    expect(promoAdventureIosPt, '');
    expect(promoAndroidEnabled, isTrue);
    expect(promoIosEnabled, isFalse);
  });

  test('Android referrer values match the spec table', () {
    expect(
      promoAndroidReferrer(app: 'letselevator', placement: 'menu'),
      'utm_source%3Dletselevator%26utm_medium%3Din_app%26utm_campaign%3Dmenu',
    );
    expect(
      promoAndroidReferrer(app: 'letselevatorneo', placement: 'menu'),
      'utm_source%3Dletselevatorneo%26utm_medium%3Din_app%26utm_campaign%3Dmenu',
    );
    expect(
      promoAndroidReferrer(app: 'letselevator', placement: 'launch'),
      'utm_source%3Dletselevator%26utm_medium%3Din_app%26utm_campaign%3Dlaunch',
    );
    expect(
      promoAndroidReferrer(app: 'letselevatorneo', placement: 'launch'),
      'utm_source%3Dletselevatorneo%26utm_medium%3Din_app%26utm_campaign%3Dlaunch',
    );
  });

  test('Android URLs are built from the package and referrer', () {
    expect(
      promoAndroidInlineInstallUrl(app: 'letselevator', placement: 'menu'),
      'https://play.google.com/d?id=nakajimamasao.appstudio.elevator3d'
      '&referrer=utm_source%3Dletselevator%26utm_medium%3Din_app%26utm_campaign%3Dmenu',
    );
    expect(
      promoAndroidStoreUrl(app: 'letselevatorneo', placement: 'launch'),
      'https://play.google.com/store/apps/details?id=nakajimamasao.appstudio.elevator3d'
      '&referrer=utm_source%3Dletselevatorneo%26utm_medium%3Din_app%26utm_campaign%3Dlaunch',
    );
  });

  test('iOS ct values match the spec table', () {
    expect(promoIosCampaignToken(placement: 'menu'), 'promo_menu');
    expect(promoIosCampaignToken(placement: 'launch'), 'promo_launch');
  });

  test('unknown placement is rejected', () {
    expect(
      () => promoAndroidReferrer(app: 'letselevator', placement: 'settings'),
      throwsArgumentError,
    );
    expect(() => promoIosCampaignToken(placement: 'settings'), throwsArgumentError);
  });

  test('iOS URL is null while the ID or token is empty', () {
    expect(promoIosStoreUrl(placement: 'menu'), isNull);
    expect(promoIosStoreUrlFor(appId: '', pt: 'abc', placement: 'menu'), isNull);
    expect(promoIosStoreUrlFor(appId: '123', pt: '', placement: 'menu'), isNull);
    expect(promoShowOnIos(), isFalse);
  });

  test('iOS URL format when the ID and token are set', () {
    expect(
      promoIosStoreUrlFor(appId: '1234567890', pt: 'abc123', placement: 'launch'),
      'https://apps.apple.com/app/id1234567890?pt=abc123&ct=promo_launch&mt=8',
    );
  });
}
